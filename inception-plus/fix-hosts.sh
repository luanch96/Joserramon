#!/bin/bash

# Script para agregar el dominio a /etc/hosts

DOMAIN_NAME=${DOMAIN_NAME:-joscastr.42.fr}

echo "🔧 Configurando /etc/hosts para $DOMAIN_NAME..."

if grep -q "$DOMAIN_NAME" /etc/hosts 2>/dev/null; then
    echo "✅ El dominio $DOMAIN_NAME ya está en /etc/hosts"
    grep "$DOMAIN_NAME" /etc/hosts
else
    echo "📝 Agregando $DOMAIN_NAME a /etc/hosts..."
    sudo bash -c "echo '127.0.0.1 $DOMAIN_NAME' >> /etc/hosts"
    if [ $? -eq 0 ]; then
        echo "✅ Dominio agregado correctamente"
        echo "📍 Entrada en /etc/hosts:"
        grep "$DOMAIN_NAME" /etc/hosts
    else
        echo "❌ Error al agregar el dominio. Por favor, ejecuta manualmente:"
        echo "   sudo bash -c 'echo \"127.0.0.1 $DOMAIN_NAME\" >> /etc/hosts'"
        exit 1
    fi
fi

echo ""
echo "🧪 Verificando conectividad..."
if curl -k -s -o /dev/null -w "%{http_code}" "https://$DOMAIN_NAME" | grep -q "200\|302\|301\|403"; then
    echo "✅ El sitio está respondiendo correctamente"
else
    echo "⚠️  El sitio no responde todavía. Verifica que los contenedores estén corriendo:"
    echo "   docker ps"
    echo "   docker-compose -f srcs/docker-compose.yml ps"
fi

