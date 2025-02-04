function ScanServidor {
    $url = Read-Host "Digite a URL do site para scan (ex: http://scanme.org)"

    try {
        $headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36"
        }

        $web = Invoke-WebRequest -Uri $url -Method Options -Headers $headers -ErrorAction Stop

        Write-Host "`nO servidor roda: "
        $web.Headers.Server
        Write-Host ""

        Write-Host "O servidor aceita os métodos: "
        $web.Headers.Allow
        Write-Host ""

        Write-Host "Links encontrados: "
        $web2 = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        $web2.Links.Href | Select-String http
    }
    catch {
        Write-Host "Erro ao conectar-se ao servidor: $_" -ForegroundColor Red
    }
}

ScanServidor


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# ========================== #
#        SCANNER WEB         #
# ========================== #

# Disfarce para evitar bloqueios (finge ser um navegador real)
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36"
}

# === 1. Captura Headers do Servidor ===
function ScanHeaders {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Escaneando Headers..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Method Head -Headers $headers -ErrorAction Stop
        Write-Host "`n📌 O servidor roda:" -ForegroundColor Green
        $response.Headers.Server
    } catch {
        Write-Host "⚠️ Erro ao buscar headers: $_" -ForegroundColor Red
    }
}

# === 2. Descobre os Métodos HTTP Permitidos ===
function ScanOptions {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Verificando métodos HTTP suportados..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Method Options -Headers $headers -ErrorAction Stop
        Write-Host "`n✅ Métodos permitidos pelo servidor:" -ForegroundColor Green
        $response.Headers.Allow
    } catch {
        Write-Host "⚠️ Erro ao buscar métodos OPTIONS: $_" -ForegroundColor Red
    }
}

# === 3. Lista os Links Encontrados no HTML ===
function ScanLinks {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Procurando links na página..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        Write-Host "`n🔗 Links encontrados:" -ForegroundColor Green
        $response.Links.Href | Select-String http
    } catch {
        Write-Host "⚠️ Erro ao buscar links: $_" -ForegroundColor Red
    }
}

# === 4. Obtém Código-Fonte do HTML ===
function ScanHTML {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Obtendo código-fonte do HTML..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        Write-Host "`n📝 Código HTML recebido:" -ForegroundColor Green
        Write-Host $response.Content.Substring(0, 500) # Exibe os primeiros 500 caracteres
    } catch {
        Write-Host "⚠️ Erro ao obter o HTML: $_" -ForegroundColor Red
    }
}

# === 5. Detecta Tecnologias Utilizadas (ex: WordPress, Cloudflare, etc.) ===
function ScanTech {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Detectando tecnologias utilizadas..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        if ($response.Headers["x-powered-by"]) {
            Write-Host "`n⚙️ Tecnologia detectada:" -ForegroundColor Green
            $response.Headers["x-powered-by"]
        } else {
            Write-Host "❌ Nenhuma tecnologia detectada nos headers."
        }
    } catch {
        Write-Host "⚠️ Erro ao buscar tecnologias: $_" -ForegroundColor Red
    }
}

# === 6. Obtém Código de Status HTTP ===
function ScanStatusCode {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Obtendo código de status HTTP..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        Write-Host "`n✅ Status Code:" -ForegroundColor Green
        $response.StatusCode
    } catch {
        Write-Host "⚠️ Erro ao obter Status Code: $_" -ForegroundColor Red
    }
}

# === 7. Obtém o <title> da Página ===
function ScanTitle {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Obtendo título da página..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
        if ($response.ParsedHtml.title) {
            Write-Host "`n🏷️ Título da página:" -ForegroundColor Green
            $response.ParsedHtml.title
        } else {
            Write-Host "❌ Nenhum título encontrado."
        }
    } catch {
        Write-Host "⚠️ Erro ao obter título da página: $_" -ForegroundColor Red
    }
}

# === 8. Verifica o arquivo robots.txt ===
function ScanRobotsTxt {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Procurando robots.txt..." -ForegroundColor Cyan
        $robotsUrl = "$url/robots.txt"
        $response = Invoke-WebRequest -Uri $robotsUrl -Headers $headers -ErrorAction Stop
        Write-Host "`n🤖 Conteúdo do robots.txt:" -ForegroundColor Green
        Write-Host $response.Content
    } catch {
        Write-Host "⚠️ Erro ao buscar robots.txt: $_" -ForegroundColor Red
    }
}

# === 9. Verifica se o site possui um Sitemap ===
function ScanSitemap {
    param ([string]$url)
    try {
        Write-Host "`n🔍 Verificando sitemap.xml..." -ForegroundColor Cyan
        $sitemapUrl = "$url/sitemap.xml"
        $response = Invoke-WebRequest -Uri $sitemapUrl -Headers $headers -ErrorAction Stop
        Write-Host "`n🗺️ Sitemap encontrado:" -ForegroundColor Green
        Write-Host $response.Content.Substring(0, 500)
    } catch {
        Write-Host "⚠️ Erro ao buscar sitemap.xml: $_" -ForegroundColor Red
    }
}

# === 10. Faz um Scan Rápido das Portas Comuns ===
function ScanPorts {
    param ([string]$host)
    $ports = @(21, 22, 25, 53, 80, 110, 143, 443, 3306, 8080)
    Write-Host "`n🔍 Escaneando portas comuns..." -ForegroundColor Cyan
    foreach ($port in $ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($host, $port)
            Write-Host "🟢 Porta $port aberta!" -ForegroundColor Green
            $tcp.Close()
        } catch {
            Write-Host "🔴 Porta $port fechada."
        }
    }
}

# === Entrada do Usuário ===
$url = Read-Host "Digite a URL do site para scan (ex: http://scanme.org)"

# === Chamando todas as funções ===
ScanHeaders -url $url
ScanOptions -url $url
ScanLinks -url $url
ScanHTML -url $url
ScanTech -url $url
ScanStatusCode -url $url
ScanTitle -url $url
ScanRobotsTxt -url $url
ScanSitemap -url $url
### ScanPorts -host ($url -replace "http://|https://", "")
