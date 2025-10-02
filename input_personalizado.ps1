
function Show-InputPrompt {
    param(
        [string]$User = $env:USERNAME,
        [string]$input_name = ""
    )
    
    $version = [System.Environment]::OSVersion.Version.ToString()

    Write-Host "`n`n               //~--~( " -NoNewline -ForegroundColor Red
    Write-Host "$User" -NoNewline -ForegroundColor Gray
    Write-Host "@Win_Version=" -NoNewline -ForegroundColor Cyan
    Write-Host "/$version/" -NoNewline -ForegroundColor Yellow
    Write-Host " )-[" -NoNewline -ForegroundColor Red
    Write-Host "~" -NoNewline -ForegroundColor White
    Write-Host "]--[" -NoNewline -ForegroundColor Red
    Write-Host "#" -NoNewline -ForegroundColor White
    Write-Host "]---> " -NoNewline -ForegroundColor Red
    Write-Host "$input_name" -ForegroundColor White
    # linha inferior
    Write-Host "              /__~----~" -NoNewline -ForegroundColor Red
    Write-Host " > " -NoNewline -ForegroundColor Red
    Write-Host "@: " -NoNewline -ForegroundColor White

    # Entrada do usuário em magenta
    $origColor = [Console]::ForegroundColor
    [Console]::ForegroundColor = "Magenta"
    $option = Read-Host
    [Console]::ForegroundColor = $origColor
    
    return $option
}
# Uso
$comando = Show-InputPrompt -input_name "Choose an option (1-12)"

