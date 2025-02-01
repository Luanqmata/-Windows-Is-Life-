function Show-ComputerInfo {
    $usuario = $env:USERNAME

    $nomeComputador = $env:COMPUTERNAME

    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress

    $portasTCP = (Get-NetTCPConnection -State Listen).Count
    $portasUDP = (Get-NetUDPEndpoint).Count

    $portasPerigosas = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3389, 8080)
    $portasAbertasPerigosas = Get-NetTCPConnection -State Listen | Where-Object { $portasPerigosas -contains $_.LocalPort } | Select-Object LocalPort

    $sistemaOperacional = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption

    $usuarios = Get-LocalUser | Measure-Object | Select-Object -ExpandProperty Count

    $memoriaRAM = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
    $memoriaRAMGB = [math]::Round($memoriaRAM / 1GB, 2)

    $disco = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
    $espacoTotalGB = [math]::Round($disco.Size / 1GB, 2)
    $espacoLivreGB = [math]::Round($disco.FreeSpace / 1GB, 2)

    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty Name

    $ultimaInicializacao = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

    $firewallStatus = (Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }).Count -gt 0

    $updateStatus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").AUOptions

    $antivirusStatus = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct).productState -ne $null

    $bitlockerStatus = (Get-BitLockerVolume -MountPoint "C:").ProtectionStatus -eq "On"

    $uacStatus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA -eq 1

    Write-Host "`n=== Informacoes do Computador ===" -ForegroundColor Cyan
    Write-Host "`n      [Usuario]" -ForegroundColor Yellow
    Write-Host "Usuario atual: $usuario"

    Write-Host "`n       [Rede]" -ForegroundColor Yellow
    Write-Host "Nome do computador: $nomeComputador"
    Write-Host "Endereço IP: $ip"
    Write-Host "Portas TCP abertas: $portasTCP"
    Write-Host "Portas UDP abertas: $portasUDP"
    if ($portasAbertasPerigosas) {
        Write-Host "Portas potencialmente perigosas abertas: " -ForegroundColor Red -NoNewline
        Write-Host ($portasAbertasPerigosas.LocalPort -join ", ") -ForegroundColor Red
    } else {
        Write-Host "Portas potencialmente perigosas abertas: Nenhuma" -ForegroundColor Green
    }

    Write-Host "`n       [Sistema]" -ForegroundColor Yellow
    Write-Host "Sistema Operacional: $sistemaOperacional"
    Write-Host "Quantidade de usuarios no sistema: $usuarios"
    Write-Host "Ultima inicializacao do sistema: $ultimaInicializacao"

    Write-Host "`n      [Hardware]" -ForegroundColor Yellow
    Write-Host "Processador (CPU): $cpu"
    Write-Host "Memória RAM total: $memoriaRAMGB GB"
    Write-Host "Espaco em disco (C:):"
    Write-Host "  - Total: $espacoTotalGB GB"
    Write-Host "  - Livre: $espacoLivreGB GB"

    Write-Host "`n      [Segurança]" -ForegroundColor Yellow
    Write-Host "Firewall ativo: $(if ($firewallStatus) { 'Sim' } else { 'Não' })"
    Write-Host "Atualizacoes automaticas: $(if ($updateStatus -eq 4) { 'Sim' } else { 'Não' })"
    Write-Host "Antivirus instalado e ativo: $(if ($antivirusStatus) { 'Sim' } else { 'Não' })"
    Write-Host "BitLocker ativado: $(if ($bitlockerStatus) { 'Sim' } else { 'Não' })"
    Write-Host "UAC (Controle de Conta de Usuario) ativado: $(if ($uacStatus) { 'Sim' } else { 'Não' })"
    Write-Host "`n===============================`n" -ForegroundColor Cyan

    $detalhes = Read-Host "`n`nVoce deseja obter informacoes mais detalhadas? (1/0)"

    if ($detalhes -eq "1") {
        Get-ComputerInfo | Format-List * 
    }

    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
    $null = Read-Host

    Clear-Host
}

