$ErrorActionPreference = "Stop"
$process = Start-Process -NoNewWindow -FilePath "c:\flutter\bin\cache\dart-sdk\bin\dart.exe" -ArgumentList @("c:\flutter\bin\cache\flutter_tools.snapshot", "--version") -RedirectStandardOutput "F:\Recent\pay_request\flutter_out.txt" -RedirectStandardError "F:\Recent\pay_request\flutter_err.txt" -Wait -PassThru
Write-Output "EXIT CODE: $($process.ExitCode)"
Write-Output "--- STDOUT ---"
Get-Content "F:\Recent\pay_request\flutter_out.txt" -ErrorAction SilentlyContinue
Write-Output "--- STDERR ---"
Get-Content "F:\Recent\pay_request\flutter_err.txt" -ErrorAction SilentlyContinue
