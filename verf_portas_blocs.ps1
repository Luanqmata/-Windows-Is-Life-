    function Validar-IP {
        param (
            [string]$ip
        )
        $regex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        return ($ip -match $regex)
    }

    function Pingar-Todas-Portas-Ip {
        Write-Host "`n"
        Write-Host "Obs: Esta acao pode levar alguns minutos (65535 portas)" -ForegroundColor Yellow

        do {
            $ip = Read-Host "Digite o IP (alvo)"
            if (-not (Validar-IP $ip)) {
                Write-Host "Endereço IP invalido. Tente novamente." -ForegroundColor Yellow
                Return
            }
        } while (-not (Validar-IP $ip))

        Write-Host "`n- Scan Iniciado -" -ForegroundColor Yellow

        $totalPortas = 65535
        $portasAbertas = [System.Collections.ArrayList]::new()
        $timeout = 200 # ms
        $maxThreads = 100 # Ajuste conforme necessário
        $blockSize = 500 # Tamanho do bloco para exibir progresso

        # Objeto para sincronização
        $syncObject = New-Object System.Object

        # Cria pool de runspaces
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxThreads)
        $runspacePool.Open()
        $runspaces = New-Object System.Collections.ArrayList

        [console]::TreatControlCAsInput = $false

        try {
            # Inicia o scan
            for ($porta = 1; $porta -le $totalPortas; $porta++) {
                # Mostra progresso a cada bloco
                if ($porta % $blockSize -eq 0) {
                    $percentComplete = [math]::Round(($porta/$totalPortas)*100, 2)
                    Write-Progress -Activity "Varredura de portas em andamento" `
                        -Status "$percentComplete% completo" `
                        -PercentComplete $percentComplete `
                        -CurrentOperation "Testando portas $porta ate $($porta + $blockSize)"
                }

                # Cria e configura o runspace
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                [void]$powershell.AddScript({
                    param($ip, $porta, $timeout, $syncObject)
                    
                    try {
                        $tcpClient = New-Object System.Net.Sockets.TcpClient
                        $async = $tcpClient.BeginConnect($ip, $porta, $null, $null)
                        $wait = $async.AsyncWaitHandle.WaitOne($timeout, $false)

                        if ($wait -and $tcpClient.Connected) {
                            $tcpClient.EndConnect($async)
                            
                            # Sincroniza a saída
                            [System.Threading.Monitor]::Enter($syncObject)
                            try {
                                Write-Host "[+] Porta $porta Aberta" -ForegroundColor Green
                                return $porta
                            } finally {
                                [System.Threading.Monitor]::Exit($syncObject)
                            }
                        }
                    } catch {
                        # Silencia erros de conexão
                    } finally {
                        if ($tcpClient) {
                            $tcpClient.Close()
                            $tcpClient.Dispose()
                        }
                    }
                    return $null
                }).AddArgument($ip).AddArgument($porta).AddArgument($timeout).AddArgument($syncObject)

                # Adiciona à lista de forma thread-safe
                [System.Threading.Monitor]::Enter($syncObject)
                try {
                    [void]$runspaces.Add([PSCustomObject]@{
                        Pipe = $powershell
                        Async = $powershell.BeginInvoke()
                        Porta = $porta
                    })
                } finally {
                    [System.Threading.Monitor]::Exit($syncObject)
                }

                # Processa os resultados completos periodicamente
                [System.Threading.Monitor]::Enter($syncObject)
                try {
                    $completed = $runspaces | Where-Object { $_.Async.IsCompleted } | ForEach-Object { $_ }
                    
                    foreach ($runspace in $completed) {
                        $result = $runspace.Pipe.EndInvoke($runspace.Async)
                        if ($result -ne $null) {
                            [void]$portasAbertas.Add($result)
                        }
                        $runspace.Pipe.Dispose()
                        $runspaces.Remove($runspace)
                    }
                } finally {
                    [System.Threading.Monitor]::Exit($syncObject)
                }
            }

            # Processa quaisquer runspaces restantes
            while ($runspaces.Count -gt 0) {
                [System.Threading.Monitor]::Enter($syncObject)
                try {
                    $completed = $runspaces | Where-Object { $_.Async.IsCompleted } | ForEach-Object { $_ }
                    
                    foreach ($runspace in $completed) {
                        $result = $runspace.Pipe.EndInvoke($runspace.Async)
                        if ($result -ne $null) {
                            [void]$portasAbertas.Add($result)
                        }
                        $runspace.Pipe.Dispose()
                        $runspaces.Remove($runspace)
                    }
                } finally {
                    [System.Threading.Monitor]::Exit($syncObject)
                }
                
                Start-Sleep -Milliseconds 100
            }
        }
        catch {
            Write-Host "`nVarredura interrompida: $_" -ForegroundColor Red
        }
        finally {
            # Limpeza final
            foreach ($runspace in $runspaces) {
                $runspace.Pipe.Dispose()
            }
            $runspacePool.Close()
            $runspacePool.Dispose()
            Write-Progress -Activity "Varredura de portas" -Completed
            [console]::TreatControlCAsInput = $true
        }

        Write-Host "`nResumo final:" -ForegroundColor Yellow
        Write-Host "Total de portas abertas encontradas: $($portasAbertas.Count)" -ForegroundColor Green
        
        if ($portasAbertas.Count -gt 0) {
            Write-Host "Lista completa de portas abertas (ordenadas):"
            $portasAbertas = $portasAbertas | Sort-Object
            $portasAbertas | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
        }

        Write-Host "`nVarredura de portas concluida!" -ForegroundColor Yellow
    }
