#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
#  ENVIRONMENT-IA · Instalador maestro
#  Instala y levanta OmniRoute y/o  en contenedores Docker.
#
#  Uso:
#    ./install.sh              → menú interactivo
#    ./install.sh all          → instala OmniRoute + 
#    ./install.sh omniroute    → solo OmniRoute
#    ./install.sh      → solo 
# ══════════════════════════════════════════════════════════════════════
set -e

# ─── Colores para salida bonita ──────────────────────────────────────
GRN='\033[0;32m'; YEL='\033[1;33m'; RED='\033[0;31m'; CYN='\033[0;36m'; NC='\033[0m'
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

banner() {
  echo -e "${CYN}"
  echo "  ╔═══════════════════════════════════════════════════════════╗"
  echo "  ║               ENVIRONMENT-IA · INSTALADOR                 ║"
  echo "  ║       OmniRoute (port 20128) +  (port 18789)     ║"
  echo "  ╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

ok()   { echo -e "${GRN}  ✔ $1${NC}"; }
info() { echo -e "${YEL}  ℹ  $1${NC}"; }
err()  { echo -e "${RED}  ✘ $1${NC}"; }

# ─── Verificación de Docker ──────────────────────────────────────────
check_docker() {
  if ! command -v docker &>/dev/null; then
    err "Docker no está instalado."
    echo "     Instálalo con:  sudo apt install docker.io docker-compose-v2"
    echo "     (Debian/Ubuntu) y luego vuelve a ejecutar este script."
    exit 1
  fi
  if ! docker compose version &>/dev/null; then
    err "Docker Compose v2 no está disponible."
    echo "     Instálalo con:  sudo apt install docker-compose-v2"
    exit 1
  fi
  if ! docker info &>/dev/null; then
    err "El demonio de Docker no está corriendo o tu usuario no tiene permisos."
    echo "     Ejecuta:  sudo systemctl start docker"
    echo "     Y si tu usuario no está en el grupo docker:  sudo usermod -aG docker \$USER"
    echo "     (cierra y abre sesión para aplicar el grupo)"
    exit 1
  fi
  ok "Docker detectado: $(docker --version)"
  ok "Compose detectado: $(docker compose version)"
}

# ─── Instaladores por servicio ───────────────────────────────────────
install_omniroute() {
  echo ""
  info "▶ Instalando OmniRoute (gateway de IA)..."
  bash "$DIR/omniroute/install.sh"
}

install_() {
  echo ""
  info "▶ Instalando  (agente autónomo)..."
  bash "$DIR//install.sh"
}

# ─── Resumen final ───────────────────────────────────────────────────
summary() {
  echo ""
  echo -e "${GRN}"
  echo "  ╔═══════════════════════════════════════════════════════════╗"
  echo "  ║              INSTALACIÓN COMPLETADA                       ║"
  echo "  ╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo "  PUERTOS:"
  echo "    OmniRoute  →  http://localhost:20128   (dashboard + API)"
  echo "       →  http://localhost:18789   (gateway web)"
  echo ""
  echo "  SIGUIENTE PASO: configurar OmniRoute en el navegador"
  echo "    (contraseña maestra, API keys, providers con tus 45 keys,"
  echo "     combos y compresión) → lee  omniroute/README.md"
  echo ""
  echo "  Luego conecta  → lee  /README.md"
  echo ""
  echo "  ¿Olvidaste algo? Lo más importante:"
  echo "    1) Pon una CONTRASEÑA FUERTE a OmniRoute y guárdala."
  echo "    2) Cada .env.example tiene instrucciones dentro."
  echo ""
}

# ─── Flujo principal ─────────────────────────────────────────────────
main() {
  banner
  check_docker

  MODE="${1:-menu}"

  case "$MODE" in
    all)
      install_omniroute
      install_
      ;;
    omniroute)
      install_omniroute
      ;;
    )
      install_
      ;;
    menu)
      echo ""
      echo "  ¿Qué quieres instalar?"
      PS3="  Selecciona una opción: "
      select opt in "Todo (OmniRoute + )" "Solo OmniRoute" "Solo " "Salir"; do
        case "$opt" in
          "Todo (OmniRoute + )") install_omniroute; install_; break;;
          "Solo OmniRoute")            install_omniroute; break;;
          "Solo ")             install_;    break;;
          "Salir")                     echo "  Hasta luego 👋"; exit 0;;
          *) echo "  Opción inválida";;
        esac
      done
      ;;
    *)
      err "Argumento desconocido: $MODE"
      echo "  Uso: ./install.sh [all|omniroute|]"
      exit 1
      ;;
  esac

  summary
}

main "$@"