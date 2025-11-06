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


## 5. Razones de los Cambios

- **Permisos de Docker**: Los permisos fueron necesarios para permitir que el usuario ejecute comandos Docker sin necesidad de sudo
- **Estructura de Directorios**: La creación de directorios en el home asegura que tengas los permisos correctos y acceso total a los datos
- **Modificación de Rutas**: Las rutas se adaptaron para que coincidan con la estructura de sistema de archivos
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

## 7. Verificación Pre-Evaluación

Se ha incluido un script automático `check_eval.sh` en la raíz del proyecto que realiza las siguientes comprobaciones:

```bash
# Dar permisos de ejecución
chmod +x check_eval.sh

# Ejecutar verificaciones
./check_eval.sh
```

El script verifica automáticamente:
- Estado de los contenedores (mariadb, wordpress, nginx)
- Existencia y accesibilidad de volúmenes
- Certificados SSL (existencia y validez)
- Presencia y contenido de Docker secrets
- Conectividad HTTPS al dominio configurado
- Respuesta de MariaDB

Cada verificación muestra un indicador visual:
- ✓ (verde): La comprobación fue exitosa
- ✗ (rojo): La comprobación falló
- i (amarillo): Información sobre la comprobación en curso

## 8. Puntos Clave para Evaluación

1. **Servicios y Contenedores**:
   - Tres contenedores separados (nginx, wordpress, mariadb)
   - Solo el puerto 443 expuesto al host
   - Comunicación interna via red Docker

2. **Seguridad**:
   - Credenciales manejadas via Docker secrets
   - SSL/TLS configurado en nginx
   - No hay contraseñas en texto plano en docker-compose.yml

3. **Persistencia**:
   - Volúmenes bind-mount en `$HOME/data/`
   - Los datos sobreviven reinicios de contenedores
   - Permisos correctos en directorios del host

4. **Configuración**:
   - Variables de entorno en `srcs/env`
   - Certificados SSL en `$HOME/data/ssl/`
   - WordPress configurado via wp-config.php

## Conclusiones



## Notas de Depuración

Si encuentras problemas durante la evaluación:

1. **Problemas de permisos**:
   ```bash
   sudo chown -R $USER:$USER ~/data
   chmod -R 755 ~/data
   ```

2. **Contenedores no arrancan**:
   ```bash
   # Ver logs de contenedores
   docker-compose logs
   
   # Reiniciar servicios
   docker-compose down
   docker-compose up -d
   ```

3. **Errores de certificados**:
   ```bash
   # Regenerar certificados
   cd srcs/requirements/nginx/tools
   ./generate-ssl.sh
   ```

4. **Base de datos no inicializa**:
   ```bash
   # Verificar secrets
   cat secrets/mariadb_root_passwd.txt
   cat secrets/mariadb_usr_passwd.txt
   
   # Limpiar y reiniciar
   docker-compose down -v
   rm -rf ~/data/mariadb/*
   docker-compose up -d
   ```