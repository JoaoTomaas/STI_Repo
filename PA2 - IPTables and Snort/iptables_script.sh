#!/bin/bash

### Firewall configuration to protect the router
#1. DNS name resolution requests sent to outside servers (/etc/services -------> DNS é chamado domain e tem porto 53)
iptables -A OUTPUT -d 23.214.219.132 -p udp --dport domain -j ACCEPT 
iptables -A OUTPUT -d 193.137.16.75 -p udp --dport domain -j ACCEPT 

iptables -A INPUT -s 23.214.219.132 -p udp --sport domain -j ACCEPT 
iptables -A INPUT -s 193.137.16.75 -p udp --sport domain -j ACCEPT


#2. SSH connections to the router system, if originated at the internal network or at the VPN gateway (vpn-gw)
iptables -A INPUT -s 23.214.219.129 -p tcp --dport ssh -j ACCEPT
iptables -A INPUT -s 192.168.10.0/24 -p tcp --dport ssh -j ACCEPT

iptables -A OUTPUT -d 23.214.219.129 -p tcp --sport ssh -j ACCEPT
iptables -A OUTPUT -d 192.168.10.0/24 -p tcp --sport ssh -j ACCEPT


### Firewall configuration to authorize direct communications (without NAT)
#1. Domain name resolutions using the dns server.
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport domain -d 23.214.219.132 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p udp --sport domain -s 23.214.219.132 -j ACCEPT

#2. The dns server should be able to resolve names using DNS servers on the Internet (dns2 and also others). (os da diretoria /etc/resolv.conf ??)
iptables -A FORWARD -s 23.214.219.132 -p udp --dport domain -d 193.137.16.75 -j ACCEPT
iptables -A FORWARD -d 23.214.219.132 -p udp --sport domain -s 193.137.16.75 -j ACCEPT

#3. The dns and dns2 servers should be able to synchronize the contents of DNS zones(https://ns1.com/resources/dns-zones-explained).
#//DNS server da DMZ inicia a ligação (ver se faz sentido)
iptables -A FORWARD -d 193.137.16.75 --dport 53  -p tcp -m state --state NEW,ESTABLISHED --sport 1024:65535 -s 23.214.219.132  -j ACCEPT
iptables -A FORWARD -s 193.137.16.75 --sport 53 -p tcp -m state --state ESTABLISHED --dport 1024:65535 -d 23.214.219.132 -j ACCEPT

#//DNS2 inicia a ligação
iptables -A FORWARD -d 23.214.219.132 --dport 53  -p tcp -m state --state NEW,ESTABLISHED --sport 1024:65535 -s 193.137.16.75 -j ACCEPT
iptables -A FORWARD -s 23.214.219.132 --sport 53 -p tcp -m state --state ESTABLISHED --dport 1024:65535 -d 193.137.16.75 -j ACCEPT

#4. SMTP connections to the smtp server.
iptables -A FORWARD -s 23.214.219.131 -p tcp --dport  smtp -d 192.168.10.0/24 -j ACCEPT
iptables -A FORWARD -d 23.214.219.131 -p tcp --sport smtp -s 192.168.10.0/24 -j ACCEPT

