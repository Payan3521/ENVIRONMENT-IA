#!/bin/bash

# Salir inmediatamente si un comando falla
set -e

echo "🚀 Iniciando la instalación de OpenCode..."

# Verificar si curl está instalado, si no, avisar al usuario
if ! command -v curl &> /dev/null; then
    echo "❌ Error: 'curl' no está instalado. Por favor, instálalo antes de continuar."
    exit 1
fi

# Ejecutar el comando oficial de instalación
echo "📥 Descargando y ejecutando el script oficial..."
curl -fsSL https://opencode.ai/install | bash

echo "✅ ¡Instalación de OpenCode completada con éxito!"