function Show-UserInfo {
    function Show-Menu {
        Clear-Host
       Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                     === Menu de Informacoes de Usuarios ===                  ║" -ForegroundColor Red
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║  1. Listar Usuarios                                                          ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  2. Visualizar Informacoes de um Usuario                                     ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  3. Exibir Grupos                                                            ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  4. Criar um Usuario                                                         ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  5. Escalar Privilegios                                                      ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  6. Deletar um Usuario                                                       ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  7. Mostrar Usuarios Logados                                                 ║" -ForegroundColor Red
    Write-Host "║                                                                              ║" -ForegroundColor Red
    Write-Host "║  8. Voltar ao menu inicial                                                   ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝`n`n" -ForegroundColor Red
    }

    # Função para listar usuários
    function List-Users {
        Write-Host "`n=== Lista de Usuarios ===" -ForegroundColor Green
        net user | ForEach-Object { Write-Host $_ }
    }

    # Função para visualizar informações de um usuário específico
    function Get-UserInfo {
        net user | ForEach-Object { Write-Host $_ }
        $username = Read-Host "`nDigite o nome do usuario"
        Write-Host "`n=== Informacoes do Usuario: $username ===" -ForegroundColor Green
        net user $username | ForEach-Object { Write-Host $_ }
    }

    # Função para exibir grupos
    function Show-Groups {
        Write-Host "`n=== Lista de Grupos ===" -ForegroundColor Green
        net localgroup | ForEach-Object { Write-Host $_ }

        $choice = Read-Host "`nDeseja visualizar os membros de algum grupo? (1 para Sim, 0 para Nao)"
        if ($choice -eq 1) {
            $groupName = Read-Host "Digite o nome do grupo"
            Write-Host "`n=== Membros do Grupo: $groupName ===" -ForegroundColor Green
            net localgroup $groupName | ForEach-Object { Write-Host $_ }
        }
    }

    # Função para criar um usuário
    function Create-User {
        $username = Read-Host "Digite o nome do novo usuario"
        $password = Read-Host "Digite a senha para o novo usuario" -AsSecureString
        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        net user $username $password /ADD
        Write-Host "Usuario $username criado com sucesso!" -ForegroundColor Green
    }

    # Função para adicionar um usuário ao grupo de administradores
    function Add-UserToAdminGroup {
        # Lista todos os usuários
        List-Users

        # Solicita o nome do usuário
        $username = Read-Host "Digite o nome do usuario que deseja adicionar ao grupo de administradores"

        # Verifica se o usuário existe
        $userExists = net user $username 2>&1 | Select-String "O nome da conta poderia não ser encontrado"
        if ($userExists) {
            Write-Host "Erro: O usuario '$username' nao existe." -ForegroundColor Red
            return
        }

        # Adiciona o usuário ao grupo de administradores
        try {
            net localgroup Administradores $username /ADD
            Write-Host "Usuario '$username' adicionado ao grupo de administradores com sucesso!" -ForegroundColor Green
        }
        catch {
            Write-Host "Erro ao adicionar o usuario '$username' ao grupo de administradores. Certifique-se de que o PowerShell está sendo executado como administrador." -ForegroundColor Red
    }
}

    # Função para deletar um usuário
    function Delete-User {
        List-Users
        $username = Read-Host "Digite o nome do usuario que deseja deletar"
        net user $username /DELETE
        Write-Host "Usuario $username deletado com sucesso!" -ForegroundColor Green
    }

    # Verifica usuários atualmente logados
    function Show-LoggedInUsers {
        Write-Host "`n=== Usuarios Atualmente Logados ===" -ForegroundColor Green
        $usuariosLogados = Get-Process -IncludeUserName | Select-Object UserName -Unique
        if ($usuariosLogados.Count -eq 0) {
            Write-Host "Nenhum usuario logado no momento." -ForegroundColor Red
        }
        else {
            $usuariosLogados | ForEach-Object {
                Write-Host "Usuario logado: $($_.UserName)"
            }
        }
    }

    # Loop do menu
    do {
        Show-Menu
        $choice = Read-Host "Escolha uma opcao (1-8)"

        switch ($choice) {
            1 { List-Users }
            2 { Get-UserInfo }
            3 { Show-Groups }
            4 { Create-User }
            5 { Add-UserToAdminGroup }
            6 { Delete-User }
            7 { Show-LoggedInUsers }
            8 { Write-Host "Saindo..." -ForegroundColor Yellow; break }
            default { Write-Host "Opcao invalida. Tente novamente." -ForegroundColor Red }
        }

        if ($choice -ne 8) {
            Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
            $null = Read-Host
        }
    } while ($choice -ne 8)
}

