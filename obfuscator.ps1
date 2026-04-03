param(
    [Alias("h", "manual", "help")]
    [switch]$ShowHelp,
    [string]$comand,
    [string]$type
)

function Show-Help {
    Write-Host ""
    Write-Host "OBFUSCATOR(1) - Manual de Usuario" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NOME" -ForegroundColor Yellow
    Write-Host "|  obfuscator.ps1 - ferramenta de ofuscacao de comandos"
    Write-Host ""
    Write-Host "SINOPSE" -ForegroundColor Yellow
    Write-Host "|  ./obfuscator.ps1 -comand [STRING] -type [METODO]"
    Write-Host "|  ./obfuscator.ps1 -h"
    Write-Host ""
    Write-Host "DESCRICAO" -ForegroundColor Yellow
    Write-Host "|  -comand [string]  |  Cadeia de caracteres ou variavel a ser processada."
    Write-Host "|  -type [metodo]    |  Define o algoritmo de transformacao (Obrigatorio)."
    Write-Host ""
    Write-Host "METODOS DISPONIVEIS (TYPE)" -ForegroundColor Yellow
    Write-Host "|  binary      |  Codificacao em sistema binario."
    Write-Host "|  charlength  |  Ofuscacao baseada em [CHAR]::Length."
    Write-Host "|  slice       |  Fragmentacao e reconstrucao de strings."
    Write-Host "|  space       |  Injecao de espacos nulos baseada em ASCII."
    Write-Host "|  unicode     |  Conversao para sequencias de escape \u{XXXX}."
    Write-Host "|  boolean     |  Transformacao em arrays de `$true/`$false."
    Write-Host "|  decimal     |  Representacao numerica inteira."
    Write-Host "|  zero        |  Preenchimento de bits com caracteres zero."
    Write-Host ""
    Write-Host "EXEMPLOS" -ForegroundColor Yellow
    
    # Exemplo 1
    Write-Host "|"
    Write-Host "|  " -NoNewline
    Write-Host "[+] " -ForegroundColor Green -NoNewline
    Write-Host "Ofuscar string simples:"
    Write-Host "|  ./obfuscator.ps1 -comand `"Get-Service | Select-Object -First 5`" -type space" -ForegroundColor White
    
    # Exemplo 2
    Write-Host "|"
    Write-Host "|  " -NoNewline
    Write-Host "[+] " -ForegroundColor Green -NoNewline
    Write-Host "Ofuscar data do sistema:"
    Write-Host "|  ./obfuscator.ps1 -comand `"Get-Date`" -type charlength" -ForegroundColor White
    
    # Exemplo 3
    Write-Host "|"
    Write-Host "|  " -NoNewline
    Write-Host "[+] " -ForegroundColor Green -NoNewline
    Write-Host "Ofuscar comando com cores:"
    Write-Host "|  ./obfuscator.ps1 -comand `"Write-Host 'PENTEST-GO' -ForegroundColor Red`" -type slice" -ForegroundColor White
    
    Write-Host "|"
    Write-Host "|  " -NoNewline
    Write-Host "[+] " -ForegroundColor Green -NoNewline
    Write-Host "Ver manual de usuario:"
    Write-Host "|  ./obfuscator.ps1 -h" -ForegroundColor White
    Write-Host ""
    
    Write-Host "NOTAS" -ForegroundColor Yellow
    # Nota 1
    Write-Host "|  " -NoNewline
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host "Caracteres especiais exigem o uso de aspas duplas."
    
    # Nota 2
    Write-Host "|  " -NoNewline
    Write-Host "[-] " -ForegroundColor Red -NoNewline
    Write-Host "Verifique as permissoes de execucao no PowerShell."
    Write-Host ""
}

function ConvertTo-Binary {
    param($Texto)
    $binario = @()
    foreach ($char in [char[]]$Texto) { $binario += [Convert]::ToString([byte]$char, 2).PadLeft(8, '0') }
    return 'function uYrp($z){$KAL="";foreach($sX in $z){$KAL+=[char][Convert]::ToInt32($sX,2)};return $KAL};&(uYrp(@("' + ($binario -join '","') + '")))'
}

function ConvertTo-CharLength {
    param($Texto)
    $lengths = @()
    foreach ($char in [char[]]$Texto) { $lengths += [int]$char }
    return '$c="' + ($lengths -join ',') + '";$r="";foreach($n in $c.Split(",")){$r+=[char][int]$n};&([scriptblock]::Create($r))'
}

function ConvertTo-Slice {
    param($Texto)
    $slice = @()
    foreach ($char in [char[]]$Texto) { $slice += $char }
    return '$s="' + ($slice -join '') + '";&([scriptblock]::Create($s))'
}

function ConvertTo-Space {
    param($Texto)
    $spaces = @()
    foreach ($char in [char[]]$Texto) { $spaces += (' ' * [int][char]$char) }
    return '$sp="' + ($spaces -join '|') + '";$r="";foreach($s in $sp.Split("|")){$r+=[char]$s.Length};&([scriptblock]::Create($r))'
}

function ConvertTo-Unicode {
    param($Texto)
    $unicode = @()
    foreach ($char in [char[]]$Texto) { $unicode += '\u{0:X4}' -f [int]$char }
    return '$u="' + ($unicode -join '') + '";$r="";for($i=0;$i -lt $u.Length;$i+=6){$r+=[char][int]("0x"+$u.Substring($i+2,4))};&([scriptblock]::Create($r))'
}

function ConvertTo-Boolean {
    param($Texto)
    $bits = @()
    foreach ($char in [char[]]$Texto) { $bits += [Convert]::ToString([byte]$char, 2).PadLeft(8, '0') }
    $boolArray = @()
    foreach ($bit in ($bits -join '').ToCharArray()) { if ($bit -eq '1') { $boolArray += '$true' } else { $boolArray += '$false' } }
    return '$b=@(' + ($boolArray -join ',') + ');$r="";for($i=0;$i -lt $b.Count;$i+=8){$byte=0;for($j=0;$j -lt 8;$j++){if($b[$i+$j]){$byte+= [math]::Pow(2,7-$j)}};$r+=[char][int]$byte};&([scriptblock]::Create($r))'
}

function ConvertTo-Decimal {
    param($Texto)
    $decimals = @()
    foreach ($char in [char[]]$Texto) { $decimals += [int]$char }
    return '$d="' + ($decimals -join ',') + '";$r="";foreach($n in $d.Split(",")){$r+=[char][int]$n};&([scriptblock]::Create($r))'
}

function ConvertTo-Zero {
    param($Texto)
    $zero = @()
    foreach ($char in [char[]]$Texto) { $zero += ('0' * [int]$char) }
    return '$z="' + ($zero -join '|') + '";$r="";foreach($s in $z.Split("|")){$r+=[char]$s.Length};&([scriptblock]::Create($r))'
}

# --- LOGICA DE EXECUCAO COM TRY/CATCH ---

try {
    # 1. Verifica se o usuario pediu ajuda explicitamente
    $ManualArg = $args | Where-Object { $_ -eq "--help" }
    if ($ShowHelp -or $ManualArg) {
        Show-Help
        exit
    }

    # 2. Valida se os parametros obrigatorios estao presentes
    if (-not $comand) {
        throw "O parametro -comand nao foi definido."
    }
    if (-not $type) {
        throw "O parametro -type nao foi definido."
    }

    # 3. Executa o Switch principal
    Write-Host ""
    switch ($type.ToLower()) {
        "binary"      { ConvertTo-Binary $comand }
        "charlength"  { ConvertTo-CharLength $comand }
        "slice"       { ConvertTo-Slice $comand }
        "space"       { ConvertTo-Space $comand }
        "unicode"     { ConvertTo-Unicode $comand }
        "boolean"     { ConvertTo-Boolean $comand }
        "decimal"     { ConvertTo-Decimal $comand }
        "zero"        { ConvertTo-Zero $comand }
        default {
            throw "Metodo de ofuscacao '$type' e invalido."
        }
    }
    Write-Host ""

}
catch {
    # 4. Captura qualquer erro (inclusive os 'throw' acima) e mostra a ajuda
    Write-Host "| [!] ERRO FATAL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "| [!] Use o comando './obfuscator.ps1 --help' para ver o manual de usuario." -ForegroundColor Red
    #Show-Help
    exit
}
