function Show-InputPrompt {
    param(
        [string]$User = $env:USERNAME,
        [string]$input_name = ""
    )
    
    $version = [System.Environment]::OSVersion.Version.ToString()

    $inputView = @"
             /----[ $User@Win= $version ]-[~]---[#]  -  $input_name
            /___ - :
"@

    $lines = $inputView -split "`n"
    
    Write-Host $lines[0] -ForegroundColor Red
    Write-Host $lines[1] -NoNewline -ForegroundColor Red
    
    return Read-Host
}

# Uso
$comando = Show-InputPrompt -input_name "Choose an option (1-12)"

