# Sesión 5: Service Discovery (DNS Local)

+ ¿Qué es esto y para qué sirve?  
Actualmente, para entrar a tu servidor escribes ssh vagrant@192.168.56.10.  
Pero en entornos reales, nadie se aprende las IPs de memoria. Usamos nombres (como web.empresa.local).

+ Vamos a engañar a tu ordenador (Windows) para que, cuando escribas miguel-dev.local, él sepa que tiene que ir a la 192.168.56.10.

🌐 HITO: Configuración de DNS Local
1. Modifica el archivo "Hosts" de Windows
El archivo hosts es el "mapa" de nombres de tu sistema operativo. 
Si tú le dices que una IP tiene un nombre, el sistema te creerá a ciegas antes de preguntar a cualquier servidor DNS en Internet.
```
Busca en el menú de inicio de Windows: Bloc de notas (Notepad).
Haz clic derecho y selecciona "Ejecutar como administrador" (esto es vital, si no, no te dejará guardar).
En el bloc de notas, ve a Archivo -> Abrir.
Pega esta ruta en la barra de direcciones y pulsa Enter: C:\Windows\System32\drivers\etc
Cambia el filtro de abajo a la derecha de "Documentos de texto (.txt)" a **"Todos los archivos (.*)"**.
Abre el archivo llamado hosts.
```

Al final del archivo, añade esta línea:
```
192.168.56.10   miguel-dev.local
```
Guarda los cambios (Ctrl + S).

### 🧪 LA PRUEBA FINAL
Ahora, abre una terminal de PowerShell (da igual donde estés) y prueba esto:
Hazle un ping al nombre:
```
ping miguel-dev.local
```
(Si responde desde la 192.168.56.10, ¡el DNS local funciona!)

2. Entra por SSH usando el nombre:

PowerShell
ssh vagrant@miguel-dev.local
💡 ¿Por qué hacemos esto? (Visión DevOps)
Esto se llama "Service Discovery". En entornos de Kubernetes o Docker Swarm, los servicios se encuentran unos a otros mediante nombres, no IPs. 
Si mañana mueves el servidor a otra IP, solo tienes que actualizar este "archivo de mapa" en un sitio centralizado, y todo tu sistema volverá a hablarse sin cambiar una sola línea de código.

+ Resultados:
- PING:
```
C:\Users\migue>ping miguel-dev.local
Haciendo ping a miguel-dev.local [192.168.56.10] con 32 bytes de datos:
Respuesta desde 192.168.56.10: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.56.10: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.56.10: bytes=32 tiempo<1m TTL=64
Respuesta desde 192.168.56.10: bytes=32 tiempo<1m TTL=64

Estadísticas de ping para 192.168.56.10:
    Paquetes: enviados = 4, recibidos = 4, perdidos = 0
    (0% perdidos),
Tiempos aproximados de ida y vuelta en milisegundos:
    Mínimo = 0ms, Máximo = 0ms, Media = 0ms
```

- VAGRANT SSH:
```
$ ssh vagrant@miguel-dev.local
The authenticity of host 'miguel-dev.local (192.168.56.10)' can't be established.
ED25519 key fingerprint is SHA256:uzSlA3eRTAdZbUkQVz9+yLfJtPfXx1O4f156SywQMDA.
This host key is known by the following other names/addresses:
    ~/.ssh/known_hosts:1: 192.168.56.10
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'miguel-dev.local' (ED25519) to the list of known hosts.
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-172-generic x86_64)

Last login: Wed Mar 11 22:31:10 2026 from 192.168.56.1
```