function Show-TCPPorts {
    Write-Host "`n              === Portas TCP Abertas ===" -ForegroundColor Green

    $portasTCP = Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, State, OwningProcess

    if ($portasTCP.Count -eq 0) {
        Write-Host "Nenhuma porta TCP aberta encontrada." -ForegroundColor Red
        Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
        $null = Read-Host

        Clear-Host
    }
    else {
        $portasTCP | ForEach-Object {
            $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            $appName = if ($process) { $process.ProcessName } else { "N/A" }
            $_ | Add-Member -MemberType NoteProperty -Name "AppName" -Value $appName -Force
            $_.State = "Escutando"
            $_
        } | Format-Table -Property LocalAddress, LocalPort, State, OwningProcess, AppName -AutoSize

        $opcao = Read-Host "`nDeseja encerrar algum processo? (1 - Encerrar, 0 - Voltar ao menu)"
        if ($opcao -eq 1) {
            $processID = Read-Host "Digite o ID do processo que deseja encerrar"
            Stop-Process -Id $processID -Force -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Processo $processID encerrado com sucesso." -ForegroundColor Green
            }
            else {
                Write-Host "Falha ao encerrar o processo $processID." -ForegroundColor Red
            }
        }
        elseif ($opcao -eq 0) {
            Write-Host "Voltando ao menu inicial." -ForegroundColor Yellow
        }
        else {
            Write-Host "Opção inválida. Voltando ao menu inicial." -ForegroundColor Red
        }

        Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
        $null = Read-Host

        Clear-Host
    }

    Write-Host "=========================`n"
}

function Show-UDPPorts {
    Write-Host "`n              === Portas UDP Abertas ===" -ForegroundColor Yellow

    
    $portasUDP = Get-NetUDPEndpoint | Select-Object LocalAddress, LocalPort, OwningProcess

    if ($portasUDP.Count -eq 0) {
        Write-Host "Nenhuma porta UDP aberta encontrada." -ForegroundColor Red
    }
    else {
        $portasUDP | ForEach-Object {
            $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            $appName = if ($process) { $process.ProcessName } else { "N/A" }
            $_ | Add-Member -MemberType NoteProperty -Name "AppName" -Value $appName -Force
            $_ | Add-Member -MemberType NoteProperty -Name "State" -Value "Escutando" -Force
            $_
        } | Format-Table -Property LocalAddress, LocalPort, State, OwningProcess, AppName -AutoSize

        $opcao = Read-Host "`nDeseja encerrar algum processo? (1 - Encerrar, 0 - Voltar ao menu)"
        if ($opcao -eq 1) {
            $processID = Read-Host "Digite o ID do processo que deseja encerrar"
            Stop-Process -Id $processID -Force -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Processo $processID encerrado com sucesso." -ForegroundColor Green
            }
            else {
                Write-Host "Falha ao encerrar o processo $processID." -ForegroundColor Red
            }
        }
        elseif ($opcao -eq 0) {
            Write-Host "Voltando ao menu inicial." -ForegroundColor Yellow
        }
        else {
            Write-Host "Opção inválida. Voltando ao menu inicial." -ForegroundColor Red
        }
    }

    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
    $null = Read-Host

    Clear-Host

    Write-Host "=========================`n"
}

