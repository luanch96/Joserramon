# Documentación explicativa para evaluación (42)

Este documento describe cómo está organizado el proyecto, cómo desplegarlo y qué comprobar durante la evaluación en 42. Está pensado para que el evaluator pueda levantar el proyecto, verificar requisitos (persistencia, SSL, contenedores funcionando) y seguir pasos de verificación rápidos.

## 1. Resumen del proyecto

Proyecto Docker que despliega un WordPress detrás de Nginx con una base de datos MariaDB. Está diseñado para persistir datos mediante volúmenes del host, usar Docker secrets para credenciales sensibles y servir el sitio mediante HTTPS con certificados locales montados.

Servicios principales (definidos en `srcs/docker-compose.yml`):
- mariadb: imagen construida desde `srcs/requirements/mariadb`.
- wordpress: imagen construida desde `srcs/requirements/wordpress` y conectada a la base de datos.
- nginx: reverso TLS (HTTP->HTTPS) construido desde `srcs/requirements/nginx`, sirve archivos de WordPress y pasa PHP a `wordpress`.

## 2. Estructura de archivos relevante

- `srcs/docker-compose.yml` — archivo principal para levantar la aplicación.
- `srcs/env` — variables de entorno por defecto (DOMAIN_NAME, credenciales, etc.).
- `secrets/` — contiene archivos con contraseñas utilizados por Docker secrets (`mariadb_root_passwd.txt`, `mariadb_usr_passwd.txt`, `mycredentials.txt`).
- `srcs/requirements/mariadb/` — Dockerfile y scripts de inicialización (`init-db.sql`, `entrypoint.sh`, `settings.sh`).
- `srcs/requirements/wordpress/` — Dockerfile y configuraciones (wp-config.php, scripts de admin).
- `srcs/requirements/nginx/` — Dockerfile y `conf/nginx.conf` (configuración SSL y proxy a PHP-FPM).

## 3. Variables y secrets clave

- Variables en `srcs/env` (ejemplo):
  - DOMAIN_NAME=joscastr.42.fr
  - MYSQL_USER, MYSQL_PASSWORD, MYSQL_ROOT_PASSWORD
  - WP_ADMIN_USER, WP_ADMIN_PASSWORD, WP_ADMIN_EMAIL, WP_TITLE

- Docker Compose está configurado para usar secrets:
  - `mariadb_root_password` -> `secrets/mariadb_root_passwd.txt`
  - `mariadb_user` -> `secrets/mariadb_usr_passwd.txt`
  - `mariadb_password` -> `secrets/mycredentials.txt`

Nota: Los secrets se montan en contenedores en `/run/secrets/...` y son referenciados por las variables de entorno del contenedor (ej. `MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mariadb_root_password`). Esto evita poner credenciales en texto plano en variables de entorno del `docker-compose.yml`.

## 4. Volúmenes y persistencia

Los volúmenes se configuran con `driver_opts` apuntando a rutas en el host (bind mounts):
- `mariadb_data` -> `${HOST_HOME}/data/mariadb`
- `wordpress_data` -> `${HOST_HOME}/data/wordpress`
- Certificados SSL: `${HOST_HOME}/data/ssl` montado en `/etc/nginx/ssl`

Esto garantiza que los datos sobreviven al reinicio o recreación de contenedores.

## 5. Cómo desplegar (pasos mínimos)

1. Preparar directorios en el host (usar la ruta indicada en `HOST_HOME`):

```bash
mkdir -p $HOME/data/mariadb
mkdir -p $HOME/data/wordpress
mkdir -p $HOME/data/ssl
```

2. Ajustar variables de entorno (opcional): editar `srcs/env` o exportar variables antes de levantar (ejemplo `DOMAIN_NAME`).

```bash
export HOST_HOME=$HOME
# opcional: export DOMAIN_NAME=tu_dominio.local
```

3. Construir y levantar con Docker Compose (desde la raíz del repo):

```bash
cd /home/jrc/Escritorio/inception-plus/srcs
docker-compose up --build -d
```

4. Comprobar contenedores:

```bash
docker-compose ps
```

