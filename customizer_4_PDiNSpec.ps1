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
    
    # Aqui estamos definindo um cabeçalho básico, caso precise
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
# Função atualizada: ScanStatusCode
# -------------------------
function Get-ip-from-url {
    param (
        [Parameter(Mandatory=$true)]
        [String]$url
    )

    try {
        Write-Host "`n Searching for IP DNS ..." -ForegroundColor Yellow
        Write-Log "Starting Get-ip-from-url for: $url"

        $domain = ($url -replace '^https?://', '') -replace '/.*$', ''
        
        $results = Resolve-DnsName -Name $domain -Type A -ErrorAction Stop
        
        Write-Host "`nIP Address(es):" -ForegroundColor Green
        $results | ForEach-Object { 
            Write-Host "$($_.IPAddress)" -ForegroundColor White
        }

        Write-Log "Successfully resolved $domain to: $($results.IPAddress -join ', ')"

        Read-Host "`nPressione Enter para continuar..."
    }
    catch {
        Write-Host "`nErro ao resolver DNS para: $url" -ForegroundColor Red
        Write-Host "Detalhes: $($_.Exception.Message)" -ForegroundColor DarkRed
        Write-Log "DNS Resolution Error for $url : $($_.Exception.Message)" "ERROR"
        
    }
}
# -------------------------
# Chamada correta da função
# -------------------------

Get-ip-from-url -url 'http://scanme.nmap.org'

