$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$cpuInfo = Get-CimInstance -ClassName Win32_Processor
$memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
$networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled } | Select-Object -First 1

$totalMemoryBytes = 0
if ($memoryInfo) {
    foreach ($mem in $memoryInfo) {
        $totalMemoryBytes += $mem.Capacity
    }
}
$totalMemoryGB = [math]::Round($totalMemoryBytes / 1GB, 2)

$userName = $env:USERNAME
$macAddress = if ($networkInfo) { $networkInfo.MACAddress } else { "Não encontrado" }
$ipAddress = if ($networkInfo) { $networkInfo.IPAddress -join ", " } else { "Não encontrado" }


Write-Host "`n=== Informações do Sistema ===" -ForegroundColor Cyan
Write-Host "Nome do Computador : $($systemInfo.Name)"
Write-Host "Usuário Atual      : $userName"
Write-Host "Sistema Operacional: $($osInfo.Caption)"
Write-Host "Arquitetura        : $($osInfo.OSArchitecture)"
Write-Host "Processador        : $($cpuInfo.Name)"
Write-Host "Memória Total      : $totalMemoryGB GB"
Write-Host "Endereço MAC       : $macAddress"
Write-Host "Endereço IP        : $ipAddress"
