# 💻 OpenCode — Asistente de código CLI

> ⏳ **PESTAÑA EN CONSTRUCCIÓN · PASO 3 DEL ECOSISTEMA**

Esta carpeta se deja **intencionalmente sin revisar** hasta que terminemos los
pasos 1–2 (OmniRoute en Docker funcionando y conectado).

**Estado actual del contenido:**
- ✅ Scripts funcionales (`opencode-install.bash`, `connect-omniroute-credentials.bash`) — **NO tocados**.
- ⏳ Guía de instalación y conexión — **se escribe en el Paso 4**.

### Lo que ya sabemos (para cuando lleguemos)
- OpenCode se instala en el PC como CLI (`curl -fsSL https://opencode.ai/install | bash`).
- **No es un contenedor**: corre directo en el sistema operativo.
- Se conecta a OmniRoute en `http://localhost:20128/v1` con su propia API key
  (`omniroute-opencode`, creada en el dashboard de OmniRoute).
- Hay 2 formas de conectarlo:
  1. **Variables de entorno permanentes** (`OPENAI_BASE_URL` + `OPENAI_API_KEY` — vía `connect-omniroute-credentials.bash`).
  2. **Plugin oficial de OmniRoute** (recomendado): descubre tus combos automáticamente en el selector de modelos.

Volveremos aquí en el **Paso 3**. Mientras tanto, NO tocar esta carpeta.