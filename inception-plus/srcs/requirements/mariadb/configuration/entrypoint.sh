#!/bin/bash

set -e

echo "🚀 Iniciando MariaDB..."

DB_ROOT_PASSWORD=$(cat /run/secrets/mariadb_root_password | tr -d '\n\r' | sed 's/[[:space:]]*$//')
DB_USER=$(cat /run/secrets/mariadb_user | tr -d '\n\r' | sed 's/[[:space:]]*$//')
DB_PASSWORD=$(cat /run/secrets/mariadb_password | tr -d '\n\r' | sed 's/[[:space:]]*$//')

chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /var/log/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "📦 Inicializando base de datos MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db
    echo "✅ Base de datos inicializada"
    
    echo "🔧 Configurando usuarios y base de datos..."
    
    mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 &
    MYSQL_PID=$!
    
    sleep 5
    
    mysql -u root <<EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        CREATE DATABASE IF NOT EXISTS wordpress;
        CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'%';
        FLUSH PRIVILEGES;
EOF
    
    kill $MYSQL_PID
    wait $MYSQL_PID
    
    echo "✅ Usuario y base de datos configurados"
else
    echo "📦 Base de datos ya existe, verificando y configurando usuario..."
    
    # Iniciar MariaDB temporalmente para verificar/crear usuario
    mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 &
    MYSQL_PID=$!
    
    sleep 5
    
    # Intentar conectarnos con la contraseña del secret
    if mysql -u root -p"${DB_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
        echo "✅ Conectado con contraseña de root, configurando usuario..."
        mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
            ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
            DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
            CREATE DATABASE IF NOT EXISTS wordpress;
            CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
            GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'%';
            FLUSH PRIVILEGES;
EOF
        kill $MYSQL_PID 2>/dev/null || true
        wait $MYSQL_PID 2>/dev/null || true
    else
        echo "🔧 No se puede conectar con la contraseña actual, reseteando..."
        kill $MYSQL_PID 2>/dev/null || true
        wait $MYSQL_PID 2>/dev/null || true
        
        # Iniciar con skip-grant-tables para resetear contraseña
        mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --skip-grant-tables &
        MYSQL_PID=$!
        
        sleep 5
        
        # Resetear contraseña de root y crear usuario
        mysql -u root <<EOF
            FLUSH PRIVILEGES;
            ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
            DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
            CREATE DATABASE IF NOT EXISTS wordpress;
            CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
            GRANT ALL PRIVILEGES ON wordpress.* TO '${DB_USER}'@'%';
            FLUSH PRIVILEGES;
EOF
        
        kill $MYSQL_PID 2>/dev/null || true
        wait $MYSQL_PID 2>/dev/null || true
        echo "✅ Contraseña reseteada y usuario configurado"
    fi
fi

mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld

echo "🔧 Iniciando MariaDB..."

exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
