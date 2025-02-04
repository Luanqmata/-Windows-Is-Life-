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
