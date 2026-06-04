locals {
  # Throwaway keystore generated at apply time — gitignored, never committed.
  keystore_path = "${path.module}/generated/keystore.jks"
}

# ---------------------------------------------------------------------------
# 1. Start LocalStack (S3) and wait until it is healthy.
#    Managed via the docker CLI so no extra Terraform provider/daemon wiring.
# ---------------------------------------------------------------------------
resource "null_resource" "localstack" {
  triggers = {
    container = var.container_name
    image     = var.localstack_image
    endpoint  = var.localstack_endpoint
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
      docker rm -f ${var.container_name} 2>$null | Out-Null
      docker run -d --name ${var.container_name} -p 4566:4566 -e SERVICES=s3 ${var.localstack_image} | Out-Null
      $ok = $false
      for ($i = 0; $i -lt 30; $i++) {
        try {
          Invoke-RestMethod "${var.localstack_endpoint}/_localstack/health" -TimeoutSec 3 | Out-Null
          $ok = $true; break
        } catch { Start-Sleep -Seconds 2 }
      }
      if (-not $ok) { throw "LocalStack did not become healthy at ${var.localstack_endpoint}" }
      Write-Host "LocalStack is healthy."
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-Command"]
    command     = "docker rm -f ${self.triggers.container} 2>$null | Out-Null; exit 0"
  }
}

# ---------------------------------------------------------------------------
# 2. Generate a throwaway JKS keystore with keytool (ships with the JDK).
# ---------------------------------------------------------------------------
resource "null_resource" "keystore" {
  triggers = {
    path = local.keystore_path
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-Command"]
    command     = <<-EOT
      $ks = "${local.keystore_path}"
      New-Item -ItemType Directory -Force (Split-Path $ks) | Out-Null
      if (Test-Path $ks) { Remove-Item $ks -Force }
      keytool -genkeypair -alias ${var.key_alias} -keyalg RSA -keysize 2048 -validity 365 `
        -dname "CN=localhost, OU=Demo, O=Priyan, C=NA" `
        -keystore $ks -storetype JKS `
        -storepass ${var.store_password} -keypass ${var.key_password}
      Write-Host "Generated keystore at $ks"
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-Command"]
    command     = "if (Test-Path '${self.triggers.path}') { Remove-Item '${self.triggers.path}' -Force }; exit 0"
  }
}

# ---------------------------------------------------------------------------
# 3. Create the bucket and upload the keystore into LocalStack.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tls" {
  bucket        = var.bucket_name
  force_destroy = true

  depends_on = [null_resource.localstack]
}

resource "aws_s3_object" "keystore" {
  bucket = aws_s3_bucket.tls.id
  key    = var.key
  source = local.keystore_path

  # No filemd5() on source — keeps the keystore out of the plan phase (it is
  # generated during apply). Re-run `terraform apply -replace=null_resource.keystore`
  # to rotate it.
  depends_on = [null_resource.keystore]
}
