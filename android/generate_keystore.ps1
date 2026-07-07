# Generate a keystore for Play Store release
# Run this from the android/ directory

$keystorePath = "key.jks"
$alias = "upload"
$validity = "10000" # ~27 years

$storePass = Read-Host "Enter keystore password" -AsSecureString
$keyPass = Read-Host "Enter key password" -AsSecureString
$BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass)
$BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass)
$storePassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)
$keyPassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

Write-Host "Generating keystore..." -ForegroundColor Green
keytool -genkey -v -keystore $keystorePath -alias $alias -keyalg RSA -keysize 2048 -validity $validity -storepass $storePassPlain -keypass $keyPassPlain

# Write key.properties
@"
storePassword=$storePassPlain
keyPassword=$keyPassPlain
keyAlias=$alias
storeFile=$keystorePath
"@ | Out-File -FilePath "key.properties" -Encoding utf8

Write-Host "Keystore created: $keystorePath" -ForegroundColor Green
Write-Host "key.properties generated" -ForegroundColor Green
Write-Host "Keep these files SECURE and never commit them!" -ForegroundColor Yellow

[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2)
