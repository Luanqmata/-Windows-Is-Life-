function Get-PortBanner {
    param (
        [string]$TargetHost,
        [int[]]$Ports = @(21,22,23,25,80,110,143,443,3389,8080)
    )

    foreach ($Port in $Ports) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $client.ReceiveTimeout = 3000
            $client.SendTimeout = 3000
            $client.Connect($TargetHost, $Port)

            if ($client.Connected) {
                $stream = $client.GetStream()
                $buffer = New-Object Byte[] 1024
                Start-Sleep -Milliseconds 500  # aguarda por banner

                $read = $stream.Read($buffer, 0, 1024)
                $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read)

                if ($response) {
                    Write-Host "[${TargetHost}:${Port}] Banner encontrado:`n$response`n" -ForegroundColor Green
                } else {
                    Write-Host "[${TargetHost}:${Port}] Sem banner visível" -ForegroundColor Yellow
                }

                $stream.Close()
                $client.Close()
            }
        }
        catch {
            Write-Host "[${TargetHost}:${Port}] Erro: $_" -ForegroundColor Red
        }
    }
}

# Exemplo de uso:
Get-PortBanner -TargetHost "scanme.nmap.org"
