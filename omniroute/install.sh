#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
#  OmniRoute · Instalador
#  Descarga, levanta y verifica el contenedor del gateway de IA.
# ──────────────────────────────────────────────────────────────────────
set -e

GRN='\033[0;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; CYN='\033[0;36m'; NC='\033[0m'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

ok()   { echo -e "${GRN}  ✔ $1${NC}"; }
info() { echo -e "${YEL}  ℹ  $1${NC}"; }
err()  { echo -e "${RED}  ✘ $1${NC}"; }

echo -e "${CYN}  ── OmniRoute · instalación ──${NC}"

# ── 1. Verificar Docker ──────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  err "Docker no está instalado. Ejecuta primero el instalador maestro (install.sh)."
  exit 1
fi

# ── 2. Descargar y levantar ──────────────────────────────────────────
info "Descargando imagen y levantando el contenedor (puede tardar la 1ª vez)..."
docker compose up -d

# ── 3. Esperar a que el puerto responda ──────────────────────────────
info "Esperando a que el servicio arranque..."
READY=0
for i in $(seq 1 60); do
  if curl -s -o /dev/null -m 2 "http://localhost:20128/v1/models" 2>/dev/null; then
    READY=1
    break
  fi
  sleep 2
done

if [ "$READY" = "1" ]; then
  ok "OmniRoute está respondiendo en el puerto 20128."
else
  info "El contenedor quedó corriendo pero aún no responde."
  echo ""
  echo "  Revisa los logs con:"
  echo "    docker compose -f omniroute/docker-compose.yml logs -f"
  echo "  o    docker logs omniroute-gateway"
  exit 0
fi

# ── 4. Instrucciones siguientes ──────────────────────────────────────
echo ""
echo "  ╔════════════════════════════════════════════════════════════╗"
echo "  ║        OmniRoute está EN LÍNEA 🎉                          ║"
echo "  ╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  🌐  Abre en tu navegador:  http://localhost:20128"
echo ""
echo "  Sigue las instrucciones de config en  omniroute/README.md:"
echo "    1. Crea la contraseña maestra (¡guárdala!)"
echo "    2. Habilita REQUIRE_API_KEY"
echo "    3. Crea 1 API key (opencode)"
echo "    4. Agrega tus 45 API keys (Gemini, Groq, OpenRouter)"
echo "    5. Crea los 3 combos (bajo / medio / avanzado)"
echo "    6. Activa la compresión de contexto"
echo ""