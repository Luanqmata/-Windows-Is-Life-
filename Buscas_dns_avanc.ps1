nslookup http://scanme.nmap.org

$n = nslookup http://scanme.nmap.org 

----
$n.address ( versão , pktoken )

----
Resolve-DnsName -name scanme.nmap.org (pega o ip e endereço)

----
Resolve-DnsName -name scanme.nmap.org -Type mx 
----
$r.NameAdministrator

----
$r = Resolve-DnsName -Name google.com -Type a
$r

--- captura IP

$r = Resolve-DnsName -Name scanme.nmap.org -Type a
$r.IpAddress
45.33.32.156

--- 

Resolve-DnsName -name scanme.nmap.org -Type dfd

Resolve-DnsName -name google.com -Type all

----

$r = Resolve-DnsName -name google.com -Type all

$r | get-member

---

Resolve-DnsName -Name google.com -Type ALL - (tab)
