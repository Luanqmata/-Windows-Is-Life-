function Busca-Por-DNS {
    $headers = @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36"
    }

    $logFile = "scan_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

    function Write-Log {
        param ([string]$message, [string]$level = "INFO")
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$level] $message"
        Add-Content -Path $logFile -Value $logMessage
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

    function Test-ValidUrl {
        param ([string]$url)
        try {
            $uri = [System.Uri]$url
            return ($uri.Scheme -eq 'http' -or $uri.Scheme -eq 'https')
        } catch {
            return $false
        }
    }

    function Invoke-WebRequestSafe {
        param ([string]$Uri, [string]$Method = 'Get', [int]$Timeout = 30)
        
        return Invoke-WebRequest -Uri $Uri -Method $Method -Headers $headers -ErrorAction Stop -TimeoutSec $Timeout
    }
    
    function ScanHeaders {
        param ([string]$url)
        try {
            Write-Host "`n Escaneando Headers..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanHeaders para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url -Method Head
            Write-Host "`n O servidor roda:" -ForegroundColor Green
            if ($response.Headers.Server) {
                $response.Headers.Server
                Write-Log "Server header: $($response.Headers.Server)"
            } else {
                Write-Host "Header Server nao encontrado." -ForegroundColor Yellow
            }
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanOptions {
        param ([string]$url)
        try {
            Write-Host "`n Verificando metodos HTTP suportados..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanOptions para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url -Method Options
            Write-Host "`n Metodos permitidos pelo servidor:" -ForegroundColor Green
            if ($response.Headers.Allow) {
                $response.Headers.Allow
                Write-Log "Métodos permitidos: $($response.Headers.Allow)"
            } else {
                Write-Host "Nenhum metodo Allow encontrado nos headers." -ForegroundColor Yellow
            }
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanLinks {
        param ([string]$url)
        try {
            Write-Host "`n Procurando links na pagina..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanLinks para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url
            Write-Host "`n Links encontrados:" -ForegroundColor Green
            $links = $response.Links.Href | Where-Object { $_ -match '^http' } | Select-Object -Unique
            if ($links) {
                $links | ForEach-Object {
                    Write-Host "  $_" -ForegroundColor White
                }
                Write-Log "Encontrados $($links.Count) links únicos"
            } else {
                Write-Host "Nenhum link HTTP encontrado." -ForegroundColor Yellow
            }
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanHTML {
        param ([string]$url)
        try {
            Write-Host "`n Obtendo Palavras do codigo-fonte do HTML..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanHTML para: $url"
            Start-Sleep -Seconds 2

            $response = Invoke-WebRequestSafe -Uri $url
            $htmlContent = $response.Content
            
            $palavras = $htmlContent -split '[^\p{L}0-9_\-]+' | 
                       Where-Object { $_.Length -gt 2 -and -not $_.StartsWith('#') -and -not $_.StartsWith('//') } | 
                       Select-Object -Unique |
                       Sort-Object
            
            $commonWords = @('the', 'and', 'for', 'you', 'your', 'this', 'that', 'with', 'have', 'from')
            $palavras = $palavras | Where-Object { $commonWords -notcontains $_.ToLower() }
            
            Write-Host "`nTotal de palavras unicas encontradas: $($palavras.Count)" -ForegroundColor Cyan
            Write-Log "Encontradas $($palavras.Count) palavras unicas para fuzzing"
            
            if ($palavras.Count -gt 0) {                
                Write-Host "`nExemplo de palavras encontradas (primeiras 10):" -ForegroundColor Yellow
                $palavras | Select-Object -First 10 | ForEach-Object {
                    Write-Host "  $_" -ForegroundColor White
                }
                
                $salvar = Read-Host "`nDeseja salvar as palavras em um arquivo para fuzzing? (S/N)"
                if ($salvar -eq 'S' -or $salvar -eq 's') {
                    $caminhoArquivo = Read-Host "`nDigite o nome do arquivo (padrao: palavras_fuzzing.txt)"
                    if ([string]::IsNullOrEmpty($caminhoArquivo)) {
                        $caminhoArquivo = "palavras_fuzzing.txt"
                    }
                    $palavras | Out-File -FilePath $caminhoArquivo -Encoding UTF8
                    $fullPath = (Get-Item $caminhoArquivo).FullName
                    Write-Host "`nPalavras salvas em: $caminhoArquivo" -ForegroundColor Green
                    Write-Host "Localização completa: $fullPath" -ForegroundColor Gray
                    Write-Log "Palavras salvas em: $fullPath"
                }
            } else {
                Write-Host "`nNenhuma palavra relevante foi encontrada no HTML." -ForegroundColor Yellow
            }
            
            return $palavras
            
        } catch {
            Handle-WebError -ErrorObject $_
            return @()
        }
    }

    function ScanTech {
        param ([string]$url)
        try {
            Write-Host "`n Detectando tecnologias utilizadas..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanTech para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url
            $techDetected = $false
            
            if ($response.Headers["x-powered-by"]) {
                Write-Host "`n Tecnologia detectada (X-Powered-By):" -ForegroundColor Green
                $response.Headers["x-powered-by"]
                Write-Log "Tecnologia detectada (X-Powered-By): $($response.Headers['x-powered-by'])"
                $techDetected = $true
            }
            
            if ($response.Headers["server"]) {
                Write-Host "`n Servidor detectado:" -ForegroundColor Green
                $response.Headers["server"]
                Write-Log "Servidor detectado: $($response.Headers['server'])"
                $techDetected = $True
            }
            
            if (-not $techDetected) {
                Write-Host "Nenhuma tecnologia detectada nos headers." -ForegroundColor Yellow
            }
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanStatusCode {
        param ([String]$url)
        try {
            Write-Host "`n Obtendo codigo de status HTTP..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanStatusCode para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url
            Write-Host "`n Status Code:" -ForegroundColor Green
            $response.StatusCode
            Write-Log "Status Code: $($response.StatusCode)"
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanTitle {
        param ([string]$url)
        try {
            Write-Host "`n Obtendo titulo da pagina..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanTitle para: $url"
            
            $response = Invoke-WebRequestSafe -Uri $url
            if ($response.ParsedHtml -and $response.ParsedHtml.title) {
                Write-Host "`n Titulo da pagina:" -ForegroundColor Green
                $response.ParsedHtml.title
                Write-Log "Titulo da pagina: $($response.ParsedHtml.title)"
            } else {
                Write-Host "`nNenhum titulo encontrado." -ForegroundColor Yellow
            }
        } catch {
            Handle-WebError -ErrorObject $_
        }
    }

    function ScanRobotsTxt {
        param ([string]$url)
        try {
            Write-Host "`n Procurando robots.txt..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanRobotsTxt para: $url"
            
            $robotsUrl = "$url/robots.txt"
            $response = Invoke-WebRequestSafe -Uri $robotsUrl
            Write-Host "`n Conteudo do robots.txt:" -ForegroundColor Green
            Write-Host $response.Content
            Write-Log "Robots.txt encontrado e lido com sucesso"
        } catch {
            Write-Host "`nRobots.txt nao encontrado ou erro de acesso." -ForegroundColor Yellow
            Write-Log "Robots.txt nao encontrado: $($_.Exception.Message)" "WARNING"
        }
    }

    function ScanSitemap {
        param ([string]$url)
        try {
            Write-Host "`n Verificando sitemap.xml..." -ForegroundColor Cyan
            Write-Log "Iniciando ScanSitemap para: $url"
            
            $sitemapUrl = "$url/sitemap.xml"
            $response = Invoke-WebRequestSafe -Uri $sitemapUrl
            Write-Host "`n Sitemap encontrado:" -ForegroundColor Green
            Write-Host $response.Content.Substring(0, [Math]::Min($response.Content.Length, 500))
            Write-Log "Sitemap.xml encontrado e lido com sucesso"
        } catch {
            Write-Host "`nSitemap.xml não encontrado ou erro de acesso." -ForegroundColor Yellow
            Write-Log "Sitemap.xml não encontrado: $($_.Exception.Message)" "WARNING"
        }
    }

    function ScanPorts {
        param ([string]$host)
        $ports = @(21, 22, 25, 53, 80, 110, 143, 443, 3306, 8080, 8443, 9000)
        Write-Host "`n Escaneando $($ports.Count) portas comuns..." -ForegroundColor Cyan
        Write-Log "Iniciando ScanPorts para: $host"
        
        $openPorts = @()
        $counter = 0
        
        foreach ($port in $ports) {
            $counter++
            $percentComplete = ($counter / $ports.Count) * 100
            Write-Progress -Activity "Escaneando portas" -Status "Verificando porta $port" -PercentComplete $percentComplete
            
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $tcp.Connect($host, $port)
                Write-Host "Porta $port aberta!" -ForegroundColor Green
                $openPorts += $port
                $tcp.Close()
            } catch {
                Write-Host "Porta $port fechada." -ForegroundColor Gray
            }
        }
        Write-Progress -Activity "Escaneando portas" -Completed
        
        if ($openPorts.Count -gt 0) {
            Write-Host "`nPortas abertas encontradas: $($openPorts -join ', ')" -ForegroundColor Green
            Write-Log "Portas abertas encontradas em $host : $($openPorts -join ', ')"
        } else {
            Write-Host "`nNenhuma porta aberta encontrada." -ForegroundColor Yellow
            Write-Log "Nenhuma porta aberta encontrada em $host"
        }
    }
    
    function RunAllScans {
        param ([string]$url)
        clear-host
        Write-Host "`n=== Iniciando todas as verificacoes para a URL: $url ===`n" -ForegroundColor Magenta
        Write-Log "Iniciando RunAllScans para: $url"
        
        $scans = @(
            @{Name="Headers do Servidor"; Function={ScanHeaders -url $url}},
            @{Name="Metodos HTTP Permitidos"; Function={ScanOptions -url $url}},
            @{Name="Links no HTML"; Function={ScanLinks -url $url}},
            @{Name="Tecnologias Utilizadas"; Function={ScanTech -url $url}},
            @{Name="Codigo de Status HTTP"; Function={ScanStatusCode -url $url}},
            @{Name="Titulo da Pagina"; Function={ScanTitle -url $url}},
            @{Name="Robots.txt"; Function={ScanRobotsTxt -url $url}},
            @{Name="Sitemap.xml"; Function={ScanSitemap -url $url}},
            @{Name="Palavras para Fuzzing"; Function={ScanHTML -url $url}}
        )
        
        $counter = 0
        foreach ($scan in $scans) {
            $counter++
            Write-Host "`n=== $counter. $($scan.Name) ===" -ForegroundColor Magenta
            & $scan.Function
            Start-Sleep -Milliseconds 300
        }
        
        Write-Host "`n=== Todas as verificacoes foram concluidas ===`n" -ForegroundColor Magenta
        Write-Log "RunAllScans concluido para: $url"
        Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
        $null = Read-Host
    }

    while ($true) {
        $cor = "Magenta"
        Clear-Host
        Write-Host "+==================================================+" -ForegroundColor $cor
        Write-Host "||                                                ||" -ForegroundColor $cor
        Write-Host "||            === MENU DE BUSCA POR DNS ===       ||" -ForegroundColor $cor
        Write-Host "||                                                ||" -ForegroundColor $cor
        Write-Host "+==================================================+" -ForegroundColor $cor
        Write-Host "||   1. Captura Headers do Servidor               ||" -ForegroundColor $cor
        Write-Host "||   2. Descobre os Metodos HTTP Permitidos       ||" -ForegroundColor $cor
        Write-Host "||   3. Lista os Links Encontrados no HTML        ||" -ForegroundColor $cor
        Write-Host "||   4. Obtem todas Palavras do site              ||" -ForegroundColor $cor
        Write-Host "||   5. Detecta Tecnologias Utilizadas            ||" -ForegroundColor $cor
        Write-Host "||   6. Obtem Codigo de Status HTTP               ||" -ForegroundColor $cor
        Write-Host "||   7. Obtem o <title> da Pagina                 ||" -ForegroundColor $cor
        Write-Host "||   8. Verifica o arquivo robots.txt             ||" -ForegroundColor $cor
        Write-Host "||   9. Verifica se o site possui um Sitemap      ||" -ForegroundColor $cor
        Write-Host "||  10. Faz um Scan Rapido das Portas Comuns      ||" -ForegroundColor $cor
        Write-Host "||  11. Rodar todas opcoes (1 a 9)                ||" -ForegroundColor $cor
        Write-Host "||  12. Sair                                      ||" -ForegroundColor $cor
        Write-Host "+==================================================+" -ForegroundColor $cor
        Write-Host "`nLog sendo salvo em: $logFile" -ForegroundColor Gray
        Write-Host "`n`n"

        $opcao = Read-Host "`nEscolha uma opcao (1-12)"
    
        switch ($opcao) {
            1 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanHeaders -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            2 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanOptions -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            3 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanLinks -url $url
                } else {
                    Write-Host "URL invlida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            4 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanHTML -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            5 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanTech -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            6 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanStatusCode -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            7 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanTitle -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            8 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanRobotsTxt -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            9 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    ScanSitemap -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                }
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            10 {
                $host = Read-Host "`nDigite o host ou IP (ex: exemplo.com ou 192.168.1.1)"
                ScanPorts -host $host
                Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                $null = Read-Host
            }
            11 {
                $url = Read-Host "`nDigite a URL do site (ex: https://exemplo.com)"
                if (Test-ValidUrl $url) {
                    RunAllScans -url $url
                } else {
                    Write-Host "URL invalida. Use http:// ou https://" -ForegroundColor Red
                    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Magenta
                    $null = Read-Host
                }
            }
            12 {
                Write-Host "`nSaindo..." -ForegroundColor Magenta
                Write-Log "Saindo do menu Busca-Por-DNS"
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

Busca-Por-DNS
