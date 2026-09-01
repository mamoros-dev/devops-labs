# Sesión 09: Diagnóstico de Red Externa

+ Hasta ahora hemos mirado dentro del servidor (htop, ss, logs). Pero, ¿qué pasa si el servidor está perfecto, el puerto 80 está abierto, pero el cliente sigue sin ver la web?

+ Aquí entran las herramientas de "sonda". Vamos a usarlas desde dentro de tu servidor para ver cómo ve él el mundo.

## 1. El comando curl (Tu navegador en texto)
+ Un SysAdmin no abre Chrome dentro del servidor. Usa curl. Sirve para pedir una web y ver qué responde el servidor de destino.
`curl -I http://localhost`
> -I (letra i mayúscula): Significa "solo las cabeceras" (Headers).  
> ¿Qué buscamos? El código HTTP/1.1 200 OK. Si sale eso, la web funciona internamente.  
```
vagrant@ubuntu-focal:~$ curl -I http://localhost
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Fri, 27 Mar 2026 16:08:08 GMT
Content-Type: text/html
Content-Length: 41
Last-Modified: Fri, 27 Mar 2026 13:13:57 GMT
Connection: keep-alive
ETag: "69c68295-29"
Accept-Ranges: bytes
```

# 2. El comando ping (¿Estás vivo?)
+ Es la herramienta más básica. Envía un paquete pequeño y espera a que vuelva.
`ping -c 4 google.com`  
> Si responde: Tienes salida a internet y el DNS funciona.  
> Si dice Temporary failure in name resolution: Tu servidor está "ciego", no sabe traducir nombres a IPs (falla el puerto 53 que vimos antes).  
```
vagrant@ubuntu-focal:~$ ping -c 4 google.com
PING google.com (142.250.180.14) 56(84) bytes of data.
64 bytes from ncamsa-ai-in-f14.1e100.net (142.250.180.14): icmp_seq=1 ttl=255 time=31.0 ms
64 bytes from ncamsa-ai-in-f14.1e100.net (142.250.180.14): icmp_seq=2 ttl=255 time=31.1 ms
64 bytes from ncamsa-ai-in-f14.1e100.net (142.250.180.14): icmp_seq=3 ttl=255 time=30.9 ms
64 bytes from ncamsa-ai-in-f14.1e100.net (142.250.180.14): icmp_seq=4 ttl=255 time=30.7 ms

--- google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 30.670/30.917/31.130/0.164 ms
```

# 3. El comando dig (El traductor de IPs)
+ Si el ping a Google falla, usamos dig para preguntar directamente a los servidores de nombres.
`dig google.com`  
> Busca la sección "ANSWER SECTION". Ahí verás la IP real de Google. Si esto funciona pero el ping no, es que tienes un bloqueo de firewall.
```
vagrant@ubuntu-focal:~$ dig google.com

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51076
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             26      IN      A       142.250.180.14

;; Query time: 0 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Mar 27 16:11:47 UTC 2026
;; MSG SIZE  rcvd: 55
```  

# 🛠️ Ejercicio de "Detective de Red"
+ Vamos a simular un problema real. Imagina que tu jefe te dice: "Miguel, el servidor no puede descargar las actualizaciones de Ubuntu".

