# Função para exibir informações do computador
function Show-ComputerInfo {
    # Obtém o nome do usuário atual
    $usuario = $env:USERNAME

    # Obtém o nome do computador
    $nomeComputador = $env:COMPUTERNAME

    # Obtém o endereço IP da máquina
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }).IPAddress

    # Obtém o número de portas TCP e UDP abertas
    $portasTCP = (Get-NetTCPConnection -State Listen).Count
    $portasUDP = (Get-NetUDPEndpoint).Count

    # Lista de portas potencialmente perigosas
    $portasPerigosas = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3389, 8080)
    $portasAbertasPerigosas = Get-NetTCPConnection -State Listen | Where-Object { $portasPerigosas -contains $_.LocalPort } | Select-Object LocalPort

    # Obtém informações sobre o sistema operacional
    $sistemaOperacional = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption

    # Obtém a quantidade de usuários no sistema
    $usuarios = Get-LocalUser | Measure-Object | Select-Object -ExpandProperty Count

    # Obtém informações sobre a memória RAM
    $memoriaRAM = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
    $memoriaRAMGB = [math]::Round($memoriaRAM / 1GB, 2)

    # Obtém informações sobre o espaço em disco
    $disco = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
    $espacoTotalGB = [math]::Round($disco.Size / 1GB, 2)
    $espacoLivreGB = [math]::Round($disco.FreeSpace / 1GB, 2)

    # Obtém informações sobre a CPU
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExpandProperty Name

    # Obtém a data e hora da última inicialização do sistema
    $ultimaInicializacao = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

    # Verifica se o Firewall está ativo
    $firewallStatus = (Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }).Count -gt 0

    # Verifica se o Windows Update está configurado para atualizações automáticas
    $updateStatus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").AUOptions

    # Verifica se o antivírus está instalado e ativo
    $antivirusStatus = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct).productState -ne $null

    # Verifica se o BitLocker está ativado
    $bitlockerStatus = (Get-BitLockerVolume -MountPoint "C:").ProtectionStatus -eq "On"

    # Verifica se o UAC (Controle de Conta de Usuário) está ativado
    $uacStatus = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System").EnableLUA -eq 1

    # Exibe as informações
    Write-Host "`n=== Informações do Computador ===" -ForegroundColor Cyan
    Write-Host "`n[Usuário]" -ForegroundColor Yellow
    Write-Host "Usuário atual: $usuario"

    Write-Host "`n[Rede]" -ForegroundColor Yellow
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

    Write-Host "`n[Sistema]" -ForegroundColor Yellow
    Write-Host "Sistema Operacional: $sistemaOperacional"
    Write-Host "Quantidade de usuários no sistema: $usuarios"
    Write-Host "Última inicialização do sistema: $ultimaInicializacao"

    Write-Host "`n[Hardware]" -ForegroundColor Yellow
    Write-Host "Processador (CPU): $cpu"
    Write-Host "Memória RAM total: $memoriaRAMGB GB"
    Write-Host "Espaço em disco (C:):"
    Write-Host "  - Total: $espacoTotalGB GB"
    Write-Host "  - Livre: $espacoLivreGB GB"

    Write-Host "`n[Segurança]" -ForegroundColor Yellow
    Write-Host "Firewall ativo: $(if ($firewallStatus) { 'Sim' } else { 'Não' })"
    Write-Host "Atualizações automáticas: $(if ($updateStatus -eq 4) { 'Sim' } else { 'Não' })"
    Write-Host "Antivírus instalado e ativo: $(if ($antivirusStatus) { 'Sim' } else { 'Não' })"
    Write-Host "BitLocker ativado: $(if ($bitlockerStatus) { 'Sim' } else { 'Não' })"
    Write-Host "UAC (Controle de Conta de Usuário) ativado: $(if ($uacStatus) { 'Sim' } else { 'Não' })"
    Write-Host "`n===============================`n" -ForegroundColor Cyan
    # Solicitar ao usuário se deseja obter informações mais detalhadas
    $detalhes = Read-Host "`n`nVocê deseja obter informações mais detalhadas? (1/0)"

    # Verificar a resposta do usuário
    if ($detalhes -eq "1") {
        Get-ComputerInfo | Format-List * 
    }

    Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Red
    $null = Read-Host

    # Limpa o terminal
    Clear-Host
}

