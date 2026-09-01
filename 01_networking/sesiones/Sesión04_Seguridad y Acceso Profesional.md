# SESIÓN 4: Seguridad y Acceso Profesional
Hoy vamos a trabajar dos pilares que te van a dar un aire de experto total:  
- El Firewall (UFW): Aprenderás a cerrar todas las puertas de tu servidor y abrir solo las que nosotros decidamos (Web y SSH).  
- SSH con Llaves (Key-based auth): Dejaremos de entrar con "usuario y contraseña" para usar llaves criptográficas. Es el estándar de la industria.  

### PASO 1: Configurando el Firewall (UFW)
En Ubuntu, el firewall por defecto es UFW (Uncomplicated Firewall). Vamos a configurarlo para que solo permita el tráfico que nos interesa.
```
# Entra en tu servidor:
vagrant ssh

# Mira el estado actual: (Verás que está inactivo).
sudo ufw status

# Configura las reglas (¡IMPORTANTE el orden!):
Primero permitimos SSH (puerto 22) para no quedarnos fuera, y luego el puerto web (80).
sudo ufw allow ssh
sudo ufw allow http

# Activa el Firewall:
sudo ufw enable
(Te preguntará si quieres continuar porque puede interrumpir la conexión SSH. Di que sí y, ya que hemos permitido el puerto ssh en el paso anterior).

# Comprueba de nuevo:
sudo ufw status numbered
```
+ Resultados:
```
vagrant@ubuntu-focal:~$ sudo ufw status numbered
Status: active
     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80/tcp                     ALLOW IN    Anywhere
[ 3] 22/tcp (v6)                ALLOW IN    Anywhere (v6)
[ 4] 80/tcp (v6)                ALLOW IN    Anywhere (v6)
```

#### 🧪 LA PRUEBA TÉCNICA
Ahora intenta entrar en http://192.168.56.10 (la IP estática que pusimos ayer) desde tu navegador en Windows. Deberías seguir viendo tu mensaje de "Hola UPCnet".  

Si intentaras entrar por cualquier otro puerto que no hayamos abierto, el servidor simplemente ignoraría la petición. Acabas de blindar tu nodo.

### 🔑 PASO 2: SSH con Llaves (Acceso Nivel Senior)
En la vida real, los administradores no ponen contraseñas en los servidores (porque son fáciles de hackear por fuerza bruta). Usamos un par de llaves criptográficas: una pública (que vive en el servidor) y una privada (que vive en tu ordenador).

Vamos a crear este vínculo entre tu Windows y tu Linux.

1. Genera tus llaves en Windows
Abre una NUEVA terminal de PowerShell (en tu Windows, fuera de la máquina virtual) y escribe:
```
PowerShell
ssh-keygen -t rsa -b 4096
```
Dale a Enter a todo (no le pongas frase de paso/passphrase por ahora para que sea automático).
Esto habrá creado dos archivos en C:\Users\TU_USUARIO\.ssh\: id_rsa (tu llave secreta) e id_rsa.pub (la que puedes compartir).

2. Saca tu "llave pública"
Todavía en tu PowerShell de Windows, muestra el contenido de tu llave pública:
```
PowerShell
cat ~/.ssh/id_rsa.pub
```
Copia todo ese texto (empieza por ssh-rsa y acaba con el nombre de tu PC).

3. Instálala en el Servidor (Linux)
Vuelve a la terminal donde tienes el vagrant ssh abierto. Tenemos que pegar esa llave en un archivo especial.
```
Crea la carpeta (si no existe): mkdir -p ~/.ssh

Abre el archivo de llaves autorizadas: nano ~/.ssh/authorized_keys

Pega tu código de Windows dentro.

Guarda y sal (Ctrl+O, Enter, Ctrl+X).

Dale permisos de seguridad: chmod 600 ~/.ssh/authorized_keys
```  

