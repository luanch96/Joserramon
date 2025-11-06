# 📋 Instrucciones para Ejecutar el Proyecto Inception Plus

Esta guía te explica paso a paso cómo ejecutar el proyecto WordPress con Docker.

## 📌 Requisitos Previos

- Docker y Docker Compose instalados
- Permisos de sudo (para configurar `/etc/hosts`)
- Acceso a terminal

## 👤 Funcionamiento Multi-Usuario

**✅ El proyecto funciona con cualquier usuario del sistema.** El Makefile detecta automáticamente:
- El **usuario actual** que ejecuta los comandos
- El **HOME** del usuario (incluso si se ejecuta con `sudo`)
- Genera el **dominio** automáticamente como `usuario.42.fr`

**Ejemplo:**
- Si lo ejecuta el usuario `jrc` → dominio: `jrc.42.fr` → datos en `/home/jrc/data/`
- Si lo ejecuta el usuario `maria` → dominio: `maria.42.fr` → datos en `/home/maria/data/`

**Cada usuario tiene sus propios datos independientes.**

Para usar un dominio específico (independiente del usuario), configura `DOMAIN_NAME` en `srcs/env`.

## 🚀 Pasos para Ejecutar el Proyecto

### 1️⃣ Configuración Inicial (Solo Primera Vez)

#### Paso 1.1: Configurar el dominio en `/etc/hosts`

El dominio debe estar configurado en `/etc/hosts` para que el navegador pueda resolverlo.

**Opción A: Dominio automático (usuario.42.fr)**
```bash
# El dominio se genera automáticamente desde tu nombre de usuario
sudo bash -c 'echo "127.0.0.1 $(whoami).42.fr" >> /etc/hosts'
```

**Opción B: Dominio específico (si está configurado en srcs/env)**
```bash
# Si DOMAIN_NAME está en srcs/env, usa ese valor
DOMAIN=$(grep DOMAIN_NAME srcs/env | cut -d= -f2)
sudo bash -c "echo \"127.0.0.1 $DOMAIN\" >> /etc/hosts"
```

**Verificación:**
```bash
grep "\.42\.fr" /etc/hosts
```

#### Paso 1.2: Configurar el entorno

Edita el archivo `srcs/env` si necesitas cambiar el dominio o las credenciales:

```bash
nano srcs/env
# o
vim srcs/env
```

**Variables disponibles:**
- `DOMAIN_NAME`: Dominio del sitio (por defecto: `joscastr.42.fr`)
- `MYSQL_USER`: Usuario de MySQL
- `MYSQL_PASSWORD`: Contraseña de MySQL
- `MYSQL_ROOT_PASSWORD`: Contraseña root de MySQL
- `WP_ADMIN_USER`: Usuario administrador de WordPress
- `WP_ADMIN_PASSWORD`: Contraseña del administrador
- `WP_ADMIN_EMAIL`: Email del administrador
- `WP_TITLE`: Título del sitio WordPress

#### Paso 1.3: Preparar directorios y certificados SSL

Ejecuta el comando `setup` para crear los directorios necesarios y generar los certificados SSL:

```bash
make setup
```

Este comando:
- Crea los directorios `~/data/mariadb`, `~/data/wordpress`, `~/data/ssl`
- Genera los certificados SSL para el dominio
- Te indica si necesitas agregar el dominio a `/etc/hosts`

### 2️⃣ Construir y Levantar los Contenedores

#### Opción A: Todo en un comando (Recomendado)

```bash
make run
```

Este comando construye las imágenes y levanta todos los contenedores.

#### Opción B: Paso a paso

```bash
# 1. Construir las imágenes
make build

# 2. Levantar los contenedores
make up
```

### 3️⃣ Instalar WordPress

Después de que los contenedores estén corriendo, instala WordPress automáticamente:

```bash
./install-wordpress.sh
```

Este script:
- Instala `wp-cli` en el contenedor WordPress
- Configura e instala WordPress automáticamente
- Te muestra las credenciales de acceso

**Credenciales por defecto:**
- Usuario: `joscastr` (o el valor de `WP_ADMIN_USER` en `srcs/env`)
- Contraseña: `secure_password` (o el valor de `WP_ADMIN_PASSWORD` en `srcs/env`)

### 4️⃣ Acceder al Sitio

Abre tu navegador y visita:

```
https://joscastr.42.fr
```

**⚠️ Importante:** Como el certificado SSL es autofirmado, el navegador mostrará una advertencia de seguridad. Para continuar:

- **Firefox**: Haz clic en "Avanzado" → "Continuar hacia joscastr.42.fr (no recomendado)"
- **Chrome/Edge**: Haz clic en "Avanzado" → "Continuar a joscastr.42.fr (no seguro)"

### 5️⃣ Acceder al Panel de Administración

Para acceder al panel de administración de WordPress:

```
https://joscastr.42.fr/wp-admin
```

Usa las credenciales que configuraste en `srcs/env` o las mostradas por `install-wordpress.sh`.

