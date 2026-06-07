<#
  Local end-to-end test of the Mule app build against LocalStack S3 — NO real AWS.

  It mirrors the CI `e2e-localstack` job:
    1. start LocalStack (S3) in Docker
    2. generate a throwaway keystore
    3. seed it into a LocalStack S3 bucket
    4. build the Mule app — the aws-tls-injector plugin downloads the keystore from
       LocalStack into target/classes/certificates and Mule packages it
    5. assert the keystore landed in the build output

  Prereqs: Docker Desktop running, AWS CLI, JDK + Maven, and the plugin installed in your
  local ~/.m2 (run `mvn -f ../tls-maven-plugin/pom.xml clean install -DskipTests` once).

  Run from the tls-mule-maven-project root:  ./scripts/local-localstack-test.ps1
#>
$ErrorActionPreference = 'Stop'

# --- config (matches the plugin config / CI defaults) ---
$Bucket   = 'mule-tls-bucket'
$Key      = 'mule-app/dev/keystore.jks'
$Endpoint = 'http://localhost:4566'

# AWS SDK v2 (the plugin) and the AWS CLI both read these. LocalStack accepts any creds.
# AWS_ENDPOINT_URL_S3 is what redirects the plugin's S3 client at LocalStack (no code change).
$env:AWS_ACCESS_KEY_ID     = 'test'
$env:AWS_SECRET_ACCESS_KEY = 'test'
$env:AWS_DEFAULT_REGION    = 'us-east-1'
$env:AWS_ENDPOINT_URL_S3   = 'http://s3.localhost.localstack.cloud:4566'
$env:AWS_ENDPOINT_URL      = 'http://s3.localhost.localstack.cloud:4566'

Write-Host '==> Starting LocalStack (S3) ...' -ForegroundColor Cyan
docker rm -f localstack-tls 2>$null | Out-Null
docker run -d --name localstack-tls -p 4566:4566 -e SERVICES=s3 localstack/localstack:3 | Out-Null

Write-Host '==> Waiting for LocalStack to be healthy ...' -ForegroundColor Cyan
for ($i = 0; $i -lt 30; $i++) {
    try {
        $h = Invoke-RestMethod "$Endpoint/_localstack/health" -TimeoutSec 2
        if ($h.services.s3 -in @('available','running')) { break }
    } catch { }
    Start-Sleep -Seconds 2
}

Write-Host '==> Generating a throwaway keystore ...' -ForegroundColor Cyan
Remove-Item keystore.jks -ErrorAction SilentlyContinue
keytool -genkeypair -alias mule-tls -keyalg RSA -keysize 2048 -validity 365 `
    -dname 'CN=localhost, OU=Demo, O=Priyan, C=NA' `
    -keystore keystore.jks -storetype JKS -storepass changeit -keypass changeit

Write-Host '==> Seeding the keystore into LocalStack S3 ...' -ForegroundColor Cyan
aws --endpoint-url $Endpoint s3 mb "s3://$Bucket" 2>$null
aws --endpoint-url $Endpoint s3 cp keystore.jks "s3://$Bucket/$Key"

Write-Host '==> Building the Mule app (plugin downloads from LocalStack) ...' -ForegroundColor Cyan
# -Dtls.* override the pom defaults; region us-east-1 matches LocalStack.
mvn -B clean package `
    -Dtls.bucket=$Bucket `
    -Dtls.key=$Key `
    -Dtls.region=us-east-1

Write-Host '==> Asserting the keystore was injected into target/classes ...' -ForegroundColor Cyan
if (Test-Path 'target/classes/certificates/keystore.jks') {
    Write-Host 'OK: keystore present in build output' -ForegroundColor Green
} else {
    Write-Host 'FAIL: plugin did not write the keystore' -ForegroundColor Red
    exit 1
}

Write-Host '==> Cleaning up LocalStack container ...' -ForegroundColor Cyan
docker rm -f localstack-tls | Out-Null
Remove-Item keystore.jks -ErrorAction SilentlyContinue
Write-Host 'DONE.' -ForegroundColor Green