5. Abrir el navegador en `https://$DOMAIN_NAME` (si DNS/hosts apuntan a la máquina) o usar `curl -k` para probar si no hay DNS configurado:

```bash
curl -k https://$DOMAIN_NAME
```

## 6. Comandos de verificación útiles

- Verificar que Nginx sirva en 443:

```bash
docker ps | grep nginx
curl -I -k https://$DOMAIN_NAME
```

- Conectarse a MariaDB desde dentro del contenedor (leer secret desde host si es necesario):

```bash
# ver el secret en el host (solo si tienes permisos):
sudo cat secrets/mariadb_root_passwd.txt

# ejecuta un cliente mysql dentro del contenedor:
docker exec -it mariadb mysql -u root -p
# cuando se pida password, pega el contenido del archivo de secret
```

- Comprobar persistencia:

```bash
# crear un archivo en wordpress_data
docker exec -it wordpress bash -c "touch /var/www/wordpress/test_file"
# detener y eliminar contenedores
docker-compose down
# volver a levantar
docker-compose up -d
# comprobar que test_file sigue presente
docker exec -it wordpress bash -c "ls -la /var/www/wordpress/test_file"
```

## 7. Qué evaluar para la corrección en 42 (checklist)

- [ ] Todos los contenedores están arriba: `docker-compose ps` y `docker ps`.
- [ ] El sitio WordPress responde en HTTPS en `DOMAIN_NAME` (o `curl -k`).
- [ ] SSL está configurado en Nginx (certificado y clave presentes en `/etc/nginx/ssl` dentro del contenedor). Ver `nginx.conf` para TLSv1.2/1.3.
- [ ] MariaDB inicializa y WordPress se conecta usando los Docker secrets (no credenciales visibles en `docker-compose.yml`).
- [ ] Volúmenes persisten datos tras `docker-compose down` y `up` (comprobar archivos o base de datos).
- [ ] No exponer puertos innecesarios (solo 443 mapeado desde nginx según `docker-compose.yml`).
- [ ] Scripts de inicialización (si existen) funcionan: `init-db.sql` y scripts en `requirements/*/tools`.

## 8. Notas de seguridad y buenas prácticas

- Evitar incrustar contraseñas en `docker-compose.yml`; el proyecto ya usa Docker secrets para eso.
- Asegurarse de que las rutas de volúmenes en host (`HOST_HOME`) tengan los permisos correctos y no sean accesibles públicamente.
- Los certificados montados en `/etc/nginx/ssl` son leídos por Nginx como archivos; protege el directorio `data/ssl` en el host.

## 9. Problemas comunes y soluciones rápidas

- Si falta `docker-compose`: instalarlo siguiendo `adaptacion_proyecto.md` o usar `docker compose` (plugin de Docker).
- Error de permisos de Docker: agregar el usuario al grupo docker (`sudo usermod -aG docker $USER`) y reiniciar sesión.
- Volúmenes vacíos: comprobar que `HOST_HOME` apunta al directorio correcto y que `driver_opts` apunta a rutas válidas.

## 10. Limpieza (stop + borrar volúmenes)

```bash
# Parar y eliminar contenedores
docker-compose down

# Eliminar volúmenes (ojo: pérdida de datos)
docker volume rm inception-mariadb_data inception-wordpress_data || true
# o eliminar carpetas bind en host
rm -rf $HOME/data/mariadb/*
rm -rf $HOME/data/wordpress/*
```

## 11. Archivos/paths para presentar al evaluator

- `srcs/docker-compose.yml` — cómo orquestar todo.
- `srcs/requirements/nginx/conf/nginx.conf` — configuración SSL y PHP-FPM proxy.
- `secrets/*.txt` — indican que se usan Docker secrets (no compartir los contenidos públicamente).
- `srcs/env` — variables por defecto usadas durante el despliegue.

---

Si quieres, puedo:
- Añadir capturas de comandos y su salida esperada para que el evaluator las compare.
- Actualizar `adaptacion_proyecto.md` en lugar de crear un archivo nuevo.
- Generar un breve script `check_eval.sh` que ejecute las comprobaciones automáticamente.

Archivo creado: `DOCUMENTACION_42.md` en la raíz del proyecto.
