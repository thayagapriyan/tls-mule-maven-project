variable "aws_region" {
  description = "AWS region for the IAM resources (IAM is global, but the provider needs a region)."
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the role, as <owner>/<repo>."
  type        = string
  # e.g. "thayagapriyan/tls-mule-maven-project"
}

variable "allowed_subjects" {
  description = <<-EOT
    OIDC subject patterns under repo:<owner>/<repo>: that may assume the role.
    Keep this tight — it is the only thing standing between any workflow run and S3.
    Examples:
      "ref:refs/heads/main"        - the main branch
      "pull_request"               - PRs from the same repo (not forks)
      "ref:refs/tags/v*"           - version tags
      "environment:production"     - a GitHub Environment
  EOT
  type        = list(string)
  default     = ["ref:refs/heads/main", "pull_request"]
}

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the GitHub OIDC provider. An AWS account can have only ONE
    provider per URL, so set this to false if token.actions.githubusercontent.com
    already exists in the account (the module will look it up instead).
  EOT
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role the CI workflow assumes."
  type        = string
  default     = "mule-tls-ci-s3-read"
}

variable "bucket_name" {
  description = "Name of the S3 bucket that holds the TLS keystore/truststore objects."
  type        = string
}

variable "s3_key_prefixes" {
  description = "Object key patterns (within the bucket) the role may read. Least privilege."
  type        = list(string)
  default     = ["mule-app/*"]
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
