#!/bin/bash

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
OK="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
INFO="${YELLOW}i${NC}"

# Función para mostrar mensajes de estado
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${OK} $2"
        return 0
    else
        echo -e "${FAIL} $2"
        return 1
    fi
}

# Función para comprobar si un contenedor está corriendo
check_container() {
    echo -e "\n${INFO} Verificando contenedor $1..."
    docker ps --format '{{.Names}}' | grep -q "^$1$"
    print_status $? "Contenedor $1 está corriendo"
}

# Función para verificar volumen
check_volume() {
    echo -e "\n${INFO} Verificando volumen $1..."
    if [ -d "$HOME/data/$1" ]; then
        ls -la "$HOME/data/$1" > /dev/null 2>&1
        print_status $? "Volumen $1 existe y es accesible"
    else
        print_status 1 "Volumen $1 no encontrado en $HOME/data/$1"
    fi
}

# Función para verificar certificados SSL
check_ssl() {
    echo -e "\n${INFO} Verificando certificados SSL..."
    local ssl_dir="$HOME/data/ssl"
    local cert_file="$ssl_dir/nginx.crt"
    local key_file="$ssl_dir/nginx.key"
    
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        openssl x509 -in "$cert_file" -text -noout > /dev/null 2>&1
        print_status $? "Certificados SSL presentes y válidos"
    else
        print_status 1 "Certificados SSL no encontrados o inválidos"
    fi
}

# Función para verificar secretos
check_secrets() {
    echo -e "\n${INFO} Verificando Docker secrets..."
    local secrets_dir="secrets"
    for secret in "mariadb_root_passwd.txt" "mariadb_usr_passwd.txt" "mycredentials.txt"; do
        if [ -f "$secrets_dir/$secret" ]; then
            if [ -s "$secrets_dir/$secret" ]; then
                print_status 0 "Secret $secret existe y no está vacío"
            else
                print_status 1 "Secret $secret existe pero está vacío"
            fi
        else
            print_status 1 "Secret $secret no encontrado"
        fi
    done
}

# Función para verificar conectividad HTTPS
check_https() {
    echo -e "\n${INFO} Verificando conectividad HTTPS..."
    local domain=$(grep DOMAIN_NAME srcs/env | cut -d= -f2)
    if [ -z "$domain" ]; then
        domain="localhost"
    fi
    
    curl -k -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "200\|302\|301"
    print_status $? "HTTPS responde correctamente en $domain"
}

# Función para verificar conexión a MariaDB
check_mariadb() {
    echo -e "\n${INFO} Verificando conexión a MariaDB..."
    docker exec mariadb mysqladmin ping -h localhost --silent
    print_status $? "MariaDB responde a ping"
}

# Función principal
main() {
    echo -e "${INFO} Iniciando verificaciones pre-evaluación..."
    
    # 1. Verificar contenedores
    for container in "mariadb" "wordpress" "nginx"; do
        check_container "$container"
    done
    
    # 2. Verificar volúmenes
    for volume in "mariadb" "wordpress" "ssl"; do
        check_volume "$volume"
    done
    
    # 3. Verificar SSL
    check_ssl
    
    # 4. Verificar secrets
    check_secrets
    
    # 5. Verificar HTTPS
    check_https
    
    # 6. Verificar MariaDB
    check_mariadb
    
    echo -e "\n${INFO} Verificación completa."
}

# Ejecutar script
main