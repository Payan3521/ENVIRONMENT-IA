# 🔀 OmniRoute — Gateway de IA

**OmniRoute es el cerebro del ecosistema.** Es un contenedor Docker que:
- Centraliza tus **45 API keys gratuitas** (Gemini ×15, Groq ×15, Mistral ×15).
- Expone **una sola API compatible con OpenAI** en `http://localhost:20128/v1`.
- Balancea y rota automáticamente entre cuentas cuando se agota una cuota diaria.
- Agrupa modelos en **combos** que puedes elegir según la potencia necesaria.

> ✅ **Port:** `20128` · **Tipo:** contenedor Docker · **Config:** vía navegador.

---

## 🚀 Instalación

```bash
# Opción A: instalador maestro (desde la raíz del repo)
./install.sh omniroute

# Opción B: manual (desde esta carpeta)
cd omniroute
docker compose up -d
```

Comprueba que esté vivo:
```bash
curl -s http://localhost:20128/v1/models > /dev/null && echo "OK ✅"
```

---

## 🌐 Configuración en el navegador (paso a paso)

Abre **http://localhost:20128** y sigue estos pasos en orden:

### Paso 1 · Contraseña maestra
El primer arranque te pedirá **crear la contraseña maestra**.
- ⚠️ **IMPORTANTE:** guárdala en un gestor de contraseñas. **No es recuperable.**
  Si la pierdes → `docker compose down -v` y volver a configurar todo desde cero.
- En el resguardo `.env.example` (raíz) hay una casilla para anotarla.

### Paso 2 · Habilitar REQUIRE_API_KEY (seguridad)
Para que no cualquiera use tu gateway. `REQUIRE_API_KEY` es un **feature flag** de categoría **Security**:

1. Ve a **Dashboard → Settings → Feature Flags** (Configuración → Funciones/Banderas).
2. Filtra por categoría **Security** (o usa el buscador).
3. Busca la tarjeta **"Require API Key"** (descripción: *"Require an API key for all incoming requests"*).
4. Activa el toggle. (Verificado en código: **toma efecto al instante**, no requiere reiniciar.)
5. Guarda si te lo pide.
6. A partir de ahora `curl /v1/models` devuelve `401` si no mandas key (`Authorization: Bearer sk-...`) → eso es correcto y deseado.

> ℹ️ **Alternativa por entorno:** la variable `REQUIRE_API_KEY` en `docker-compose.yml` hace lo mismo (default `false`). El toggle del dashboard es más cómodo porque no requiere reiniciar el contenedor. Usa uno solo para evitar confusiones.

### Paso 3 · Crear las 2 API keys del gateway
1. Ve a **Dashboard → API Keys** (Settings → API Keys en algunos diseños).
2. Crea una key llamada **`omniroute-opencode`** → se usará para OpenCode.
3. Crea otra llamada **`omniroute-`** → se usará para .
4. Anótalas temporalmente (necesitarás `omniroute-` en el Paso 3 del README principal y `omniroute-opencode` en el Paso 4).

### Paso 4 · Agregar los proveedores con tus 45 API keys

Ve a **Providers → Add Provider** (o **Connections**). Agrega UN proveedor por plataforma y dentro de él TODAS tus cuentas como **conexiones**:

| Proveedor | Conexiones que agregar | Cómo generar cada key |
|---|---|---|
| **Gemini** | 15 (una por email) | https://aistudio.google.com/apikey |
| **Groq** | 15 | https://console.groq.com/keys |
| **Mistral** | 15 | https://console.mistral.ai/api-keys |

> ⚠️ **NO uses OpenRouter, Cerebras ni NVIDIA.** Todos fallaron en 2026: OpenRouter da **crédito único ~$1** que se agota y NO se renueva; Cerebras pide **tarjeta** (`payment_required`); NVIDIA pide **contactar soporte**. Mistral es el reemplazo correcto: ~1B tokens/mes renovables y sin tarjeta. Detalles en [troubleshooting.md](../docs/troubleshooting.md).

