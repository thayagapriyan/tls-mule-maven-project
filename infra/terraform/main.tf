# ---------------------------------------------------------------------------
# GitHub Actions OIDC provider
# ---------------------------------------------------------------------------
# Fetch GitHub's OIDC TLS cert so the thumbprint is computed dynamically rather
# than hardcoded (it has rotated before).
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# When the provider already exists in the account, look it up instead of creating it.
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn

  # Full subject claims, e.g. "repo:owner/repo:ref:refs/heads/main".
  subjects = [for s in var.allowed_subjects : "repo:${var.github_repo}:${s}"]
}

# ---------------------------------------------------------------------------
# IAM role the CI workflow assumes via OIDC
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    # Audience must be the STS audience the configure-aws-credentials action requests.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to specific repo refs/branches/PRs — this is the trust boundary.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.subjects
    }
  }
}

resource "aws_iam_role" "ci" {
  name                 = var.role_name
  description          = "Assumed by GitHub Actions (${var.github_repo}) to read TLS keystores from S3."
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Least-privilege S3 read policy (matches the plugin's needs)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "s3_read" {
  # GetObject (+ versioned reads, since the plugin supports file.versionId).
  statement {
    sid       = "ReadTlsObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [for prefix in var.s3_key_prefixes : "arn:aws:s3:::${var.bucket_name}/${prefix}"]
  }

  # ListBucket scoped to the same prefixes turns a missing object into a clean
  # NoSuchKey instead of an opaque AccessDenied.
  statement {
    sid       = "ListTlsPrefixes"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = var.s3_key_prefixes
    }
  }
}

resource "aws_iam_role_policy" "s3_read" {
  name   = "${var.role_name}-s3-read"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.s3_read.json
}