1. Prueba de vida: ping -c 3 8.8.8.8 (Es el DNS de Google, si esto falla, no tienes internet).  
```
vagrant@ubuntu-focal:~$ ping -c 3 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=255 time=30.9 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=255 time=30.8 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=255 time=31.3 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 30.756/30.973/31.256/0.209 ms
```
2. Prueba de DNS: dig ubuntu.com (Mira si te da una IP en la "Answer Section").  
```
vagrant@ubuntu-focal:~$ dig ubuntu.com

; <<>> DiG 9.18.30-0ubuntu0.20.04.2-Ubuntu <<>> ubuntu.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 47215
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;ubuntu.com.                    IN      A

;; ANSWER SECTION:
ubuntu.com.             19      IN      A       185.125.190.20
ubuntu.com.             19      IN      A       185.125.190.21
ubuntu.com.             19      IN      A       185.125.190.29

;; Query time: 39 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Mar 27 16:14:31 UTC 2026
;; MSG SIZE  rcvd: 87
```
3. Prueba de Web Externa: curl -I https://www.google.com (Mira si te devuelve un código 200 o un 301/302 de redirección).  
```
vagrant@ubuntu-focal:~$ curl -I https://www.google.com
HTTP/2 200 
content-type: text/html; charset=ISO-8859-1
content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce-CvfK7wbjUDUGE04IIr5y8A' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
reporting-endpoints: default="//www.google.com/httpservice/retry/jserror?ei=7azGaZ_bAZ7R1sQPucukqQY&cad=crash&error=Page%20Crash&jsel=1&bver=2410&dpf=iszTDyCXc26qH5p_X-yDkrKyxWqPaNMOnksu66tvzM4"
accept-ch: Sec-CH-Prefers-Color-Scheme
p3p: CP="This is not a P3P policy! See g.co/p3phelp for more info."
date: Fri, 27 Mar 2026 16:14:37 GMT
server: gws
x-xss-protection: 0
x-frame-options: SAMEORIGIN
expires: Fri, 27 Mar 2026 16:14:37 GMT
cache-control: private
set-cookie: AEC=AaJma5tMlpGrcde4Wk46UifhOvodbRhw38Endr1jF8TAu_ZH_83xIx97I_8; expires=Wed, 23-Sep-2026 16:14:37 GMT; path=/; domain=.google.com; Secure; HttpOnly; SameSite=lax
set-cookie: __Secure-ENID=32.SE=eKT9Z1wP4PjQH39PH9LowygNzKkVG5RqcBH0ycxY7Sj645PAGmmkP39ibuftB6RXgSwOYAd5expJvpMCFMSAYX64LpSMn8iBzjSW-3n2bMuwq93dLlItiqWXaw6-p_EFr5fo57ZWWu7Lu_6sB3u92yFzkwmHxptS1Djd0DN1o33uVTIR1VT9aTWiCeoX3a3MWDUTlXQUjmqN4VeCkAZ0exkVfoC1KQlNwpQgsZXjJ7Jm1gBI3044Qhtewnsu1Uhw5JNh; expires=Tue, 27-Apr-2027 08:32:55 GMT; path=/; domain=.google.com; Secure; HttpOnly; SameSite=lax
set-cookie: __Secure-BUCKET=CO4E; expires=Wed, 23-Sep-2026 16:14:37 GMT; path=/; domain=.google.com; Secure; HttpOnly
alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000

vagrant@ubuntu-focal:~$
```
+ Resultados:  
1. El nivel físico/conectividad básica (ping) `Comando: ping -c 3 8.8.8.8`
- ¿Qué ha pasado? Has enviado 3 paquetes de "eco" directamente a una IP de Google (8.8.8.8).
- El resultado: 0% packet loss.
- ¿Qué significa? Tu servidor tiene "cable". Los paquetes salen a internet y vuelven sin perderse. Si esto fallara, no serviría de nada probar lo demás; el servidor estaría aislado del mundo.

2. El nivel de traducción/DNS (dig) `Comando: dig ubuntu.com`  
- ¿Qué ha pasado? Le has preguntado a tu servidor de nombres: "¿En qué dirección vive ubuntu.com?".
- El resultado: Te ha respondido con 3 direcciones IP (185.125.190.20, etc.) en la ANSWER SECTION.
- ¿Qué significa? Tu servidor no está ciego. Sabe traducir nombres de dominio a números IP. Es vital para poder descargar actualizaciones o conectar con otros servicios usando sus nombres. El tiempo de respuesta fue de 39 msec, lo cual es muy rápido.

3. El nivel de aplicación/Web (curl) `Comando: curl -I [https://www.google.com](https://www.google.com)`  
- ¿Qué ha pasado? Has simulado ser un navegador web. Has ido a la puerta de Google y has dicho: "No quiero ver tu web, solo enséñame tu identificación (cabeceras)".
- El resultado: HTTP/2 200.
- ¿Qué significa? Tu servidor puede establecer conexiones seguras (HTTPS/Puerto 443). El protocolo HTTP/2 funciona. Google te ha respondido con un 200 (OK), lo que confirma que el camino de ida y vuelta para datos web está totalmente despejado.