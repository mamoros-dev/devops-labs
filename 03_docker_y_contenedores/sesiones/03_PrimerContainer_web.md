# PRIMER IMAGEN CON DOCKERFILE

+ Primeros pasos:
```
vagrant@ubuntu-focal:~$ echo "<h1>Hola Miguel, esta es mi imagen de Docker personalizada en 2026</h1>" > index.html
vagrant@ubuntu-focal:~$ cat <<EOF > Dockerfile
> # Paso 1: Usar la imagen oficial de Nginx como base
> FROM nginx:alpine
>
> # Paso 2: Copiar nuestra web dentro de la ruta por defecto de Nginx
> COPY index.html /usr/share/nginx/html/index.html
> EOF
```  
+ Contruimos: `vagrant@ubuntu-focal:~/imagenes/mi-web$ docker build -t mi-primera-web:v1 .`  
```
¿Qué significa este comando técnicamente?

docker build: Le dice al motor que compile un Dockerfile.
-t mi-primera-web:v1: Es el tag o la etiqueta. Le das un nombre a tu creación (mi-primera-web) y una versión (v1).
. (El punto): Define el contexto de construcción. Le dice a Docker: "Busca el Dockerfile y los archivos que necesitas en esta carpeta actual".
```  

+ Imagen creada:
```
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker images
REPOSITORY       TAG       IMAGE ID       CREATED         SIZE
mi-primera-web   v1        092310d80a4c   2 minutes ago   62.3MB
```

+ Montamos el contenedor con mi página web personalizada:
```
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker run -d --name servidor-miguel -p 80:80 mi-primera-web:v1
fa66ef983056c8ba5abeab61d865d79e486352a3a6165230dce1bab5b9c14070
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS         PORTS                                     NAMES
fa66ef983056   mi-primera-web:v1   "/docker-entrypoint.…"   4 seconds ago   Up 3 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   servidor-miguel

## Repaso técnico instantáneo de los flags:
-d: Corre en segundo plano (Detached). No te secuestra la terminal.
--name servidor-miguel: El nombre de esta instancia.
-p 8080:80: Mapea el puerto 8080 de tu Ubuntu al puerto 80 interno del contenedor (donde Nginx escucha).
mi-primera-web:v1: Tu receta personalizada.
```

+ Comprobamos resultados:
```
Dentro de la MV
vagrant@ubuntu-focal:~/imagenes/mi-web$ curl http://localhost:8080
<h1>Hola Miguel, esta es mi imagen de Docker personalizada en 2026</h1>

Fuera de la MV
http://localhost:8080/
```
> Todo esto funciona porque tenemos el mapeo de mi windoes 8080 al 80 de la MV de ubuntu. Luego el docker escucha de ese 80 de la MV de ubuntu con el 80 del docker.  
```
# WINDOWS
cat Vagrantfile | grep forwarded_port
> Nos enseñó la línea real de configuración: host: 8080, guest: 80. Ahí descubrimos que Windows recogía el tráfico en el 8080 pero lo escupía obligatoriamente en el 80 de la máquina virtual.

# MV UBUNTU
sudo ss -tulnp | grep :8080
> Al principio nos salía que el dueño del puerto 8080 era docker-proxy. Gracias a eso nos dimos cuenta de que Docker se había adueñado del 8080 de Ubuntu, mientras que el tráfico de Vagrant estaba llegando al puerto 80 vacío.

# DOCKER
docker ps
> Miramos la columna PORTS. Al principio ponía 0.0.0.0:8080->80/tcp (Docker escuchaba en el 8080 de Ubuntu). Al corregirlo, cambió a 0.0.0.0:80->80/tcp (Docker escuchando en el 80 de Ubuntu, haciendo match perfecto con Vagrant).
```