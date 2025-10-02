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
function ScanStatusCode {
    param ([String]$url)
    try {
        Write-Host "`n Obtaining HTTP status code..." -ForegroundColor Yellow
        Write-Log "Starting ScanStatusCode for: $url"

        $response = Invoke-WebRequestSafe -Uri $url

        Write-Host "`nStatus Code:" -ForegroundColor Green
        $response.StatusCode
        Write-Log "Status Code: $($response.StatusCode)"


        Write-Host "`n Obtaining IP address..." -ForegroundColor Yellow
        Write-Log "Starting ScanIpAddr for: $url"
        # --- NOVO: Resolve IP do domínio ---
        $domain = ($url -replace '^https?://', '') -replace '/.*$', ''
        $r = Resolve-DnsName -Name $domain -Type A
        Write-Host "`nIP Address(es):" -ForegroundColor Green
        $r.IpAddress
        Write-Log "Resolved IPs: $($r.IpAddress -join ', ')"

    } catch {
        Handle-WebError -ErrorObject $_
    }
}

# -------------------------
# Chamada correta da função
# -------------------------
ScanStatusCode -url 'http://scanme.nmap.org'
