$command = Get-Command python -ErrorAction SilentlyContinue
if (-not $command) { $command = Get-Command py -ErrorAction SilentlyContinue }
if (-not $command) { Write-Host 'Python 3 is required, or use the Node build/start workflow in README.md.'; Read-Host 'Press Enter'; exit 1 }
$server = Join-Path $PSScriptRoot 'server.py'
Start-Process -FilePath $command.Source -ArgumentList @('"' + $server + '"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
