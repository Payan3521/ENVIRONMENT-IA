#!/bin/bash

# 1. Verificar si existe el archivo .env local
if [ ! -f .env ]; then
    echo "❌ Error: No se encontró el archivo .env"
    echo "💡 Por favor, copia .env.example a .env y pon tus credenciales reales."
    exit 1
fi

echo "⚙️ Leyendo variables desde el archivo .env..."

# 2. Cargar las variables del .env temporalmente en el script
export $(grep -v '^#' .env | xargs)

# 3. Detectar la terminal actual (Zsh o Bash)
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    RC_FILE="$HOME/.zshrc"
else
    RC_FILE="$HOME/.bashrc"
fi

echo "📝 Configurando variables de entorno en $RC_FILE..."

# 4. Inyectar OPENAI_BASE_URL (evitando duplicados)
if ! grep -q "OPENAI_BASE_URL" "$RC_FILE"; then
    echo "export OPENAI_BASE_URL=\"$OMNIROUTE_BASE_URL\"" >> "$RC_FILE"
else
    # Si ya existe, actualiza la línea con el nuevo valor del .env
    sed -i.bak "s|export OPENAI_BASE_URL=.*|export OPENAI_BASE_URL=\"$OMNIROUTE_BASE_URL\"|" "$RC_FILE"
fi

# 5. Inyectar OPENAI_API_KEY (evitando duplicados)
if ! grep -q "OPENAI_API_KEY" "$RC_FILE"; then
    echo "export OPENAI_API_KEY=\"$OMNIROUTE_API_KEY\"" >> "$RC_FILE"
else
    # Si ya existe, actualiza la línea con la nueva clave del .env
    sed -i.bak "s|export OPENAI_API_KEY=.*|export OPENAI_API_KEY=\"$OMNIROUTE_API_KEY\"|" "$RC_FILE"
fi

echo "✅ ¡Configuración de OmniRoute finalizada con éxito!"
echo "🔄 Ejecuta 'source $RC_FILE' para activar los cambios en esta pestaña."