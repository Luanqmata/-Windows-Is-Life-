# obfuscator.ps1 - Versão final corrigida
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

# Se não tem comando, mostra ajuda
if (-not $comand) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "     OBFUSCADOR DE COMANDOS BINARIOS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: ./obfuscator.ps1 -comand <comando> [-type payload_binary]" -ForegroundColor Green
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  ./obfuscator.ps1 -comand whoami -type payload_binary" -ForegroundColor White
    Write-Host "  ./obfuscator.ps1 -comand dir" -ForegroundColor White
    Write-Host "  ./obfuscator.ps1 -comand ipconfig" -ForegroundColor White
    Write-Host ""
    exit
}

# Se tem comando, processa
if ($type -eq "payload_binary") {
    ConvertTo-Payload $comand
}
else {
    Write-Host "Binario: $(ConvertTo-Binary $comand)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Payload: $(ConvertTo-Payload $comand)" -ForegroundColor Green
}
