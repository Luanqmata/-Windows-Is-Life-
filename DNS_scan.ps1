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
function Busca-Por-DNS {
        $headers = @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36"
        }

        # === Funcoes ===
        function ScanHeaders {
            param ([string]$url)
            try {
                Write-Host "`n Escaneando Headers..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Method Head -Headers $headers -ErrorAction Stop
                Write-Host "`n O servidor roda:" -ForegroundColor Green
                $response.Headers.Server
            } catch {
                Write-Host "`nErro ao buscar headers: $_" -ForegroundColor Red
            }
        }

        function ScanOptions {
            param ([string]$url)
            try {
                Write-Host "`n Verificando metodos HTTP suportados..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Method Options -Headers $headers -ErrorAction Stop
                Write-Host "`n Metodos permitidos pelo servidor:" -ForegroundColor Green
                $response.Headers.Allow
            } catch {
                Write-Host "`nErro ao buscar metodos OPTIONS: $_" -ForegroundColor Red
            }
        }

        function ScanLinks {
            param ([string]$url)
            try {
                Write-Host "`n Procurando links na pagina..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
                Write-Host "`n Links encontrados:" -ForegroundColor Green
                $response.Links.Href | Select-String http
            } catch {
                Write-Host "`nErro ao buscar links: $_" -ForegroundColor Red
            }
        }

        function ScanHTML {
            param ([string]$url)
            try {
                Write-Host "`n Obtendo codigo-fonte do HTML..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
                Write-Host "`n Codigo HTML recebido:" -ForegroundColor Green
                Write-Host $response.Content.Substring(0, 500) # Exibe os primeiros 500 caracteres
            } catch {
                Write-Host "`nErro ao obter o HTML: $_" -ForegroundColor Red
            }
        }

        function ScanTech {
            param ([string]$url)
            try {
                Write-Host "`n Detectando tecnologias utilizadas..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
                if ($response.Headers["x-powered-by"]) {
                    Write-Host "`n Tecnologia detectada:" -ForegroundColor Green
                    $response.Headers["x-powered-by"]
                } else {
                    Write-Host "Nenhuma tecnologia detectada nos headers."
                }
            } catch {
                Write-Host "`nErro ao buscar tecnologias: $_" -ForegroundColor Red
            }
        }

        function ScanStatusCode {
            param ([string]$url)
            try {
                Write-Host "`n Obtendo codigo de status HTTP..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
                Write-Host "`n Status Code:" -ForegroundColor Green
                $response.StatusCode
            } catch {
                Write-Host "`nErro ao obter Status Code: $_" -ForegroundColor Red
            }
        }

        function ScanTitle {
            param ([string]$url)
            try {
                Write-Host "`n Obtendo titulo da pagina..." -ForegroundColor Cyan
                $response = Invoke-WebRequest -Uri $url -Headers $headers -ErrorAction Stop
                if ($response.ParsedHtml.title) {
                    Write-Host "`n Titulo da pagina:" -ForegroundColor Green
                    $response.ParsedHtml.title
                } else {
                    Write-Host "`nNenhum titulo encontrado."
                }
            } catch {
                Write-Host "`nErro ao obter titulo da pagina: $_" -ForegroundColor Red
            }
        }

        function ScanRobotsTxt {
            param ([string]$url)
            try {
                Write-Host "`n Procurando robots.txt..." -ForegroundColor Cyan
                $robotsUrl = "$url/robots.txt"
                $response = Invoke-WebRequest -Uri $robotsUrl -Headers $headers -ErrorAction Stop
                Write-Host "`n Conteudo do robots.txt:" -ForegroundColor Green
                Write-Host $response.Content
            } catch {
                Write-Host "`nErro ao buscar robots.txt: $_" -ForegroundColor Red
            }
        }

        function ScanSitemap {
            param ([string]$url)
            try {
                Write-Host "`n Verificando sitemap.xml..." -ForegroundColor Cyan
                $sitemapUrl = "$url/sitemap.xml"
                $response = Invoke-WebRequest -Uri $sitemapUrl -Headers $headers -ErrorAction Stop
                Write-Host "`n Sitemap encontrado:" -ForegroundColor Green
                Write-Host $response.Content.Substring(0, 500)
            } catch {
                Write-Host "`nErro ao buscar sitemap.xml: $_" -ForegroundColor Red
            }
        }

        function ScanPorts {
            param ([string]$host)
            $ports = @(21, 22, 25, 53, 80, 110, 143, 443, 3306, 8080)
            Write-Host "`n Escaneando portas comuns..." -ForegroundColor Cyan
            foreach ($port in $ports) {
                try {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    $tcp.Connect($host, $port)
                    Write-Host "Porta $port aberta!" -ForegroundColor Green
                    $tcp.Close()
                } catch {
                    Write-Host "Porta $port fechada."
                }
            }
        }
        
        function RunAllScans {
            param ([string]$url)

            Write-Host "`n=== Iniciando todas as verificacoes para a URL: $url ===`n" -ForegroundColor Magenta

            Write-Host "`n=== 1. Captura Headers do Servidor ===" -ForegroundColor Magenta
            ScanHeaders -url $url

            Write-Host "`n=== 2. Descobre os Metodos HTTP Permitidos ===" -ForegroundColor Magenta
            ScanOptions -url $url

            Write-Host "`n=== 3. Lista os Links Encontrados no HTML ===" -ForegroundColor Magenta
            ScanLinks -url $url

            Write-Host "`n=== 4. Obtem Codigo-Fonte do HTML ===" -ForegroundColor Magenta
            ScanHTML -url $url

            Write-Host "`n=== 5. Detecta Tecnologias Utilizadas ===" -ForegroundColor Magenta
            ScanTech -url $url

            Write-Host "`n=== 6. Obtem Codigo de Status HTTP ===" -ForegroundColor Magenta
            ScanStatusCode -url $url

            Write-Host "`n=== 7. Obtem o <title> da Pagina ===" -ForegroundColor Magenta
            ScanTitle -url $url

            Write-Host "`n=== 8. Verifica o arquivo robots.txt ===" -ForegroundColor Magenta
            ScanRobotsTxt -url $url

            Write-Host "`n=== 9. Verifica se o site possui um Sitemap ===" -ForegroundColor Magenta
            ScanSitemap -url $url

            Write-Host "`n=== Todas as verificacoes foram conclui­das! ===`n" -ForegroundColor Magenta
            Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
            $null = Read-Host
        }

        while ($true) {
            Clear-Host
            Write-Host "`n`n`n`n`n`n+==================================================+" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||         === Menu de busca por DNS ===          ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "+==================================================+" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      1. Captura Headers do Servidor            ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      2. Descobre os Metodos HTTP Permitidos    ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      3. Lista os Links Encontrados no HTML     ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      4. Obtem Codigo-Fonte do HTML             ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      5. Detecta Tecnologias Utilizadas         ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      6. Obtem Codigo de Status HTTP            ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      7. Obtem o <title> da Pagina              ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      8. Verifica o arquivo robots.txt          ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      9. Verifica se o site possui um Sitemap   ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      10. Faz um Scan Rapido das Portas Comuns  ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      11. Rodar todas opcoes (1 a 9)            ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "||      12. Voltar para o Menu Principal          ||" -ForegroundColor Magenta
            Write-Host "||                                                ||" -ForegroundColor Magenta
            Write-Host "+==================================================+" -ForegroundColor Magenta
            Write-Host "`n`n"

            $opcao = Read-Host "`nEscolha uma opcao (1-12)"
        
            switch ($opcao) {
                1 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanHeaders -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                2 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanOptions -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                3 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanLinks -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                4 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanHTML -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                5 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanTech -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                6 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanStatusCode -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                7 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanTitle -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                8 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanRobotsTxt -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                9 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanSitemap -url $url
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                10 {
                    $host = Read-Host "`nDigite o host ou IP (ex: exemplo.com ou 192.168.1.1)"
                    ScanPorts -host $host
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
                11{
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    RunAllScans -url $url
                }
                12 {
                    Write-Host "`nSaindo..." -ForegroundColor Magenta
                    return
                }
                default {
                    Write-Host "`nOpcao invalida. Escolha um numero entre 1 a 12." -ForegroundColor Magenta
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
            }
        }

}
    
