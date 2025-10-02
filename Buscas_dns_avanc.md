# DNS Lookup & PowerShell Commands

## nslookup

nslookup http://scanme.nmap.org

$n = nslookup http://scanme.nmap.org

### Obter endereço (versão e pktoken)

$n.address

---

## Resolve-DnsName (obter IP e endereço)

Resolve-DnsName -Name scanme.nmap.org

---

## Consultar registros MX (Mail Exchange)

Resolve-DnsName -Name scanme.nmap.org -Type MX

$r.NameAdministrator

---

## Consultar registros A (endereços IPv4)

$r = Resolve-DnsName -Name google.com -Type A
$r

### Capturar apenas o IP

$r = Resolve-DnsName -Name scanme.nmap.org -Type A
$r.IpAddress

Exemplo de saída esperada:

45.33.32.156

---

## Testes com tipos inválidos ou múltiplos

### Tipo inválido (exemplo: DFD)

Resolve-DnsName -Name scanme.nmap.org -Type DFD

### Consultar todos os tipos de registros DNS

Resolve-DnsName -Name google.com -Type ALL

$r = Resolve-DnsName -Name google.com -Type ALL

### Ver estrutura de membros do resultado

$r | Get-Member

---

## Autocompletar no PowerShell

Resolve-DnsName -Name google.com -Type ALL  # (pressione Tab para autocompletar)