El proceso por cada proveedor:
1. Busca el proveedor en el catálogo (`gemini`, `groq`, `mistral`).
2. En **API Key / Connection**, pega las keys de cada cuenta como entradas separadas (p. ej. `Cuenta 01`, `Cuenta 02`, …, `Cuenta 15`).
3. Guarda y espera a que OmniRoute haga una **prueba de salud** a cada una.

> 💡 **Por qué funciona la "IA infinita":** OmniRoute monitoriza la **cuota diaria de cada conexión**. Si la cuenta 1 se agota, hace cooldown de esa conexión y pasa a la 2, 3… Al día siguiente, cuando se renueva la cuota, la **rotación vuelve a partir de la cuenta 1 automáticamente**. Esto es nativo del gateway: no necesitas scripts ni rotadores manuales.

> 📊 En **Providers → Usage/Quota** ves el saldo estimado y el contador de renove de cada una de las 45 conexiones.

### Paso 5 · Crear los 3 combos

Ve a **Combos → New Combo** y crea 3. Cada combo es una **lista ordenada de modelos**: OmniRoute intenta el primero y si falla (cuota, error, lentitud) cae al siguiente.

**Flujo del builder por cada combo:**
1. **Combo Name** = exactamente `combo-bajo` / `combo-medio` / `combo-avanzado` (ese es el ID que usarán /OpenCode).
2. **Estrategia (Strategy)** = **`Priority`** ("Sequential fallback: tries model 1 first, then 2, etc."). Evita hoy `Round Robin` (reparte en círculo, no hay respaldo real) y `Fill First` (es a nivel de cuentas, se usa en Settings → Routing).
3. Agrega los modelos **en ese orden** uno a uno con **Add model**, tecleando `provider/model`.
4. **Review**: es solo una pantalla de confirmación. Verifica Nombre + Strategy + orden de pasos, **déjalo todo por defecto** y guarda.

> Los modelos listados abajo **fueron creados y verificados** en esta instalación (agosto 2026). Estrategia de los 3: `priority`, cada modelo anclado a la única cuenta del proveedor disponible (al agregar las otras 14 cuentas, la rotación las distribuye sola).

#### 🟢 Combo `bajo` — tareas simples, chat, respuestas rápidas
| # | Modelo | Proveedor |
|---|---|---|
| 1 | `gemini/gemini-2.5-flash-lite` | Gemini |
| 2 | `groq/openai/gpt-oss-20b` | Groq |
| 3 | `mistral/mistral-small-2603` | Mistral |

#### 🟡 Combo `medio` — desarrollo ligero (por defecto de )
| # | Modelo | Proveedor |
|---|---|---|
| 1 | `gemini/gemini-3.6-flash` | Gemini |
| 2 | `groq/openai/gpt-oss-120b` | Groq |
| 3 | `mistral/mistral-medium-2604` | Mistral |

#### 🔴 Combo `avanzado` — desarrollo complejo, razonamiento profundo
| # | Modelo | Proveedor |
|---|---|---|
| 1 | `gemini/gemini-3.7-flash` | Gemini |
| 2 | `mistral/mistral-large-2512` | Mistral |
| 3 | `mistral/codestral-2508` | Mistral |
| 4 | `mistral/devstral-2512` | Mistral |

**Contexto efectivo de cada combo** (verificado vía `/v1/models`): `combo-bajo` = 128K · `combo-medio` = 128K · `combo-avanzado` = 256K.
> ℹ️ Nota: el contexto efectivo de un combo es el **mínimo común** de los modelos que lo forman. Por eso conviene que los modelos de un combo tengan límites de contexto y de salida similares.

> ℹ️ **Modelos Mistral:** `codestral-2508` y `devstral-2512` son los modelos **dedicados a código** de Mistral (ideales para desarrollo/agentes), y `mistral-medium-2604` / `mistral-large-2512` son generalistas potentes. Son comparables o superiores, en tareas de código, a `DeepSeek V4 Flash`.

