# Sesión 11: Inspección y Gestión de Recursos
+ Antes de pasar a crear nuestras propias imágenes (Bloque 2), un profesional debe saber qué está pasando "bajo el capó" de esos contenedores.

1. El "Rayos X" (inspect)
+ Este comando te devuelve un JSON gigante con TODA la configuración técnica del contenedor (IP interna, rutas, variables, etc.).
```
docker inspect servidor-beta
```  
+ Busca la sección "NetworkSettings" para ver la IP interna que Docker le ha asignado al contenedor dentro de su propia red.
```
"NetworkSettings": {
            "Bridge": "",
            "SandboxID": "c326dcf274235861a47f35020c5fb546f0cf9a7f0469ebd9bc085dd7069c3b81",
            "SandboxKey": "/var/run/docker/netns/c326dcf27423",
            "Ports": {
                "80/tcp": [
                    {
                        "HostIp": "0.0.0.0",
                        "HostPort": "8082"
                    },
                    {
                        "HostIp": "::",
                        "HostPort": "8082"
                    }
                ]
            },
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "075e2516670961bff8396e5baba892764b2ead7c650520e163d2b934a7970c1b",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.3",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "16:20:ae:73:c1:58",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "16:20:ae:73:c1:58",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "a29c0ae960bcccb11fe1ad3fb05374480dcfec5edd64c956afcf7a774ada76b4",
                    "EndpointID": "075e2516670961bff8396e5baba892764b2ead7c650520e163d2b934a7970c1b",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.3",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        }
    }
]
```
> IPAddress": "172.17.0.3  

2. Monitorización en tiempo real (stats)
+ ¿Te acuerdas de htop? Docker tiene su propio "top" para contenedores.
```
docker stats servidor-beta
```  
+ Verás cuánta CPU y RAM está consumiendo exactamente ese contenedor. (Pulsa Ctrl+C para salir).
```
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O         PIDS 
e23e35033ec9   servidor-beta   0.00%     4.379MiB / 964.8MiB   0.45%     1.05kB / 126B   1.14MB / 8.19kB   3 
```
3. Los procesos internos (top)
+ Para ver qué procesos están corriendo dentro de ese contenedor específico:
```
docker top servidor-beta
```

```
vagrant@ubuntu-focal:~$ docker top servidor-beta 
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                8690                8664                0                   15:29               ?                   00:00:00            nginx: master process nginx -g daemon off;
systemd+            8761                8690                0                   15:29               ?                   00:00:00            nginx: worker process
systemd+            8762                8690                0                   15:29               ?                   00:00:00            nginx: worker process
vagrant@ubuntu-focal:~$ 
```

🛠️ Mini-Reto antes de cerrar por hoy
+ Ya que tienes el servidor-beta en el puerto 8082, intenta entrar de nuevo "dentro" para hacer un cambio manual y ver la magia de la inmutabilidad:

+ Entra al contenedor: docker exec -it servidor-beta bash
+ Modifica el mensaje de bienvenida (sin usar editores, solo con un comando):
```
echo "<h1>Hola Miguel, esto es Docker</h1>" > /usr/share/nginx/html/index.html
Sal del contenedor (exit).
```

+ Haz el curl -I o míralo en el navegador de Windows.
```
vagrant@ubuntu-focal:~$ docker exec -it servidor-beta bash
root@e23e35033ec9:/# echo "<h1>Hola Miguel, esto es Docker</h1>" > /usr/share/nginx/html/index.html
root@e23e35033ec9:/# exit
exit
vagrant@ubuntu-focal:~$ curl -i http://localhost:8082
HTTP/1.1 200 OK
Server: nginx/1.29.8
Date: Mon, 13 Apr 2026 15:55:56 GMT
Content-Type: text/html
Content-Length: 37
Last-Modified: Mon, 13 Apr 2026 15:54:59 GMT
Connection: keep-alive
ETag: "69dd11d3-25"
Accept-Ranges: bytes

<h1>Hola Miguel, esto es Docker</h1>
```