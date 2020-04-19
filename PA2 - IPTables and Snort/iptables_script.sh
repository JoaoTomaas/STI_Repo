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
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport smtp -d  23.214.219.131 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport smtp -s  23.214.219.131 -j ACCEPT

#5. POP and IMAP connections to the mail server
#(Ainda tenho que perceber se é suposto fazer entre a internet e o mail server ou se isso faz sentido)
#(Acho que basta fazer entre a rede interna e a DMZ, visto que esse é o propósito da DMZ)
#POP (O nome do service pop é pop2)
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport pop2 -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport pop2 -s 23.214.219.133 -j ACCEPT
#POP3 (confirmar se é preciso POP3 ou se basta POP)
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport pop3 -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport pop3 -s 23.214.219.133 -j ACCEPT
#IMAP
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport imap -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport imap -s 23.214.219.133 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport imap -d 23.214.219.133 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p udp --sport imap -s 23.214.219.133 -j ACCEPT

#6. HTTP and HTTPS connections to the www server
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport http -d 23.214.219.130 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport http -s 23.214.219.130 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport https -d 23.214.219.130 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport https -s 23.214.219.130 -j ACCEPT

#7. OpenVPN connections to the vpn-gw server. 
#openvpn -> 1194
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport openvpn -d 23.214.219.129 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport openvpn -s 23.214.219.129 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport openvpn -d 23.214.219.129 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p udp --sport openvpn -s 23.214.219.129 -j ACCEPT
#(Não sei se é necessário configurar alguma interface, tipo tun0)

#8. VPN clients connected to the gateway (vpn-gw) should able to connect to the PosgreSQL service on the datastore server.
#postgres -> 5432 (tcp e udp)
#Acho que nao preciso de pôr porto no endereço do vpn-gw, acho que basta o de destino que é o do postgres
iptables -A FORWARD -s 23.214.219.129 -p tcp --dport postgres -d 192.168.10.1 -j ACCEPT
iptables -A FORWARD -d 23.214.219.129 -p tcp --sport postgres -s 192.168.10.1 -j ACCEPT
iptables -A FORWARD -s 23.214.219.129 -p udp --dport postgres -d 192.168.10.1 -j ACCEPT
iptables -A FORWARD -d 23.214.219.129 -p udp --sport postgres -s 192.168.10.1 -j ACCEPT

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
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p udp --dport domain -j SNAT --to-source 87.248.214.97
#Nem no MIT fazem forwards tão bons
iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport domain -o enp0s10 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p udp --sport domain -i enp0s10 -j ACCEPT

#2. HTTP, HTTPS and SSH connections
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport ssh -j SNAT --to-source 87.248.214.97
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport http -j SNAT --to-source 87.248.214.97
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport https -j SNAT --to-source 87.248.214.97
#FORWARDS DE SAÍDA
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport ssh -o enp0s10 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport http -o enp0s10 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport https -o enp0s10 -j ACCEPT
#FORWARDS DE ENTRADA
iptables -A FORWARD -d 192.168.10.0/24 -p tcp ! --syn -j ACCEPT
#ou
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport ssh -i enp0s10 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport http -i enp0s10 -j ACCEPT
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport htttps -i enp0s10 -j ACCEPT

#3. FTP connections (in passive and active modes) to external FTP servers
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -p tcp --dport 21 -j SNAT --to-source 87.248.214.97
#FORWARD do Command Channel
iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 21 -m state --state NEW -o enp0s10 -j ACCEPT #(será que nesta regra preciso da output interface -o enp0s3??)

#ACTIVE do Data Channel
iptables -A FORWARD -d 192.168.10.0/24 -p tcp --sport 20 -m state --state RELATED, ESTABLISHED -i enp0s10 -j ACCEPT 

#PASSIVE do Data Channel


#Active
#iptables -t nat -A PREROUTING -d 87.248.214.97 -m state ESTABLISHED, RELATED -p tcp --sport 20 -j DNAT --to-destination 192.168.10.0/24
#(Forward em falta)
#Passive (não sei o porto)
#iptables -t nat -A PREROUTING -d 87.248.214.97 -m state ESTABLISHED, RELATED -p tcp -j DNAT --to destination 192.168.10.0/24
#(Forward em falta)

#Configuração dos módulos para o connection tracking do FTP
#modprobe ip_conntrack_ftp
#modprobe ip_nat_ftp
#Adicionar esta linha no ficheiro /etc/sysconfig/iptables-config: IPTABLES_MODULES="ip_nat_ftp ip_conntrack_ftp"
