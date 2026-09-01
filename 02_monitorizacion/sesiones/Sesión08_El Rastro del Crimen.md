# Sesión 08: El Rastro del Crimen

+ El comando tail sirve para ver el "rabo" (el final) de un archivo. Pero con el parámetro -f (follow), la terminal se queda abierta y "enganchada" al archivo. Si alguien escribe una línea nueva, aparece en tu pantalla al instante.

+ Resultados:
```
vagrant@ubuntu-focal:~$ sudo tail -f /var/log/nginx/access.log
> localhost:8080
10.0.2.2 - - [27/Mar/2026:15:32:04 +0000] "GET / HTTP/1.1" 200 71 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
10.0.2.2 - - [27/Mar/2026:15:32:05 +0000] "GET /favicon.ico HTTP/1.1" 404 197 "http://localhost:8080/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
> http://192.168.56.1:8080/
192.168.56.1 - - [27/Mar/2026:15:34:34 +0000] "GET / HTTP/1.1" 200 71 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
192.168.56.1 - - [27/Mar/2026:15:34:34 +0000] "GET /favicon.ico HTTP/1.1" 404 197 "http://192.168.56.10/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
> http://miguel-dev.local:80
192.168.56.1 - - [27/Mar/2026:15:37:04 +0000] "GET /favicon.ico HTTP/1.1" 404 197 "http://miguel-dev.local/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
```
> Puerto 8080: Es un mapeo externo (Windows). Solo funciona con localhost.
> Puerto 80: Es el puerto real del servicio (Nginx). Funciona con la IP directa de la máquina.
> Moraleja: Si estás en una empresa y te dicen "la IP del servidor es la .10", nunca uses el 8080, ve directo al 80. El 8080 es solo un "truco" de Vagrant para cuando no tenemos red privada configurada.