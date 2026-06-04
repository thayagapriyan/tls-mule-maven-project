output "ci_role_arn" {
  description = "ARN of the IAM role CI assumes. Set this as the GitHub secret AWS_ROLE_ARN."
  value       = aws_iam_role.ci.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider used by the trust policy."
  value       = local.oidc_provider_arn
}