#5. POP and IMAP connections to the mail server (assumo que seja POP3)
(#Ainda tenho que perceber se é suposto fazer entre a internet e o mail server ou se isso faz sentido)
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport POP3 -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport POP3 -s 23.214.219.133 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport IMAP -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport IMAP -s 23.214.219.133 -j ACCEPT

#6. HTTP and HTTPS connections to the www server
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport http -d 23.214.219.130 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport http -s 23.214.219.130 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport https -d 23.214.219.130 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport https -s 23.214.219.130 -j ACCEPT

#7. OpenVPN connections to the vpn-gw server. 
#(Penso que tanto poderá ser tcp como udp)
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 1194 -d 23.214.219.129 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport 1194 -d 23.214.219.129 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport 1194 -s 23.214.219.129 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p udp --sport 1194 -s 23.214.219.129 -j ACCEPT
#(Não sei se é necessário configurar alguma interface, tipo tun0)

#8. VPN clients connected to the gateway (vpn-gw) should able to connect to the PosgreSQL service on the datastore server.
iptables -A FORWARD -s 23.214.219.129 -p tcp --dport 1194 -d 192.168.10.1 -j ACCEPT
iptables -A FORWARD -s 23.214.219.129 -p udp --dport 1194 -d 192.168.10.1 -j ACCEPT
iptables -A FORWARD -d 23.214.219.129 -p tcp --sport 1194 -s 192.168.10.1 -j ACCEPT
iptables -A FORWARD -d 23.214.219.129 -p udp --sport 1194 -s 192.168.10.1 -j ACCEPT

### Firewall configuration for connections to the external IP address of the firewall (using NAT) DNAT
#Dnat->mudar o destino da ligação.

#1. FTP connections (in passive and active modes) to the ftp server.
#FTP connections de onde ?????
#(active mais fácil)

iptables -t nat -A PREROUTING  -d 87.248.214.97 -m state --state NEW
 -p tcp --dport 21  -j DNAT --to-destination 192.168.10.1

iptables -A FORWARD  -d 192.168.10.1 -p tcp --dport 21 -j ACCEPT 
iptables -A FORWARD  -s 192.168.10.1 -p tcp --sport 20 -j ACCEPT 
iptables -t nat -A POSTROUTING -s 192.168.10.1 -p tcp --sport 20 -j SNAT --to-source 87.248.214.97

iptables -t nat -A PREROUTING  -d 87.248.214.97 -m state --state RELATED,ESTABLISHED -p tcp -j DNAT --to-destination 192.168.10.1
iptables -A FORWARD  -d 192.168.10.1 -m state --state RELATED,ESTABLISHED -p tcp -j ACCEPT 

#(Command channel)
iptables -A FORWARD  -d 192.168.10.1 -p tcp --dport 21 -j ACCEPT 
iptables -A FORWARD  -s 192.168.10.1 -p tcp --sport 21 -j ACCEPT 

#(Data channel Active)
iptables -A FORWARD  -s 192.168.10.1 -p tcp --sport 20 -j ACCEPT 
iptables -A FORWARD  -d 192.168.10.1 -p tcp --dport 20 -j ACCEPT 

#(Data channel Passive)
-p tcp -m state --state RELATED,ESTABLISHED

#2. SSH connections to the datastore server, but only if originated at the eden or dns2 servers.
#(substituir o -d por -o?????)
#(Depois do pre-routing é sempre preciso o foward como mostra o esquema)
iiptables -t nat -A PREROUTING -s 193.137.16.75 -d 87.248.214.97 -p tcp --dport ssh -j DNAT --to-destination 192.168.10.2
iptables -A FORWARD -s 193.137.16.75 -d 192.168.10.2 -p tcp --dport ssh -j ACCEPT 

iptables -t nat -A PREROUTING -s 193.136.212.1 -d 87.248.214.97 -p tcp --dport ssh -j DNAT --to-destination 192.168.10.2
iptables -A FORWARD -s 193.136.212.1 -d 192.168.10.2 -p tcp --dport ssh -j ACCEPT 

iptables -A FORWARD -s 192.168.10.2 -p tcp --sport ssh -j ACCEPT
#(O joão já deve ter algo do gênero)
#(retorno da ligação)

### Firewall configuration for communications from the internal network to the outside (using NAT) SNAT
#1. Domain name resolutions using DNS
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p udp --dport domain -d 193.136.212.1 -j SNAT --to-source 87.248.214.97
#(Ainda tenho que rever este FORWARD)
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport domain -o enp0s3 -j ACCEPT

#2. HTTP, HTTPS and SSH connections
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport ssh -j SNAT --to-source 87.248.214.97
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport http -j SNAT --to-source 87.248.214.97
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport https -j SNAT --to-source 87.248.214.97
#(Tenho que rever estes FORWARDS)
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport ssh -o enp0s3 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport http -o enp0s3 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport https -o enp0s3 -j ACCEPT

#3. FTP connections (in passive and active modes) to external FTP servers
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport 21 -j SNAT --to-source 87.248.214.97
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 21 -m state --state NEW -j ACCEPT #(será que nesta regra preciso da output interface -o enp0s3??)

#Active
iptables -t nat -A PREROUTING -d 87.248.214.97 -m state ESTABLISHED, RELATED -p tcp --sport 20 -j DNAT --to-destination 192.168.10.0/24
#(Forward em falta)

#Passive (não sei o porto)
iptables -t nat -A PREROUTING -d 87.248.214.97 -m state ESTABLISHED, RELATED -p tcp -j DNAT --to destination 192.168.10.0/24
#(Forward em falta)

#modprobe ip_conntrack_ftp
#-> Provavelmente serão estes os dois módulos de que iremos precisar para o connection tracking
#Temos que adicionar esta linha no ficheiro iptables-config file:
#IPTABLES_MODULES="ip_nat_ftp ip_conntrack_ftp"