## 🔧 Comandos Útiles

### Ver estado de los contenedores

```bash
make info
# o
docker ps
```

### Ver logs de los contenedores

```bash
# Todos los contenedores
docker-compose -f srcs/docker-compose.yml logs

# Contenedor específico
docker-compose -f srcs/docker-compose.yml logs nginx
docker-compose -f srcs/docker-compose.yml logs wordpress
docker-compose -f srcs/docker-compose.yml logs mariadb
```

### Reiniciar los contenedores

```bash
make restart
```

### Detener los contenedores

```bash
make down
```

### Limpiar todo (contenedores, imágenes, volúmenes)

```bash
make clean
```

### Limpieza completa (incluye datos)

```bash
make fclean
```

⚠️ **Cuidado:** `make fclean` elimina todos los datos de MariaDB y WordPress.

## 🔍 Verificación y Diagnóstico

### Verificar que todo funciona

```bash
# Verificar contenedores
docker ps | grep -E "nginx|wordpress|mariadb"

# Verificar conectividad HTTPS
curl -k -I https://joscastr.42.fr

# Verificar certificados SSL
ls -la ~/data/ssl/

# Verificar base de datos
docker exec mariadb mysql -u root -pMIA1234 -e "SHOW DATABASES;"
```

### Script de verificación

Ejecuta el script de verificación incluido:

```bash
./check_eval.sh
```

### Script para configurar hosts

Si necesitas configurar el dominio en `/etc/hosts`:

```bash
./fix-hosts.sh
```

## 🐛 Solución de Problemas

### Problema: "Could not resolve host"

**Solución:** El dominio no está en `/etc/hosts`. Ejecuta:
```bash
sudo bash -c 'echo "127.0.0.1 joscastr.42.fr" >> /etc/hosts'
```

### Problema: El sitio no carga / página en blanco

**Solución:** WordPress no está instalado. Ejecuta:
```bash
./install-wordpress.sh
```

### Problema: Error de conexión a la base de datos

**Solución:** Verifica que MariaDB esté corriendo:
```bash
docker ps | grep mariadb
docker logs mariadb
```

### Problema: Certificados SSL no encontrados

**Solución:** Regenera los certificados:
```bash
make setup
```

### Problema: Contenedores no inician

**Solución:** Verifica los logs y reinicia:
```bash
docker-compose -f srcs/docker-compose.yml logs
make restart
```

## 📝 Resumen Rápido

Para una ejecución rápida desde cero:

```bash
# 1. Configurar hosts (dominio automático basado en tu usuario)
sudo bash -c 'echo "127.0.0.1 $(whoami).42.fr" >> /etc/hosts'

# 2. Setup inicial
make setup

# 3. Construir y levantar
make run

# 4. Instalar WordPress
./install-wordpress.sh

# 5. Abrir navegador (usa tu-usuario.42.fr)
# https://$(whoami).42.fr
```

**Nota:** El dominio se genera automáticamente. Si ejecutas `make setup`, te mostrará el dominio que se usará.

## 📚 Estructura del Proyecto

```
inception-plus/
├── srcs/
│   ├── docker-compose.yml    # Configuración de contenedores
│   ├── env                   # Variables de entorno
│   └── requirements/
│       ├── mariadb/          # Configuración MariaDB
│       ├── nginx/            # Configuración Nginx
│       └── wordpress/        # Configuración WordPress
├── secrets/                  # Credenciales (Docker secrets)
├── Makefile                  # Comandos make
├── install-wordpress.sh      # Script de instalación WordPress
├── fix-hosts.sh              # Script para configurar /etc/hosts
└── check_eval.sh             # Script de verificación
```

## 🎯 Información de Acceso

**El dominio depende del usuario que ejecuta el proyecto:**

- **URL del sitio:** `https://[tu-usuario].42.fr` (ej: `https://jrc.42.fr`)
- **URL del admin:** `https://[tu-usuario].42.fr/wp-admin`
- **Usuario admin:** (ver `srcs/env` o ejecutar `./install-wordpress.sh`)
- **Contraseña admin:** (ver `srcs/env` o ejecutar `./install-wordpress.sh`)

**Para verificar tu dominio:**
```bash
make info
# o
echo "https://$(whoami).42.fr"
```

## 💡 Notas Importantes

1. **Persistencia de datos:** Los datos se guardan en `~/data/mariadb` y `~/data/wordpress`
2. **Certificados SSL:** Los certificados están en `~/data/ssl`
3. **Dominio:** El dominio se configura automáticamente desde `srcs/env` o el nombre de usuario
4. **Puerto:** El sitio está disponible en el puerto 443 (HTTPS)
5. **Reinicio:** Los datos persisten después de reiniciar los contenedores

---

¿Necesitas ayuda? Revisa los logs con `docker-compose -f srcs/docker-compose.yml logs` o ejecuta `./check_eval.sh` para diagnóstico.