function Show-Apps {
    $usuarioAtivo = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    $processos = Get-Process | Where-Object { $_.SessionId -eq (Get-Process -Id $PID).SessionId } | Select-Object Id, ProcessName, MainWindowTitle, Path

    Write-Host "`n=== Aplicativos em Execucao no Perfil do Usuario Ativo ===" -ForegroundColor Cyan
    $processos | Format-Table -AutoSize -Property Id, ProcessName, MainWindowTitle, Path

    $opcao = Read-Host "`nDeseja encerrar algum processo? (1 - Encerrar, 0 - Voltar ao menu)"
    if ($opcao -eq 1) {
        $processID = Read-Host "Digite o ID do processo que deseja encerrar"
        Stop-Process -Id $processID -Force -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "Processo $processID encerrado com sucesso." -ForegroundColor Green
        }
        else {
            Write-Host "Falha ao encerrar o processo $processID." -ForegroundColor Red
        }
    }
    elseif ($opcao -eq 0) {
        Write-Host "Voltando ao menu inicial." -ForegroundColor Yellow
    }
    else {
        Write-Host "Opcao invalida. Voltando ao menu inicial." -ForegroundColor Red
    }
    Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
    $null = Read-Host

    Clear-Host

}

function Wmap {
    function Show-Menu {
        Clear-Host
        Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                                 === WMap ===                                 ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                 1. Pingar IP                                                 ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                 2. Criar Lista de IP                                         ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                 3. Pingar Maq da rede                                        ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                 4. Pingar Porta Espcifica ( S/ rastros)                      ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║                 0. Menu Principal                                            ║" -ForegroundColor Red
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝`n`n" -ForegroundColor Red
    }

    function Pingar-Ip {
        Write-Host "`n"
        $ip = Read-Host "Digite o IP"
        Write-Host "`nEfetuando ping no host: $ip"
        $pingResult = Test-Connection -ComputerName $ip -Count 3 -Quiet
        if ($pingResult) {
            Write-Host "`n               - - RED TEAM - - " -ForegroundColor Red
            ping -n 5 $ip | Select-String "bytes=32"
            Write-Host "`n`nO host: $ip :ONLINE" -ForegroundColor Green
        } else {
            ping -n 5 $ip | Select-String "bytes=32"
            Write-Host "`n`nFalha ao pingar o host: $ip :OFFLINE" -ForegroundColor Red
        }
    }

    function Criar-Lista {
        Write-Host "`n"
        $baseIP = Read-Host "Digite a parte inicial do IP (Ex: 192.168.10.)"
    
        if (-not $baseIP.EndsWith(".")) {
            Write-Host "Formato inválido. Certifique-se de incluir o ponto final (Ex: 192.168.10.)" -ForegroundColor Red
            return
        }

        Write-Host "`nGerando lista de IPs..." -ForegroundColor Yellow

        foreach ($i in 1..254) {
            $ip = "$baseIP$i"
            Write-Host $ip
        }

        Write-Host "`nLista de IPs gerada com sucesso!" -ForegroundColor Green
        }

    function Pingar-Ip-Rede {
        Write-Host "`n"
        $baseIP = Read-Host "Digite a parte inicial do IP (Ex: 192.168.10.)"

        # Verifica se o usuário digitou um valor válido
        if (-not $baseIP.EndsWith(".")) {
            Write-Host "Formato inválido. Certifique-se de incluir o ponto final (Ex: 192.168.10.)" -ForegroundColor Red
            return
        }

        Write-Host "`nPingando endereços de 1 a 254 do IP $baseIP ..." -ForegroundColor Yellow

        # Loop para pingar cada IP na rede
        foreach ($ip in 1..254) {
            $fullIP = "$baseIP$ip" # Concatena a base do IP com o número atual
            Write-Host "Pingando $fullIP..." -ForegroundColor Cyan
            $result = ping -n 1 $fullIP | Select-String "bytes=32"

            # Exibe o resultado do ping
            if ($result) {
                Write-Host "$fullIP respondeu ao ping." -ForegroundColor Green
            } else {
                Write-Host "$fullIP não respondeu ao ping." -ForegroundColor Red
            }
        }

        Write-Host "`nPing concluído!" -ForegroundColor Yellow
    }

    function Pingar-Porta-IP {
        Write-Host "`n"
        $ip = Read-Host "Digite o IP"
        $porta = Read-Host "Digite a porta"

        if (-not $ip -or -not $porta) {
            Write-Host "Dados Inseridos corretamente..." -ForegroundColor Red
            return
        }

        # Valida se a porta é um número válido
        if (-not ($porta -match '^\d+$') -or [int]$porta -lt 1 -or [int]$porta -gt 65535) {
            Write-Host "`nPorta inválida. A porta deve ser um número entre 1 e 65535." -ForegroundColor Red
            return
        }

        Write-Host "`nVerificando a porta $porta no IP $ip..." -ForegroundColor Yellow

        # Testa a conexão com o IP e a porta e obtém detalhes completos
        $resultado = Test-NetConnection -ComputerName $ip -Port $porta -WarningAction SilentlyContinue

        # Exibe os detalhes da conexão
        Write-Host "`n=== Detalhes da Conexão ===" -ForegroundColor Cyan
        Write-Host "ComputerName: $($resultado.ComputerName)" -ForegroundColor Green
        Write-Host "RemoteAddress: $($resultado.RemoteAddress)" -ForegroundColor Green
        Write-Host "RemotePort: $($resultado.RemotePort)" -ForegroundColor Green
        Write-Host "InterfaceAlias: $($resultado.InterfaceAlias)" -ForegroundColor Green
        Write-Host "SourceAddress: $($resultado.SourceAddress)" -ForegroundColor Green
        Write-Host "PingReplyDetails (RTT): $($resultado.PingReplyDetails.RoundtripTime) ms" -ForegroundColor Green
        Write-Host "TcpTestSucceeded: $($resultado.TcpTestSucceeded)" -ForegroundColor Green

        # Resultado do teste de porta
        if ($resultado.TcpTestSucceeded) {
            Write-Host "`nPorta $porta está aberta no IP $ip." -ForegroundColor Green
        } else {
            Write-Host "`nPorta $porta está fechada no IP $ip." -ForegroundColor Red
        }
    }

    do {
        Show-Menu
        $choice = Read-Host "Escolha uma opcao (1-0)"

        switch ($choice) {
            1 { Pingar-Ip }
            2 { Criar-Lista }
            3 { Pingar-Ip-Rede }
            4 { Pingar-Porta-IP }
            0 { Write-Host "Voltando ao menu principal..." -ForegroundColor Yellow; break }
            default { Write-Host "Opcao invalida. Tente novamente." -ForegroundColor Red }
        }

        if ($choice -ne 0) {
            Write-Host "`nPressione Enter para continuar..." -ForegroundColor Green
            $null = Read-Host
        }
    } while ($choice -ne 0)
}

while ($true) {
    Clear-Host
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                          === Menu Principal ===                              ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 1. Mostrar informações do computador                         ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 2. Informações avançadas de Usuários                         ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 3. Listar portas TCP abertas                                 ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 4. Listar portas UDP abertas                                 ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 5. Listar aplicativos em USO                                 ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 6. WMap                                                      ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "║                 0. Sair                                                      ║" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    $opcao = Read-Host "`nEscolha uma opção (1-0)" 

    if ($opcao -eq 1) {
        Show-ComputerInfo
    }
    elseif ($opcao -eq 2) {
        Show-UserInfo
    }
    elseif ($opcao -eq 3) {
        Show-TCPPorts
    }
    elseif ($opcao -eq 4) {
        Show-UDPPorts
    }
    elseif ($opcao -eq 5) {
        Show-Apps
    }
    elseif ($opcao -eq 6){
        Wmap
    }
    elseif ($opcao -eq 0) {
        Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║                                  Saindo...                                   ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        break
    }
    else {
        Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
        Write-Host "`nPressione qualquer tecla para continuar..."
        $null = Read-Host

        Clear-Host
    }
}
