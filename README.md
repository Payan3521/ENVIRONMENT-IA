# 🌐 ENVIRONMENT-IA

**Ecosistema de IA auto-hospedado** con agentes y modelos gratuitos, organizado en un solo repositorio listo para instalar en cualquier PC Linux con Docker.

> 🧠 **Idea central:** 15 cuentas de correo × 3 plataformas de IA gratuitas = **45 API keys renovables**. OmniRoute las agrupa tras un único endpoint y rota automáticamente entre ellas cuando se agota una cuota.  y OpenCode consumen ese endpoint como si fueran un solo proveedor de IA *ilimitado*.

---

## 🏗️ Arquitectura

```
                    ┌──────────────────────────────────────────────────────┐
                    │               TU PC · Linux Debian                   │
                    │                                                      │
                    │  ┌──────────────────────┐    ┌────────────────────┐  │
                    │  │       OmniRoute      │◄───│            │  │
                    │  │   (Docker container) │ API│  (Docker container)│  │
                    │  │   Puerto :20128      │    │  Puerto :18789     │  │
                    │  │   http://localhost/  │    │  http://localhost/ │  │
                    │  └─────────┬────────────┘    └────────────────────┘  │
                    │            │ 45 API keys (1 sola piscina)            │
                    │            ▼                                         │
                    │  ┌──────────────────────┐    ┌────────────────────┐  │
                    │  │  Gemini  ×15 keys    │    │   OpenCode CLI     │  │
                    │  │  Groq    ×15 keys    │    │ (instalado en elPC)│  │
                    │  │  Mistral ×15 keys    │    │  NO es un container│  │
                    │  └──────────────────────┘    │  Puerto :localhost │  │
                    │                              └────────────────────┘  │
                    └──────────────────────────────────────────────────────┘
```

> 📐 Diagrama completo e interactivo (Mermaid): [docs/arquitectura.md](docs/arquitectura.md)

---

## 🧩 Servicios y puertos

| Servicio | Qué es | Puerto | Acceso web | Tipo |
|---|---|---|---|---|
| **OmniRoute** | Gateway que centraliza 45 API keys y enruta solicitudes | `20128` | `http://localhost:20128` | Contenedor Docker |
| **** | Agente autónomo con memoria, skills y sesiones | `18789` | `http://localhost:18789` | Contenedor Docker |
| **OpenCode** | Asistente de código/agente CLI en tu terminal | — | — | Instalado en el PC (NO container) |

Los 2 contenedores comparten la red del host. OmniRoute expone su API compatible con OpenAI en `http://localhost:20128/v1`.  (dentro de Docker) la alcanza vía `http://host.docker.internal:20128/v1`.

---

## ✅ Requisitos previos

| Requisito | Verificar con |
|---|---|
| Linux (Debian/Ubuntu recomendado) | `lsb_release -a` |
| Docker + Docker Compose v2 | `docker --version` y `docker compose version` |
| `curl` | `curl --version` |
| `sudo` (solo la primera vez, para permisos) | `sudo -v` |

Si Docker no está instalado:
```bash
sudo apt update
sudo apt install docker.io docker-compose-v2 curl
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # ← reinicia sesión para que aplique
```

---

## 🚀 Instalación en 2 minutos

```bash
# 1. Clona (o copia) el repositorio y entra
git clone <tu-repo> && cd ENVIRONMENT-IA

# 2. Ejecuta el instalador maestro
./install.sh          # o: ./install.sh all
```

El instalador:
1. Verifica Docker.
2. Crea las carpetas de  con los permisos correctos (pedirá `sudo` UNA sola vez).
3. Genera los `.env` desde las plantillas `.env.example`.
4. Levanta OmniRoute y .
5. Te muestra las URLs.

> ⚠️ Después del paso 2 deberás **editar los `.env` generados** poniendo tus credenciales reales. Abre `omniroute/README.md` para la configuración completa de OmniRoute.

---

## 📋 Los 4 pasos de configuración

El ecosistema se configura en 4 pasos secuenciales:

### Paso 1 · Levantar los contenedores ✅ (ya hecho por el instalador)
- [x] OmniRoute corriendo en `:20128`
- [x]  corriendo en `:18789`

