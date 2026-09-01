# Sesión 2: Automatización y Persistencia de Infraestructura

## 1. Contexto de la Sesión
En esta sesión hemos pasado de un despliegue manual y volátil (donde los cambios se perdían al apagar la máquina) a un modelo de **Infraestructura como Código (IaC)**. El objetivo principal ha sido lograr que el servidor se autoconfigure de forma consistente al desplegarse.

## 2. Problemas Identificados
* **Volatilidad:** Los cambios realizados manualmente dentro de la MV (instalación de paquetes, configuración de servicios) no persistían si la máquina se recreaba o destruía (`vagrant destroy`).
* **Dependencia Manual:** La necesidad de configurar el servidor "a dedo" cada vez que iniciábamos el entorno.

## 3. Soluciones Implementadas

### A. Automatización con Provisioning
Hemos modificado el archivo `Vagrantfile` para incluir un bloque de aprovisionamiento (`provision`). Esto permite ejecutar comandos de forma automática durante el proceso de arranque (`vagrant up` o `vagrant provision`).


1. Para que no tenga que volver a instalar nginx cuando vuelva a crear la VM, se usa `provisioners` en el Vagrantfile. Pondremos:
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