# Função para exibir informações avançadas dos usuários do sistema
function Show-UserInfo {
    Write-Host "`n=== Informações Avançadas de Usuários do Sistema ===" -ForegroundColor Blue

    # Obtém todos os usuários locais
    $usuarios = Get-LocalUser

    if ($usuarios.Count -eq 0) {
        Write-Host "Nenhum usuário local encontrado." -ForegroundColor Red
    }
    else {
        # Obtém a política de senha do sistema
        $politicaSenha = Get-LocalUser | Select-Object -First 1 | ForEach-Object {
            $politica = Get-LocalUser -Name $_.Name | Select-Object PasswordNeverExpires, PasswordRequired
            @{
                PasswordNeverExpires = $politica.PasswordNeverExpires
                PasswordRequired = $politica.PasswordRequired
            }
        }

        # Exibe a política de senha
        Write-Host "`n=== Política de Senha do Sistema ===" -ForegroundColor Cyan
        Write-Host "Senha nunca expira? $($politicaSenha.PasswordNeverExpires)"
        Write-Host "Senha é obrigatória? $($politicaSenha.PasswordRequired)"
        Write-Host "==============================="

        # Itera sobre cada usuário e exibe informações detalhadas
        $usuarios | ForEach-Object {
            $usuario = $_
            $grupos = Get-LocalGroup | ForEach-Object {
                $grupo = $_
                if (Get-LocalGroupMember -Group $grupo.Name | Where-Object { $_.Name -eq $usuario.Name }) {
                    $grupo.Name
                }
            }

            # Verifica se o usuário é administrador
            $isAdmin = if ($grupos -contains "Administrators") { "Sim" } else { "Não" }

            # Verifica se a conta está desativada
            $contaDesativada = if ($usuario.Enabled -eq $false) { "Sim" } else { "Não" }

            # Verifica se a conta está expirada
            $contaExpirada = if ($usuario.PasswordExpires -eq $null -or $usuario.PasswordExpires -lt (Get-Date)) { "Sim" } else { "Não" }

            # Verifica se a senha está em branco
            $senhaEmBranco = if ($usuario.PasswordRequired -eq $false) { "Sim" } else { "Não" }

            # Verifica se o usuário nunca fez login
            $ultimoLogin = if ($usuario.LastLogon -eq $null) { "Nunca fez login" } else { $usuario.LastLogon }

            # Exibe as informações do usuário
            Write-Host "`n=== Usuário: $($usuario.Name) ===" -ForegroundColor Cyan
            Write-Host "Nome completo: $($usuario.FullName)"
            Write-Host "Descrição: $($usuario.Description)"
            Write-Host "É administrador? $isAdmin"
            Write-Host "Grupos: $($grupos -join ', ')"
            Write-Host "Conta desativada? $contaDesativada"
            Write-Host "Conta expirada? $contaExpirada"
            Write-Host "Senha em branco? $senhaEmBranco"
            Write-Host "Senha nunca expira? $($usuario.PasswordNeverExpires)"
            Write-Host "Último login: $ultimoLogin"
            Write-Host "Última alteração de senha: $($usuario.PasswordLastSet)"
            Write-Host "==============================="
        }
    }

    # Verifica usuários atualmente logados
    Write-Host "`n=== Usuários Atualmente Logados ===" -ForegroundColor Green
    $usuariosLogados = Get-Process -IncludeUserName | Select-Object UserName -Unique
    if ($usuariosLogados.Count -eq 0) {
        Write-Host "Nenhum usuário logado no momento." -ForegroundColor Red
    }
    else {
        $usuariosLogados | ForEach-Object {
            Write-Host "Usuário logado: $($_.UserName)"
        }
    }

    Write-Host "`n===============================`n"
    Write-Host "`nPressione qualquer tecla para continuar..."
    $null = Read-Host

    # Limpa o terminal
    Clear-Host
}

