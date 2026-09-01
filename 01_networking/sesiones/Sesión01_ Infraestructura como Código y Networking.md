# 03 - Sesión 1: Infraestructura como Código y Networking

Como estamos en casos-reales/networking, vamos a tratar este primer ejercicio como un Caso de Redes.

🛠️ Paso a paso: Ejecución del Laboratorio
Para que no ensuciemos la raíz de tu repositorio, haz esto en tu terminal (PowerShell) ahora mismo:

1. Entra en la carpeta de networking:

```
cd casos-reales/networking
```

2. Crea una subcarpeta para el primer caso:

```
mkdir caso-01-analisis-ip
cd caso-01-analisis-ip
```
3. Inicia y levanta la infraestructura:

```
vagrant init ubuntu/focal64
vagrant up
```
> Si da fallo de que no encuentra provider, es que falta descargar [Virtualbox](https://www.virtualbox.org/wiki/Downloads) o asignarle un provider.

> Para ello descargamos Virtualbox en la web o, si lo tenemos, podemos probar con `vagrant up --provider=virtualbox`

4. Entra al servidor y danos el primer dato:
```
vagrant ssh
ip a
```

5. Resultado:
```
Last login: Wed Mar  4 16:36:22 2026 from 10.0.2.2
vagrant@ubuntu-focal:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 02:1a:a2:1e:9d:b7 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 metric 100 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 85408sec preferred_lft 85408sec
    inet6 fd17:625c:f037:2:1a:a2ff:fe1e:9db7/64 scope global dynamic mngtmpaddr noprefixroute
       valid_lft 86192sec preferred_lft 14192sec
    inet6 fe80::1a:a2ff:fe1e:9db7/64 scope link
       valid_lft forever preferred_lft forever
vagrant@ubuntu-focal:~$
```

6. Explicación del resultado:
```
Vamos a diseccionar tu red para que entiendas qué estás administrando:

1. La Interfaz lo (Loopback) - El "Yo" del servidor
IP: 127.0.0.1/8

Para qué sirve: Es la dirección interna. Si un servicio (como una base de datos) falla, lo primero que haces es un ping 127.0.0.1. Si eso no responde, el problema no es la red, es el Kernel de Linux que está frito.

2. La Interfaz enp0s3 - Tu puerta al mundo (NAT)
Aquí es donde está la acción. En Ubuntu moderno (focal), ya no se llaman eth0, sino que usan nombres basados en el hardware (enp0s3).

IP: 10.0.2.15/24

Máscara /24: Esto significa que tu red tiene 254 IPs disponibles (desde la .1 hasta la .254). El /24 equivale a la clásica máscara 255.255.255.0.

MAC Address: 02:1a:a2:1e:9d:b7. Esta es la "matrícula" física de tu tarjeta de red virtual. Si en un switch físico filtras por seguridad, esta es la dirección que tendrías que autorizar.
```

7. Redirección de puertos (port forwarding)
```
El Problema Real: Tienes el servidor encendido, pero está "escondido" dentro de VirtualBox. Si instalamos un servidor web (Nginx) ahora mismo, no podrías verlo desde el navegador de tu Windows.

En una empresa, esto se soluciona con NAT o VLANs. En nuestro laboratorio, vamos a modificar el código (Vagrantfile) para abrir un túnel.

Tu reto ahora:

Sal del servidor escribiendo: exit (volverás a tu PowerShell de Windows).

Abre el archivo Vagrantfile que tienes en esa carpeta con el Bloc de Notas o VS Code.

Busca la línea que está comentada (tiene un #) y dice algo parecido a:
config.vm.network "forwarded_port", guest: 80, host: 8080

Quítale el # (descoméntala) para que quede activa.

Guarda el archivo.
```

8. En la terminal, aplica los cambios sin apagar la máquina:
```
vagrant reload
```

9. El vagrant reload realiza:
```
    default: Guest Additions Version: 6.1.50
    default: VirtualBox Version: 7.2
==> default: Mounting shared folders...
    default: C:/Users/MIGUEL_AMOROS/Documents/GITHUB/mamoros-dev.github.io/casos-reales/networking/caso-01_analisis-ip => /vagrant
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
PS C:\Users\MIGUEL_AMOROS\Documents\GITHUB\mamoros-dev.github.io\casos-reales\networking\caso-01_analisis-ip> 

El vagrant reload ha funcionado. Fíjate en una cosa de experto en tu salida: Mounting shared folders....

Vagrant acaba de crear un túnel entre tu carpeta de Windows y la carpeta /vagrant dentro de Linux. Cualquier archivo que pongas en tu PC aparecerá mágicamente en el servidor. ¡Eso es sincronización de entornos!
```

10. Instalar Servidor Web (nginx)
```
Nginx es el estándar para servir aplicaciones.

Entra de nuevo al servidor:
---
vagrant ssh
---

Actualiza los repositorios e instala Nginx: (Como somos administradores, usamos sudo).
---
sudo apt update
sudo apt install nginx -y
---

Verifica que el servicio está corriendo:
---
systemctl status nginx
---
```

11. Para que no tenga que volver a instalar nginx cuando vuelva a crear la VM, se usa `provisioners` en el Vagrantfile. Pondremos:
```
config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    # Copiamos tu archivo de la carpeta compartida al servidor web automáticamente
    cp /vagrant/index.html /var/www/html/index.html
  SHELL
```
> Después pondremos `vagrant provision` para que cargue esa nueva configuración.  

> La carpeta /vagrant se crea dentro de la MV y coge lo conectado con la máquina host donde tenemos creado nuestro Vagrantfile. Si en esta ruta creamos un `index.html` con `<h1>Hola! Este es mi servidor DevOps</h1>` veremos que en `localhost:8080` nos saldrá esta web en nuestro nginx.  