#### 🧪 LA PRUEBA DE FUEGO
Sal del servidor con exit. Ahora, en lugar de usar vagrant ssh, vamos a intentar entrar directamente por la red que creamos ayer usando la IP estática.

Desde tu PowerShell de Windows escribe:
```
PowerShell
ssh vagrant@192.168.56.10
```
Si entras directo sin que te pida nada, ¡felicidades! Has configurado tu primer túnel de acceso profesional. Esto es exactamente lo que harás cuando tengas que gestionar servidores en la nube (AWS/Azure) donde no existe el comando "vagrant ssh".

+ Resultados:
```
migue@DESKTOP-G47I0DM MINGW64 ~/Documents/mamoros-dev.github.io/casos-reales/networking/caso-01_analisis-ip (main)
$ ssh vagrant@192.168.56.10

Last login: Wed Mar 11 22:30:50 2026 from 10.0.2.2
```

+ Explicaciones:

1. ¿Por qué se han entendido Windows y Linux? (El apretón de manos)
```
La magia no es que se "entiendan" por ser amigos, sino por un protocolo llamado Criptografía de Clave Asimétrica.
- La Llave Pública (.pub): Es como un candado que dejaste abierto en el servidor. Cualquiera puede verlo, pero solo una llave puede cerrarlo y abrirlo.
- La Llave Privada: Es la llave física que tienes en tu bolsillo (Windows).
Cuando escribes ssh vagrant@192.168.56.10, el servidor te envía un "desafío" cifrado con ese candado. Tu máquina Windows usa su llave privada para resolver el acertijo y se lo devuelve. El servidor dice: "Si has podido resolverlo, es porque tienes la llave real. Adelante". Por eso no te pide contraseña: tu identidad es tu llave.
```

2. ¿Por qué ese comando y ese número (-b 4096)?
```
El comando fue: ssh-keygen -t rsa -b 4096
-t rsa: Indica el algoritmo (RSA). Es el estándar más compatible del mundo. Es como elegir el tipo de cerradura (una cerradura de puntos, por ejemplo).
-b 4096: Aquí está la clave. Es el tamaño de la llave en bits.
> Una llave de 1024 bits hoy es considerada débil (se puede romper por fuerza bruta con superordenadores).
> Una llave de 2048 es el estándar actual.
> Una llave de 4096 es el nivel "paranoico" o de alta seguridad. Es como si en lugar de una llave de 5 dientes, tuvieras una de 50. Cuanto más larga es la llave, más difícil es para un hacker adivinar la combinación mediante matemáticas.
```

3. ¿Por qué esos permisos en concreto (chmod 600)?
Este es el punto donde mucha gente falla. En Linux, el sistema de archivos es muy estricto con la seguridad.
```
El comando chmod 600 ~/.ssh/authorized_keys significa:
- 6 (Lectura y Escritura) para el dueño (tú, el usuario vagrant).
- 0 (Nada) para el grupo.
- 0 (Nada) para otros.
```
> ¿Por qué es obligatorio? SSH es muy "especialito". Si el archivo donde guardas las llaves estuviera abierto (por ejemplo, que cualquiera pudiera leerlo), SSH consideraría que el servidor está comprometido y, por seguridad, ignoraría la llave y te pediría contraseña. SSH dice: "Si no eres capaz de cuidar tu propia cerradura, no confío en que esta conexión sea segura".

📓 RESUMEN PARA TUS APUNTES (Añadir a la Sesión 4)  
🧐 Notas Técnicas de Seguridad  
- Criptografía Asimétrica: Relación entre id_rsa (privada) e id_rsa.pub (pública). La pública cifra, la privada descifra.
- Robustez (4096 bits): Mayor longitud de clave implica una protección exponencial contra ataques de fuerza bruta.
- Principio de Mínimo Privilegio (chmod 600): SSH requiere que los archivos de identidad sean accesibles solo por el propietario. Si los permisos son demasiado abiertos, el servicio SSH rechaza la clave por motivos de seguridad.