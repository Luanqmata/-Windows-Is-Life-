# -------------------------
# Stubs mínimos para rodar
# -------------------------
# Define o caminho do arquivo de log
$logFile = "$env:TEMP\scan-status.log"

function Write-Log {
    param ([string]$message, [string]$level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$level] $message"
    Add-Content -Path $logFile -Value $logMessage
}

function Invoke-WebRequestSafe {
    param ([string]$Uri, [string]$Method = 'Get', [int]$Timeout = 30)
    
    $headers = @{
        "User-Agent" = "PowerShell-Script"
    }
    
    return Invoke-WebRequest -Uri $Uri -Method $Method -Headers $headers -ErrorAction Stop -TimeoutSec $Timeout
}

function Handle-WebError {
    param ($ErrorObject)
    if ($ErrorObject.Exception.Response.StatusCode.value__) {
        $statusCode = $ErrorObject.Exception.Response.StatusCode.value__
        Write-Host "`nErro HTTP: $statusCode" -ForegroundColor Red
        Write-Log "Erro HTTP: $statusCode" "ERROR"
    } else {
        Write-Host "`nErro: $($ErrorObject.Exception.Message)" -ForegroundColor Red
        Write-Log "Erro: $($ErrorObject.Exception.Message)" "ERROR"
    }
}

# -------------------------
# Funções auxiliares de DNS
# -------------------------

function Get-DNSRecords {
    param([string]$Domain)

    $domain = ($Domain -replace '^https?://', '') -replace '/.*$', ''

    Write-Host "`n Verificando registros DNS..." -ForegroundColor Yellow
    Write-Log "Iniciando verificação de registros DNS para: $domain" "INFO"

    $recordTypes = @(
        @{Type = "MX"; Color = "Yellow"; Description = "MX Records"},
        @{Type = "NS"; Color = "Magenta"; Description = "NS Records"},
        @{Type = "SOA"; Color = "DarkYellow"; Description = "SOA Record"},
        @{Type = "CNAME"; Color = "DarkGreen"; Description = "CNAME Record"},
        @{Type = "TXT"; Color = "DarkCyan"; Description = "TXT Records"}
    )

    foreach ($recordType in $recordTypes) {
        try {
            Write-Log "Buscando registros $($recordType.Type) para: $domain" "DEBUG"
            $records = Resolve-DnsName -Name $domain -Type $recordType.Type -ErrorAction Stop
            
            if ($records) {
                Write-Host "`n$($recordType.Description):" -ForegroundColor $recordType.Color
                Write-Log "Registros $($recordType.Type) encontrados para: $domain" "INFO"
                
                switch ($recordType.Type) {
                    "MX" {
                        $records | ForEach-Object {
                            $output = "  $($_.NameExchange) (Pref: $($_.Preference))"
                            Write-Host $output
                            Write-Log "MX: $output" "DEBUG"
                        }
                    }
                    "NS" {
                        $records | ForEach-Object {
                            Write-Host "  $($_.NameHost)"
                            Write-Log "NS: $($_.NameHost)" "DEBUG"
                        }
                    }
                    "SOA" {
                        $records | ForEach-Object {
                            Write-Host "  Primary Server: $($_.PrimaryServer)"
                            Write-Host "  Admin: $($_.NameAdministrator)"
                            Write-Host "  Serial: $($_.SerialNumber)"
                            Write-Log "SOA: Primary=$($_.PrimaryServer) Admin=$($_.NameAdministrator) Serial=$($_.SerialNumber)" "DEBUG"
                        }
                    }
                    "CNAME" {
                        $records | ForEach-Object {
                            $output = "  $($_.NameAlias) -> $($_.NameHost)"
                            Write-Host $output
                            Write-Log "CNAME: $output" "DEBUG"
                        }
                    }
                    "TXT" {
                        $records | ForEach-Object {
                            $txtValue = $_.Strings -join '; '
                            Write-Host "  $txtValue"
                            Write-Log "TXT: $txtValue" "DEBUG"
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "  Nenhum registro $($recordType.Type) encontrado" -ForegroundColor Red
            Write-Log "Falha ao buscar registros $($recordType.Type) para: $domain - $($_.Exception.Message)" "WARNING"
        }
    }

    # Processamento de Reverse Lookup (PTR)
    try {
        Write-Log "Iniciando reverse lookup (PTR) para: $domain" "DEBUG"
        $ips = @()
        
        $aRecords = Resolve-DnsName -Name $domain -Type A -ErrorAction SilentlyContinue
        if ($aRecords) { 
            $ips += $aRecords.IPAddress
            Write-Log "Registros A encontrados: $($aRecords.IPAddress -join ', ')" "DEBUG"
        }

        $aaaaRecords = Resolve-DnsName -Name $domain -Type AAAA -ErrorAction SilentlyContinue
        if ($aaaaRecords) { 
            $ips += $aaaaRecords.IPAddress
            Write-Log "Registros AAAA encontrados: $($aaaaRecords.IPAddress -join ', ')" "DEBUG"
        }

        if ($ips.Count -gt 0) {
            Write-Host "`nReverse Lookup (PTR):" -ForegroundColor Cyan
            Write-Log "Iniciando buscas PTR para $($ips.Count) endereços IP" "INFO"
            
            foreach ($ip in $ips) {
                try {
                    $hostEntry = [System.Net.Dns]::GetHostEntry($ip)
                    $output = "  $ip -> $($hostEntry.HostName)"
                    Write-Host $output
                    Write-Log "PTR bem-sucedido: $output" "DEBUG"
                }
                catch {
                    Write-Host "  $ip -> PTR não encontrado" -ForegroundColor DarkYellow
                    Write-Log "Falha no PTR para $ip - $($_.Exception.Message)" "DEBUG"
                }
            }
        }
        else {
            Write-Host "`nNenhum IP encontrado para reverse lookup." -ForegroundColor DarkYellow
            Write-Log "Nenhum registro A ou AAAA encontrado para reverse lookup: $domain" "INFO"
        }
    }
    catch {
        Write-Host "`nErro durante reverse lookup: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Erro crítico durante reverse lookup: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "Verificação de registros DNS concluída para: $domain" "INFO"
}

# -------------------------
# Chamada correta da função
# -------------------------
#Get-DNSRecords -Domain "google.com"

#Get-DNSRecords -Domain "scanme.nmap.org"
Get-DNSRecords -Domain "http://businesscorp.com.br"
