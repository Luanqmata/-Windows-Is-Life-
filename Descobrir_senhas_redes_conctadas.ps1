# Colar codigo no powershell diretamente

$profiles = netsh wlan show profiles | Select-String "Todos os Perfis de Usuário|All User Profile"

foreach ($profile in $profiles) {
    $ssid = ($profile.Line -split ":")[1].Trim()
    $result = netsh wlan show profile name="$ssid" key=clear

    $passwordLine = $result | Select-String "Conteúdo da Chave|Key Content"

    if ($passwordLine) {
        $password = ($passwordLine.Line -split ":")[1].Trim()
    } else {
        $password = "senha não encontrada"
    }

    Write-Output "SSID: $ssid | Senha: $password"
}