> ⚠️ **Los planes gratuitos de 2026 cambian.** Si un modelo empieza a fallar o desaparece (Gemini/Groq/Mistral), consúltalo: [troubleshooting.md](../docs/troubleshooting.md) → "Modelo retirado de la capa gratuita".

Los IDs de los combos que usarán /OpenCode serán (en  se ven como `openai/combo-*`):
```
combo-bajo, combo-medio, combo-avanzado
```

### Paso 6 · Activar la compresión de contexto (ahorra tokens)

Era tu "aplanar contexto": ayuda a gastar menos tokens y alarga la cuota diaria al **resumir/compactar** el contenido de sesiones de agentes y herramientas.

1. Ve a **Dashboard → Context → Engine Grid** (el panel de motores; `/dashboard/context/settings`).
2. Activa el **interruptor maestro (ON)** de Compression.
3. Activa el motor **RTK** → nivel **`Aggressive`** (ahorro máximo).
4. Activa el motor **Caveman** → nivel **`Ultra`** (ahorro máximo).
5. Automáticamente se arma el **pipeline "stacked"** RTK + Caveman en el orden correcto (verás el preview).
6. **Auto-trigger threshold**: déjalo en **`0`** (desactivado).

> 💡 **¿Por qué `0`?** El auto-trigger solo comprime cuando el contexto supera ese umbral y, además, usa el modo `lite` (más suave). Como RTK + Caveman **ya comprimen SIEMPRE** al máximo con el master ON, dejarlo en `0` evita duplicar compresión. Active "auto-trigger > 0" solo si quieres que ciertas peticiones enormes se compriman con un modo extra.

7. **Preserve system prompt** = deja el **ON** por defecto (protege las instrucciones del agente).
8. Resto de motores (session-dedup, ccr, headroom, llmlingua, ultra, aggressive, codex-responses, omniglyph): **déjalos OFF** al inicio. Guarda.

> 🔒 **Caveman protege el código por diseño:** aunque no configures `preservePatterns`, Caveman trae patrones **built-in** obligatorios que protegen bloques de código, rutas de archivos, URLs, variables de entorno y mensajes de error. Perfecto para /OpenCode.

> ⚠️ **Si notas respuestas raras** (texto machacado): baja RTK a `standard` y Caveman a `full`. Si todo va bien, déjalo al máximo.

> 📊 **Cómo verificar que está activo:** en el código interno, el estado se guarda como `enabled=true`, RTK=`aggressive`, Caveman=`ultra`. Un indicador visible es que los `<context>` de tus requests se ven más compactos en **Analytics → Compression**.

---

## ✅ Verificación rápida

```bash
# 1. El gateway responde (espera 401 sin key = correcto)
curl -s http://localhost:20128/v1/models -H "Authorization: Bearer tu-api-key"

# 2. Pruébalo con un modelo
curl http://localhost:20128/v1/chat/completions \
  -H "Authorization: Bearer tu-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"combo-medio","messages":[{"role":"user","content":"Hola, responde OK"}]}'
```

---

## 🔄 Mantenimiento

```bash
# Logs
docker logs -f omniroute-gateway

# Reiniciar
docker compose restart

# Actualizar a la última versión
docker compose pull && docker compose up -d

# Detener TODO (sin borrar datos)
docker compose down

# ⚠️ Borrar TODOS los datos (contraseña, keys, combos) — irrecuperable
docker compose down -v
```

---

## ❓ Preguntas frecuentes

- **¿Por qué devuelve 401 ahora?** Porque activaste `REQUIRE_API_KEY` (Paso 2). Es lo correcto: toda petición debe ir con `Authorization: Bearer sk-...`.
- **¿Dónde pego mis 45 keys?** En **Providers**, nunca en archivos. OmniRoute las guarda cifradas en su volumen.
- **¿La rotación es tan automática como dices?** Sí: probado en la documentación oficial (circuit breaker por proveedor, cooldown por conexión, lockout por modelo y estrategia `reset-aware` para renovaciones diarias).
- **¿Puedo conectar otros programas?** Sí, cualquier cosa que hable OpenAI: apunta a `http://localhost:20128/v1`.