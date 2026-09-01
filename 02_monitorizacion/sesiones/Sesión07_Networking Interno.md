# Networking Interno

+ Vamos a por la segunda herramienta de monitorización. Si htop es el pulso del corazón, ss es el radar de tráfico.
1. El concepto de "Socket"
Un servidor no es más que una máquina con "puertas" (puertos).
- Listening (Escuchando): El puerto está abierto esperando a que alguien llame (ej: Nginx en el 80).
- Established (Conectado): Alguien ha llamado y ahora hay un "tubo" de datos abierto entre su IP y la tuya.

2. El comando ss (Socket Statistics)
+ Antes se usaba netstat, pero ss es el sustituto moderno, mucho más rápido y preciso.  

+ Comando Clave: `sudo ss -tunlp`
```
-t: Muestra conexiones TCP (la mayoría: web, ssh).
-u: Muestra conexiones UDP (DNS, streaming).
-n: Muestra números (puertos) en lugar de nombres (ej: 80 en vez de "http").
-l: Muestra solo los puertos que están Listening (esperando).
-p: Te dice qué Proceso (programa) es el dueño de ese puerto (necesitas sudo).
```

+ Resultados:
```
vagrant@ubuntu-focal:~$ sudo ss -tunlp
Netid  State   Recv-Q  Send-Q      Local Address:Port     Peer Address:Port  Process                                                                           
udp    UNCONN  0       0           127.0.0.53%lo:53            0.0.0.0:*      users:(("systemd-resolve",pid=601,fd=12))
udp    UNCONN  0       0        10.0.2.15%enp0s3:68            0.0.0.0:*      users:(("systemd-network",pid=589,fd=22))
tcp    LISTEN  0       4096        127.0.0.53%lo:53            0.0.0.0:*      users:(("systemd-resolve",pid=601,fd=13))
tcp    LISTEN  0       128               0.0.0.0:22            0.0.0.0:*      users:(("sshd",pid=850,fd=3))
tcp    LISTEN  0       511               0.0.0.0:80            0.0.0.0:*      users:(("nginx",pid=3051,fd=6),("nginx",pid=3050,fd=6),("nginx",pid=3049,fd=6))  
tcp    LISTEN  0       128                  [::]:22               [::]:*      users:(("sshd",pid=850,fd=4))
tcp    LISTEN  0       511                  [::]:80               [::]:*      users:(("nginx",pid=3051,fd=7),("nginx",pid=3050,fd=7),("nginx",pid=3049,fd=7)) 
```

+ 🔍 Análisis del Radar de Red (ss)
1. Puerto 80 (Nginx):
> Ves que pone 0.0.0.0:80. El 0.0.0.0 significa que Nginx está escuchando peticiones de CUALQUIER sitio (tu red local, internet, la red interna de Vagrant).  
> Fíjate que aparecen 3 PIDs (3051, 3050, 3049). Nginx crea varios "trabajadores" (workers) para repartirse el trabajo. Es como tener 3 cajeros en un supermercado.  

2. Puerto 22 (SSH):
> El proceso sshd es el que te permite estar conectado ahora mismo. Si matas ese proceso (PID 850), ¡te quedarías fuera de la máquina al instante!

3. Puerto 53 (DNS):
> Ves systemd-resolve. Este es el encargado de que tu servidor sepa traducir "https://www.google.com/search?q=google.com" a una IP. Sin este pequeño proceso escuchando ahí, tu servidor estaría "ciego" en internet.

4. IPv6 ([::]:80 y [::]:22):
> Esos corchetes con dos puntos significan que tu servidor también está preparado para recibir visitas por el nuevo protocolo IPv6.

## Posible caso:
+ Te pasará mil veces: intentas arrancar Nginx (o cualquier otro servicio) y te escupe un error rojo: Address already in use o Port 80 is already bound.
+ Regla de Oro del SysAdmin: "Dos programas no pueden escuchar en el mismo puerto y la misma IP al mismo tiempo".

+ Flujo de resolución:
1. Detectar: sudo ss -tunlp | grep :[PUERTO]
2. Identificar: Mirar el nombre del proceso y su PID.
3. Ejecutar: Detener el proceso con systemctl stop o kill o configurar otro puerto.