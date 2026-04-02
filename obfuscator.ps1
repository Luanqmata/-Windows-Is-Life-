param(
    [string]$comand,
    [string]$type
)

function ConvertTo-Binary {
    param($Texto)
    $binario = @()
    foreach ($char in [char[]]$Texto) {
        $binario += [Convert]::ToString([byte]$char, 2).PadLeft(8, '0')
    }
    return $binario -join ' '
}

function ConvertTo-Payload {
    param($Texto)
    $binario = @()
    foreach ($char in [char[]]$Texto) {
        $binario += [Convert]::ToString([byte]$char, 2).PadLeft(8, '0')
    }
    return 'function uYrp($z){$KAL="";foreach($sX in $z){$KAL+=[char][Convert]::ToInt32($sX,2)};return $KAL};&(uYrp(@("' + ($binario -join '","') + '")))'
}

if (-not $comand) {
    Write-Host "Uso: ./obfuscator.ps1 -comand COMANDO -type payload_binary" -ForegroundColor White
    Write-Host ""
    Write-Host "Opcoes:" -ForegroundColor Yellow
    Write-Host "  -comand     Comando que sera ofuscado (ex: whoami, ipconfig, 'net user')" -ForegroundColor Gray
    Write-Host "  -type       Tipo de saida (no momento, apenas 'payload_binary')" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  ./obfuscator.ps1 -comand whoami -type payload_binary" -ForegroundColor Green
    Write-Host "  ./obfuscator.ps1 -comand 'whoami && hostname' -type payload_binary" -ForegroundColor Green
    Write-Host "  ./obfuscator.ps1 -comand 'powershell Get-Process' -type payload_binary" -ForegroundColor Green
    Write-Host ""
    exit
}

if ($type -eq "payload_binary") {
    Write-Host ""
    Write-Host "Binario: $(ConvertTo-Binary $comand)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Payload: $(ConvertTo-Payload $comand)" -ForegroundColor Green
}
