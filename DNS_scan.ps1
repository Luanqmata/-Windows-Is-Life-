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

        # === Funções ===
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

        # === Menu Principal ===
        while ($true) {
            Clear-Host
            Write-Host "`n`n`n`n`n`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
            Write-Host "║                     === Menu de busca por DNS ===                            ║" -ForegroundColor Red
            Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
            Write-Host "║  1. Captura Headers do Servidor                                             ║" -ForegroundColor Red
            Write-Host "║  2. Descobre os Métodos HTTP Permitidos                                     ║" -ForegroundColor Red
            Write-Host "║  3. Lista os Links Encontrados no HTML                                      ║" -ForegroundColor Red
            Write-Host "║  4. Obtém Código-Fonte do HTML                                              ║" -ForegroundColor Red
            Write-Host "║  5. Detecta Tecnologias Utilizadas                                          ║" -ForegroundColor Red
            Write-Host "║  6. Obtém Código de Status HTTP                                             ║" -ForegroundColor Red
            Write-Host "║  7. Obtém o <title> da Página                                               ║" -ForegroundColor Red
            Write-Host "║  8. Verifica o arquivo robots.txt                                           ║" -ForegroundColor Red
            Write-Host "║  9. Verifica se o site possui um Sitemap                                    ║" -ForegroundColor Red
            Write-Host "║ 10. Faz um Scan Rápido das Portas Comuns                                    ║" -ForegroundColor Red
            Write-Host "║ 11. Sair                                                                    ║" -ForegroundColor Red
            Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝`n`n" -ForegroundColor Red

            $opcao = Read-Host "`nEscolha uma opcao (1-11)"
        
            switch ($opcao) {
                1 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanHeaders -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                2 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanOptions -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                3 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanLinks -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                4 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanHTML -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                5 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanTech -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                6 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanStatusCode -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                7 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanTitle -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                8 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanRobotsTxt -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                9 {
                    $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                    ScanSitemap -url $url
                    Read-Host "`nPressione Enter para continuar..."
                }
                10 {
                    $host = Read-Host "`nDigite o host ou IP (ex: exemplo.com ou 192.168.1.1)"
                    ScanPorts -host $host
                    Read-Host "`nPressione Enter para continuar..."
                }
                11 {
                    Write-Host "`nSaindo..." -ForegroundColor Green
                    return
                }
                default {
                    Write-Host "`n❌ Opção inválida. Por favor, escolha uma opção entre 1 e 11." -ForegroundColor Red
                    Read-Host "`nPressione Enter para continuar..."
                }
            }
        }
    }
