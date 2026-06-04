output "bucket" {
  description = "The S3 bucket holding the keystore."
  value       = aws_s3_bucket.tls.id
}

output "key" {
  description = "The S3 object key of the keystore."
  value       = aws_s3_object.keystore.key
}

output "sdk_s3_endpoint" {
  description = "Endpoint the Maven plugin's SDK should use (set AWS_ENDPOINT_URL_S3)."
  value       = var.sdk_s3_endpoint
}

# Copy-paste block to run the Mule build against this LocalStack fixture.
output "next_steps" {
  description = "Commands to build the Mule app against the provisioned LocalStack."
  value       = <<-EOT

    LocalStack is up and seeded. Now build the Mule app:

    # 1. Install the plugin locally (once):
    #    cd ..\..\..\tls-maven-plugin ; mvn clean install

    # 2. Point the plugin's SDK at LocalStack and set dummy creds:
    $env:AWS_ACCESS_KEY_ID = "test"
    $env:AWS_SECRET_ACCESS_KEY = "test"
    $env:AWS_DEFAULT_REGION = "${var.region}"
    $env:AWS_ENDPOINT_URL_S3 = "${var.sdk_s3_endpoint}"

    # 3. Build the app (resolves the plugin from your local ~/.m2 snapshot):
    cd ${abspath("${path.module}/../..")}
    mvn clean package `
      -Dtls.injector.groupId=com.priyan.maven `
      -Dtls.injector.plugin.version=1.0.0-SNAPSHOT `
      -Dtls.bucket=${aws_s3_bucket.tls.id} `
      -Dtls.key=${aws_s3_object.keystore.key} `
      -Dtls.region=${var.region}

    # 4. Verify:
    Test-Path target\classes\certificates\keystore.jks

    Tear down when done:  terraform destroy
  EOT
}
