# CASO REAL 04: "El Misterio del Servidor Lento"

+ Situación:  
Viernes, 17:00h. Recibes un aviso: "La web miguel-dev.local no carga para algunos usuarios y, cuando carga, va desesperadamente lenta".

+ Tu Tarea:  
Crea el archivo Caso04_Diagnostico.md dentro de la carpeta 01_networking/caso-04_diagnostico-total/ (o donde prefieras dentro de la Fase 2) y redacta tu Protocolo de Actuación.

## ✍️ Protocolo de Emergencia: Servidor Lento o Caído
**1. Revisión de Recursos (El "Cuerpo" del servidor)**
- Comando: htop
- Objetivo: Ver si la CPU está al 100% o si la RAM está llena (Swap alta).
- Acción: Si hay un proceso "comiéndose" el servidor, lo identifico y lo mato con F9 (SIGTERM o SIGKILL).

**2. Revisión de Puertos (La "Escucha")**
- Comando: sudo ss -tunlp
- Objetivo: Confirmar que Nginx (puerto 80) y SSH (puerto 22) están en estado LISTEN.
- Acción: Si el puerto 80 no aparece, intento reiniciar el servicio: sudo systemctl restart nginx.

**3. Revisión de Actividad (Los "Logs")**
- Comando: sudo tail -f /var/log/nginx/access.log
- Objetivo: Ver si están entrando visitas en tiempo real.
- Acción:
    + Si veo códigos 200: Todo está bien, el problema puede ser la red del cliente.
    + Si veo códigos 500: El servidor tiene un error interno (de código).
    + Si no aparece nada: El tráfico no está llegando al servidor (posible Firewall).

**4. Revisión de Salida (La "Vista" al exterior)**
- Comando: ping -c 3 8.8.8.8 y curl -I http://localhost
- Objetivo:
    + ping: Saber si el servidor tiene internet.
    + curl: Saber si la web funciona "por dentro".
- Acción: Si el curl interno funciona pero desde fuera no puedo entrar, el problema es el Firewall (UFW) o el redireccionamiento de puertos de Vagrant.