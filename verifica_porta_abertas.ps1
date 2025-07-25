function Validar-IP {
        param (
            [string]$ip
        )
        $regex = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
        return ($ip -match $regex)
}

function Pingar-Todas-Portas-Ip { # TOP TOP TOP
        Write-Host "`n"
        Write-Host "Obs: Esta acao pode levar alguns minutos (65535 portas)" -ForegroundColor Yellow
        
        do {
            $ip = Read-Host "`nDigite o IP (alvo)"
            if (-not (Validar-IP $ip)) {
                Write-Host "`nEndereco IP invalido. Tente novamente." -ForegroundColor Yellow 
                return
            } else {
                
            }
        } while (-not (Validar-IP $ip))

        Write-Host "`n- Scan Iniciado -" -ForegroundColor Yellow

        $totalPortas = 65535
        $portasAbertas = @()
        $progress = 0

        [console]::TreatControlCAsInput = $false

        try {
            for ($porta = 1; $porta -le $totalPortas; $porta++) {
                $progress++
                Write-Progress -Activity "Varredura de portas em andamento" `
                    -Status "$([math]::Round(($progress/$totalPortas)*100, 2))% completo" `
                    -PercentComplete ($progress / $totalPortas * 100) `
                    -CurrentOperation "Testando porta $porta"

                try {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $async = $tcpClient.BeginConnect($ip, $porta, $null, $null)
                    $wait = $async.AsyncWaitHandle.WaitOne(200, $false)

                    if ($wait -and $tcpClient.Connected) {
                        $tcpClient.EndConnect($async)
                        Write-Host "Porta $porta Aberta" -ForegroundColor Green
                        $portasAbertas += $porta
                    }

                    $tcpClient.Close()
                    $tcpClient.Dispose()
                } catch {
                    # Silencia erros
                }
            }
        }
        catch {
            Write-Host "`nVarredura interrompida pelo usuário." -ForegroundColor Yellow
        }
        finally {
            Write-Progress -Activity "Varredura de portas" -Completed
            [console]::TreatControlCAsInput = $true
        }

        Write-Host "`nPortas abertas encontradas: $($portasAbertas.Count)" -ForegroundColor Green
        if ($portasAbertas.Count -gt 0) {
            Write-Host "Lista de portas abertas (ordenadas):"
            $portasAbertas = $portasAbertas | Sort-Object
            $portasAbertas | ForEach-Object { Write-Host $_ -ForegroundColor Green }
        }

        Write-Host "`nVarredura de portas concluída!" -ForegroundColor Yellow
    }