function Show-TCPPorts {
    Write-Host "`n=== Portas TCP Abertas ===" -ForegroundColor Green

    # Obtém as conexões TCP no estado "Listen" (Aberto) com o ID do processo e o nome do aplicativo
    $portasTCP = Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, State, OwningProcess

    if ($portasTCP.Count -eq 0) {
        Write-Host "Nenhuma porta TCP aberta encontrada." -ForegroundColor Red
        Write-Host "`nPressione qualquer tecla para continuar..."
        $null = Read-Host

        # Limpa o terminal
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

        # Pergunta ao usuário se deseja encerrar um processo ou voltar ao menu
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

        Write-Host "`nPressione qualquer tecla para continuar..."
        $null = Read-Host

        # Limpa o terminal
        Clear-Host
    }

    Write-Host "=========================`n"
}

# Função para listar todas as portas UDP abertas
function Show-UDPPorts {
    Write-Host "`n=== Portas UDP Abertas ===" -ForegroundColor Yellow

    # Obtém as portas UDP com o ID do processo e o nome do aplicativo
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

        # Pergunta ao usuário se deseja encerrar um processo ou voltar ao menu
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

    Write-Host "`nPressione qualquer tecla para continuar..."
    $null = Read-Host

    # Limpa o terminal
    Clear-Host

    Write-Host "=========================`n"
}

function Show-Apps {
    # Obtém o nome do usuário ativo
    $usuarioAtivo = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Lista todos os processos em execução e filtra pelo usuário ativo
    $processos = Get-Process | Where-Object { $_.SessionId -eq (Get-Process -Id $PID).SessionId } | Select-Object Id, ProcessName, MainWindowTitle, Path

    Write-Host "`n=== Aplicativos em Execução no Perfil do Usuário Ativo ===" -ForegroundColor Cyan
    $processos | Format-Table -AutoSize -Property Id, ProcessName, MainWindowTitle, Path

    # Pergunta ao usuário se deseja encerrar um processo ou voltar ao menu
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
    Write-Host "`nPressione qualquer tecla para continuar..."
    $null = Read-Host

    # Limpa o terminal
    Clear-Host

    Write-Host "=========================`n"
}

# Menu principal
while ($true) {
    Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          === Menu Principal ===      ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║ 1. Mostrar informações do computador ║" -ForegroundColor Green
    Write-Host "║                                      ║" -ForegroundColor Green
    Write-Host "║ 2. Informações avançadas de Usuários ║" -ForegroundColor Green
    Write-Host "║                                      ║" -ForegroundColor Green
    Write-Host "║ 3. Listar portas TCP abertas         ║" -ForegroundColor Green
    Write-Host "║                                      ║" -ForegroundColor Green
    Write-Host "║ 4. Listar portas UDP abertas         ║" -ForegroundColor Green
    Write-Host "║                                      ║" -ForegroundColor Green
    Write-Host "║ 5. Listar aplicativos em USO         ║" -ForegroundColor Green
    Write-Host "║                                      ║" -ForegroundColor Green
    Write-Host "║ 0. Sair                              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Green
    $opcao = Read-Host "`nEscolha uma opção (1-0)" 

    if ($opcao -eq 1) {
        # Mostrar informações do computador
        Show-ComputerInfo
    }
    elseif ($opcao -eq 2) {
        # Filtrar e listar portas TCP
        Show-UserInfo
    }
    elseif ($opcao -eq 3) {
        # Filtrar e listar portas TCP
        Show-TCPPorts
    }
    elseif ($opcao -eq 4) {
        # Filtrar e listar portas UDP
        Show-UDPPorts
    }
    elseif ($opcao -eq 5) {
        # Listar e encerrar aplicativos
        Show-Apps
    }
    elseif ($opcao -eq 0) {
        # Sair do script
        Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║            Saindo...                 ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Red
        break
    }
    else {
        Write-Host "Opção inválida. Tente novamente." -ForegroundColor Red
        Write-Host "`nPressione qualquer tecla para continuar..."
        $null = Read-Host

        # Limpa o terminal
        Clear-Host

        Write-Host "=========================`n"
    }
}
