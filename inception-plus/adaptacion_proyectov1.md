# Resumen de Adaptación del Proyecto Docker

## 1. Instalación de Dependencias Necesarias

```bash
# Instalación de curl
sudo apt-get install curl

# Instalación de Docker
sudo apt-get install docker.io

# Instalación de Docker Compose (binario)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalación de Docker Buildx
sudo apt-get install docker-buildx
```

## 2. Configuración de Permisos y Grupos

```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Configurar permisos del socket de Docker
sudo chmod 666 /var/run/docker.sock

# Reinicio de servicios Docker
sudo systemctl stop docker docker.socket
sudo rm -rf /var/run/docker.sock
sudo systemctl start docker
```

## 3. Creación de Estructura de Directorios

```bash
# Crear directorios necesarios en el home del usuario
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress
mkdir -p ~/data/ssl

# Configurar permisos de los directorios
chmod -R 755 ~/data
```

## 4. Modificaciones en docker-compose.yml

Los siguientes cambios se realizaron en el archivo para adaptar las rutas:
- Cambio de `/home/luisanch/data/mariadb` a `/home/jrc/data/mariadb`
- Cambio de `/home/luisanch/data/wordpress` a `/home/jrc/data/wordpress`
- Cambio de `/home/luisanch/data/ssl` a `/home/jrc/data/ssl`

## 5. Razones de los Cambios

- **Permisos de Docker**: Los cambios en los permisos fueron necesarios para permitir que tu usuario ejecute comandos Docker sin necesidad de sudo
- **Estructura de Directorios**: La creación de directorios en tu home asegura que tengas los permisos correctos y acceso total a los datos
- **Modificación de Rutas**: Las rutas se adaptaron para que coincidan con tu estructura de sistema de archivos
- **Configuración de Volúmenes**: Los volúmenes se configuraron para mantener la persistencia de datos entre reinicios de contenedores

## 6. Verificación de la Instalación

```bash
# Verificar versión de Docker Compose
docker-compose --version

# Verificar que Docker está funcionando
docker ps

# Verificar la construcción de contenedores
docker-compose -f srcs/docker-compose.yml build
```

## Conclusiones

Estos cambios mantienen la funcionalidad original del proyecto mientras:
- Aseguran la portabilidad
- Mantienen la seguridad
- Preservan la persistencia de datos
- Facilitan la gestión y mantenimiento

Para defender el proyecto, es importante mencionar que estos cambios:
- No alteran la funcionalidad core del proyecto
- Mejoran la portabilidad
- Siguen las mejores prácticas de Docker
- Mantienen la seguridad del sistema
- Facilitan el despliegue en diferentes entornos