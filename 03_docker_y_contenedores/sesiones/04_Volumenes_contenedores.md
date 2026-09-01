# 🧠 Persistencia de Datos: Volúmenes vs Bind Mounts
+ En el mundo real y en la nube (AWS, Kubernetes), los contenedores se destruyen y se recrean continuamente (para actualizar el código, por fallos, para escalar). Si el contenedor muere, todo lo que hay dentro se borra.

+ Para que los datos sobrevivan (como los usuarios de tu base de datos o los archivos que suben los clientes), Docker separa el proceso del almacenamiento.

+ Hay dos formas de hacerlo y cada una tiene su caso de uso real en empresas:
    + Bind Mount:
        - Apuntar a una carpeta exacta de tu máquina (ej: /home/vagrant/app).
        - Tú manejas la carpeta y los permisos desde fuera.
        - Entornos de Desarrollo. Modificas el código en tu editor y el contenedor lo ve en vivo.

    + Volume:
        - El estándar de producción.
        - Docker crea y gestiona una carpeta oculta dentro de su propio sistema.
        - Docker gestiona los permisos, la seguridad y el rendimiento.
        - Producción / Bases de Datos. Para guardar datos de MySQL, PostgreSQL, etc., en AWS de forma segura y rápida.

## 🛠️ Caso Real: Montar una Base de Datos con persistencia (Volumen)
+ Imagínate que estás en tu futuro trabajo y te piden desplegar una base de datos PostgreSQL para la aplicación de la empresa. No puedes arriesgarte a que si el contenedor se reinicia, se borren los datos. Usaremos un Volumen de Docker.

+ Creamos un volumen de producción:
```
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker volume create mi-base-datos-prod
mi-base-datos-prod
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker volume ls
DRIVER    VOLUME NAME
local     mi-base-datos-prod
```

+ Creamos un contenedor con postgresql indicando que los datos que guarda dentro, los guarde también al volumen docker creados:
`vagrant@ubuntu-focal:~/imagenes/mi-web$ docker run -d --name mi-postgres -p 5432:5432 -e POSTGRES_PASSWORD=miguel123 -v mi-base-datos-prod:/var/lib/postgresql postgres:alpine`  
```
1. docker run -d --name mi-postgres
-d (Detached): Corre el contenedor en segundo plano. Si no lo pones, la base de datos se adueña de tu terminal, empieza a escupir logs de sistema y, en cuanto cierres la consola, la base de datos se apaga.
--name mi-postgres: Le asigna un nombre amigable a la instancia para que cuando hagas docker ps o quieras borrarlo, no tengas que andar copiando el ID alfanumérico raro que Docker genera por defecto.

2. -p 5432:5432 (Los Puertos)
Aquí aplicamos exactamente la misma lógica que descubrimos antes con Nginx, pero adaptada a bases de datos:
El 5432 de la derecha: Es el puerto interno del contenedor. El software de PostgreSQL, por defecto de fábrica, viene programado para escuchar e intercambiar datos en el puerto 5432.
El 5432 de la izquierda: Es el puerto que abres en tu MV Ubuntu.
💡 Conexión con tu objetivo (AWS): Cuando estés en Amazon AWS, si una aplicación web quiere guardar datos en este PostgreSQL, apuntará al puerto 5432 de esta máquina.

3. -e POSTGRES_PASSWORD=miguel123 (Variables de Entorno)
El flag -e significa Environment Variable (Variable de Entorno). Es la forma que tenemos en DevOps de pasarle configuraciones o credenciales a un contenedor sin tener que entrar en él a editar archivos.
¿Por qué es obligatorio aquí? La imagen oficial de PostgreSQL está programada con una medida de seguridad: si intentas arrancarla sin definir una contraseña para el usuario administrador, el contenedor se apaga inmediatamente por seguridad para evitar bases de datos expuestas en internet sin clave.
Al poner POSTGRES_PASSWORD=miguel123, el proceso de arranque lee esa variable y configura automáticamente el usuario postgres con esa contraseña.

4. -v mi-base-datos-prod:/var/lib/postgresql (El Volumen de Producción)
Este es el núcleo de la clase de hoy. Como vimos, la izquierda y la derecha de los dos puntos se conectan entre sí:
/var/lib/postgresql/data (Derecha): Es la ruta oficial e interna donde PostgreSQL guarda físicamente los archivos binarios de las bases de datos, las tablas y los registros de los usuarios. Todo lo que se guarda, va ahí dentro.
mi-base-datos-prod (Izquierda): Es el volumen seguro que creamos en el paso anterior. Vive en una carpeta gestionada por Docker en el disco de tu Ubuntu, protegida de borrados accidentales.
🎯 El porqué de esto: Al unirlos, le estás diciendo al contenedor: "Cada vez que un cliente inserte un dato y se escriba en tu carpeta interna, mándalo en tiempo real a mi volumen exterior".

5. postgres:alpine (La Imagen)
postgres: Descarga la imagen oficial de la base de datos.
:alpine: Esta es una etiqueta (tag) clave en el mundo profesional. Alpine es una distribución de Linux extremadamente ligera (pesa apenas 5 MB). En las empresas se usa alpine siempre que se puede porque reduce el tamaño de las imágenes, se descargan más rápido en la nube y, al tener menos herramientas instaladas, es mucho más segura contra vulnerabilidades de Hackers.
```

+ Resultado:
```
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                      
   NAMES
0e6723413896   postgres:alpine   "docker-entrypoint.s…"   4 seconds ago    Up 2 seconds    0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp   mi-postgres
```

+ Añadimos una entrada a la base de datos y miramos de eliminar el contenedor para resucitar otro y ver que la info sigue:
```
vagrant@ubuntu-focal:~/imagenes/mi-web$ docker exec -it mi-postgres sh -c "echo 'Datos ultra secretos de la empresa de Miguel' > /var/lib/postgresql/archivo_seguro.txt"

vagrant@ubuntu-focal:~/imagenes/mi-web$ docker rm mi-postgres 
mi-postgres

vagrant@ubuntu-focal:~/imagenes/mi-web$ docker run -d --name mi-postgres-resucitado -p 5432:5432 -e POSTGRES_PASSWORD=miguel123 -v mi-base-datos-prod:/var/lib/postgresql postgres:alpine
40b0f1ed5e4975375a606859c7e9763ee7f30959144b5cd477073c783f00e24a

vagrant@ubuntu-focal:~/imagenes/mi-web$ docker exec -it mi-postgres-resucitado cat /var/lib/postgresql/archivo_seguro.txt
Datos ultra secretos de la empresa de Miguel
```