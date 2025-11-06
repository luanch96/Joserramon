#!/bin/bash

# Script para instalar WordPress automáticamente

echo "🔧 Instalando WordPress automáticamente..."

# Verificar que el contenedor wordpress esté corriendo
if ! docker ps | grep -q wordpress; then
    echo "❌ Error: El contenedor wordpress no está corriendo"
    exit 1
fi

echo "📦 Instalando wp-cli en el contenedor..."
docker exec wordpress bash -c "
    if ! command -v wp &> /dev/null; then
        wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /tmp/wp-cli.phar
        chmod +x /tmp/wp-cli.phar
        mv /tmp/wp-cli.phar /usr/local/bin/wp
        wp --info --allow-root
    fi
"

echo "⏳ Esperando a que MariaDB esté lista..."
sleep 5

# Obtener credenciales desde los secrets
DB_USER=$(cat secrets/mariadb_usr_passwd.txt | tr -d '\n\r ')
DB_PASSWORD=$(cat secrets/mycredentials.txt | tr -d '\n\r ')
DOMAIN_NAME=$(grep DOMAIN_NAME srcs/env | cut -d= -f2)
WP_ADMIN_USER=$(grep WP_ADMIN_USER srcs/env | cut -d= -f2)
WP_ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD srcs/env | cut -d= -f2)
WP_ADMIN_EMAIL=$(grep WP_ADMIN_EMAIL srcs/env | cut -d= -f2)
WP_TITLE=$(grep WP_TITLE srcs/env | cut -d= -f2)

echo "🚀 Instalando WordPress..."
docker exec wordpress bash -c "
    cd /var/www/wordpress
    
    # Verificar si WordPress ya está instalado completamente
    TABLAS=\$(wp db query 'SELECT COUNT(*) as total FROM information_schema.tables WHERE table_schema = DATABASE()' --path=/var/www/wordpress --allow-root --skip-column-names 2>/dev/null)
    if [ \"\$TABLAS\" -ge \"10\" ] && wp core is-installed --path=/var/www/wordpress --allow-root 2>/dev/null; then
        echo '✅ WordPress ya está instalado correctamente'
        exit 0
    else
        echo '⚠️  WordPress no está completamente instalado. Limpiando e instalando...'
        # Limpiar base de datos si hay tablas incompletas
        if [ \"\$TABLAS\" -gt 0 ] && [ \"\$TABLAS\" -lt \"10\" ]; then
            echo '🗑️  Eliminando tablas incompletas...'
            wp db reset --yes --path=/var/www/wordpress --allow-root 2>/dev/null || true
        fi
    fi
    
    # Instalar WordPress
    wp core install \
        --path=/var/www/wordpress \
        --url=https://$DOMAIN_NAME \
        --title='$WP_TITLE' \
        --admin_user='$WP_ADMIN_USER' \
        --admin_password='$WP_ADMIN_PASSWORD' \
        --admin_email='$WP_ADMIN_EMAIL' \
        --skip-email \
        --allow-root
    
    if [ \$? -eq 0 ]; then
        echo '✅ WordPress instalado correctamente'
        echo '🌐 Accede a: https://$DOMAIN_NAME'
        echo '👤 Usuario admin: $WP_ADMIN_USER'
        echo '🔑 Contraseña: $WP_ADMIN_PASSWORD'
    else
        echo '❌ Error al instalar WordPress'
        exit 1
    fi
"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Instalación completada"
    echo "🌐 Accede a: https://$DOMAIN_NAME"
else
    echo ""
    echo "⚠️  Hubo un problema. Intenta acceder manualmente a:"
    echo "   https://$DOMAIN_NAME/wp-admin/install.php"
fi