### Paso 2 · Configurar OmniRoute (la IA) 📄 → [`omniroute/README.md`](omniroute/README.md)
En el navegador:
1. Poner contraseña maestra (¡guárdala!).
2. Habilitar `REQUIRE_API_KEY` (seguridad).
3. Crear 2 API keys: una para , otra para OpenCode.
4. Agregar los **3 proveedores** (Gemini, Groq, Mistral) y pegar las **45 API keys** (15 conexiones por proveedor).
5. Crear los **3 combos**: `bajo`, `medio`, `avanzado`.
6. Activar **compresión de contexto** (RTK+Caveman).

OmniRoute hará automáticamente el **fallback/rotación** entre tus 45 keys conforme se agoten cuotas diarias y se renueven.

### Paso 3 · Conectar  a OmniRoute 📄 → [`/README.md`](/README.md)
- `/.env` → pegar la API key de  + endpoint `host.docker.internal:20128/v1`.
- `/config/.json` → ya incluye los 3 combos como modelos.
- Abrir `http://localhost:18789` en el navegador y configurar el gateway.

### Paso 4 · (Volver a) instalar OpenCode y conectarlo 📄 → [`opencode/README.md`](opencode/README.md)
> ⏳ **Pendiente de definir en esta revisión.** OpenCode se instala como CLI en el PC y consume OmniRoute con su propia API key.

---

## 🗂️ Estructura del repositorio

```
ENVIRONMENT-IA/
├── install.sh                  ← Instalador maestro (todo en uno)
├── .env.example                ← Plantilla maestra de credenciales (respaldo)
├── .gitignore                  ← Protege tus keys y datos generados
├── omniroute/                  ← Contenedor del gateway de IA
│   ├── docker-compose.yml
│   ├── install.sh
│   └── README.md               ← Configuración UI paso a paso (keys, combos)
├── /                   ← Contenedor del agente autónomo
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── install.sh
│   ├── config/.json.example
│   └── README.md               ← Configuración del gateway + conexión a OmniRoute
├── docs/
│   ├── credenciales.md         ← ⭐ Tabla maestra de tus 45 API keys (plantilla)
│   ├── arquitectura.md         ← Diagrama Mermaid + ASCII
│   └── troubleshooting.md      ← Errores comunes y soluciones
└── opencode/                   ← CLI (se configura en el Paso 4)
    └── README.md
```

---

## 🛠️ Comandos útiles

```bash
# Estado de los contenedores
docker compose -f omniroute/docker-compose.yml ps
docker compose -f /docker-compose.yml ps

# Ver logs en vivo
docker compose -f omniroute/docker-compose.yml logs -f
docker compose -f /docker-compose.yml logs -f

# Detener / reiniciar
docker compose -f omniroute/docker-compose.yml down
docker compose -f /docker-compose.yml restart

# Actualizar a las últimas imágenes
docker compose -f omniroute/docker-compose.yml pull && docker compose -f omniroute/docker-compose.yml up -d
docker compose -f /docker-compose.yml pull && docker compose -f /docker-compose.yml up -d
```

---

## ⚠️ Notas importantes

- **Seguridad:** los `.env` y las carpetas `config/`/`workspace/` de  están en `.gitignore` y **nunca se suben**. Las API keys reales se cargan en OmniRoute por el navegador, no en archivos del repo.
- **Modelos gratuitos cambian:** los planes gratuitos de 2026 evolucionan. Si un modelo falla o desaparece, consulta [docs/troubleshooting.md](docs/troubleshooting.md) para saber cómo actualizar tus combos.
- **Proveedores descartados (no los uses):** **OpenRouter** (da crédito único ~$1 que se agota y NO se renueva), **Cerebras** (pide tarjeta: `payment_required`) y **NVIDIA NIM** (pide contactar soporte). Mira el apartado en [troubleshooting.md](docs/troubleshooting.md).
- La contraseña maestra de OmniRoute **no se puede recuperar**: si la pierdes, hay que borrar el volumen y volver a configurar.

---

📚 **Documentación detallada:** [Credenciales](docs/credenciales.md) · [Arquitectura](docs/arquitectura.md) · [Troubleshooting](docs/troubleshooting.md)