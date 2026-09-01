# Networking Estático y Redes Privadas

1. Hoy vamos a dejar de usar la red "por defecto" (donde VirtualBox asigna lo que quiere) y vamos a configurar una Red Privada con IP Estática. Esto es lo que te permite conectar varios servidores entre sí en una red propia, como si fuera el rack de un centro de datos.  

2. En el vagrantfile añadimos esta linea para poner una ip estática:
```
# Red privada con IP estática
config.vm.network "private_network", ip: "192.168.56.10"
```

3. Hacemos un `vagrant reload` para reiniciar la máquina y cargue la nueva configuración.  

4. Si ahora entramos a la máquina, comprobamos que tenemos una interface con esa ip:  
```
Last login: Sun Mar  8 19:40:52 2026 from 10.0.2.2
vagrant@ubuntu-focal:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 02:83:8d:8f:42:16 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 86333sec preferred_lft 86333sec
    inet6 fd17:625c:f037:2:83:8dff:fe8f:4216/64 scope global dynamic mngtmpaddr noprefixroute
       valid_lft 86335sec preferred_lft 14335sec
    inet6 fe80::83:8dff:fe8f:4216/64 scope link
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:df:04:79 brd ff:ff:ff:ff:ff:ff
    inet 192.168.56.10/24 brd 192.168.56.255 scope global enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fedf:479/64 scope link
       valid_lft forever preferred_lft forever
```

+ Explicaciones:
```
lo (Loopback): Es tu "auto-diálogo". Es la dirección 127.0.0.1. Todo servidor necesita hablar consigo mismo para que sus servicios internos se comuniquen. Es como tu sistema nervioso interno.

enp0s3 (El puente al Mundo Exterior / NAT): Esta es la interfaz que te da acceso a Internet. Es el equivalente a que tu servidor estuviera conectado a un Router de casa. Tiene una IP 10.0.2.15 y a través de ella sales fuera para descargar Nginx, hacer apt update, etc.

enp0s8 (Tu Red Privada / El cable directo): Esta es la interfaz 192.168.56.10. Al definirla como private_network, VirtualBox crea un conmutador virtual (switch) interno. Es como si hubieras sacado un cable de red de tu portátil y lo hubieras pinchado directamente en la tarjeta de red de tu servidor.

¿Por qué funciona el Ping? Porque tu Windows también tiene una interfaz virtual de red (creada por VirtualBox) que "vive" en ese mismo rango 192.168.56.x. Al hacer ping, los paquetes viajan por ese "cable" privado sin pasar por el Router, sin pasar por Internet y sin que nadie fuera de tu PC pueda interceptarlos.
```

+ Diferencia entre `vagrant reload` y `vagrant provisioner`:  
    - vagrant reload (Reinicio total): Es como tirar abajo una pared y reconstruirla o apagar y encender el cuadro eléctrico de toda la casa. Vagrant detiene la máquina, vuelve a leer el Vagrantfile, aplica cambios estructurales (como cambiar el tamaño de la RAM, añadir un nuevo disco o, en nuestro caso, cambiar la configuración de red) y vuelve a arrancar el sistema operativo desde cero.  

    > Úsalo cuando: Modificas la red (private_network), cambias el nombre de la máquina o recursos de hardware.

    - vagrant provision (Actualización en caliente): Es como cambiar la decoración o instalar una estantería nueva sin tener que tirar abajo la casa. La máquina ya está encendida y funcionando. Vagrant simplemente ejecuta los scripts de configuración (shell, ansible, etc.) que definiste en tu Vagrantfile.  

    > Úsalo cuando: Modificas el script de instalación de Nginx, cambias tu archivo index.html o añades paquetes nuevos. No reinicia la máquina, lo cual es mucho más rápido.