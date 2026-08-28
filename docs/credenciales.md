# 🔐 Registro de Credenciales — ENVIRONMENT-IA

> ⚠️ **IMPORTANTE DE SEGURIDAD**
> Este archivo es tu **registro personal** de API keys. La plantilla (así vacía) es seguro compartirla,
> porque no lleva ningún dato — PERO en cuanto pegues tus keys reales **deja de compartirse**:
> añádelo a `.gitignore` para que tus credenciales nunca suban al repositorio, o mantén una copia local
> fuera del proyecto (ej. `/home/tu-usuario/Documentos/credenciales-IA.md`).

---

## 📌 Cómo funcionan las cuentas

El ecosistema usa **15 cuentas de correo × 3 proveedores = 45 API keys**.

| Proveedor | Cuántas | Plan gratis | ¿Renovable? | Dónde generar cada key |
|---|---|---|---|---|
| **Gemini** | 15 | 5–15 RPM, 250K TPM | ✅ Por minuto/día | https://aistudio.google.com/apikey |
| **Groq** | 15 | ~30 RPM (free reducida a 1K req/día en 2026) | ✅ Por minuto/día | https://console.groq.com/keys |
| **Mistral** | 15 | ~1B tokens/mes (free "Experiment") | ✅ Mensual | https://console.mistral.ai/api-keys |

> 🚫 **NO usar**: **OpenRouter** (crédito único ~$1, se agota y NO se renueva) · **Cerebras** (pide tarjeta: `payment_required`) · **NVIDIA NIM** (pide contactar soporte). Ver [troubleshooting.md](troubleshooting.md).

---

## 📋 Tabla de cuentas y API keys (45)

> Rellena cada casilla con la key que generaste. Los **emails** ayudan a recordar qué cuenta es cuál.

| # | Email de la cuenta | Gemini key | Groq key | Mistral key | Estado |
|---|---|---|---|---|---|
| 01 | `01omniroute@gmail.com` |  |  |  | ✅ agregada |
| 02 | `freefire33445112@gmail.com` |  |  |  | ✅ agregada |
| 03 | `jhonatanbrinez62@gmail.com` |  |  |  | ✅ agregada |
| 04 | `sospetseam@gmail.com` |  |  |  | ✅ agregada |
| 05 | `antigravitypayan@gmail.com` |  |  |  | ✅ agregada |
| 06 | `06omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 07 | `07omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 08 | `08omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 09 | `09omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 10 | `10omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 11 | `11omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 12 | `12omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 13 | `13omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 14 | `14omniroute@gmail.com` |  |  |  | ⬜ pendiente |
| 15 | `15omniroute@gmail.com` |  |  |  | ⬜ pendiente |

> ✅ **5 de 15 cuentas agregadas.** Cuando llenes las 10 restantes (cuenta-06 a 15), OmniRoute **rota solo** entre las 15 cuentas de cada proveedor: ya está configurado en "AUTO", no hay que tocar los combos.

---

## 🔑 Claves propias del ecosistema (NO son de proveedor)

| Clave | Para qué sirve | Valor |
|---|---|---|
| **Contraseña maestra OmniRoute** (dashboard) | Entrar a `http://localhost:20128` | `________` |
| **API key OmniRoute · ** | Autenticar al agente contra el gateway | `sk-...` |
| **API key OmniRoute · OpenCode** | Autenticar al CLI contra el gateway (Paso 4) | `sk-...` |
| **Token gateway ** | Entrar a la web del agente `http://localhost:18789` | `________` |

> 🔑 **API keys de OmniRoute** (las de /OpenCode) se crean en **Dashboard → API Keys** del propio OmniRoute, NO se generan en una web externa.

---

## 🧮 Resumen de qué va en qué archivo

```
ENVIRONMENT-IA/
├── omniroute/            ← Proveedores + combos → se configuran en la WEB (localhost:20128)
├── /
│   ├── .env              ← key  + BASE_URL + token gateway   (NO se sube)
│   └── config/.json  ← baseUrl + key + combos (modelos)       (NO se sube)
└── opencode/
    └── .env              ← key OPENCODE + BASE_URL                    (NO se sube)
```

> ⚠️ Las API keys de **proveedor** (Gemini/Groq/Mistral) se cargan SOLO en OmniRoute → **Providers**.
> No van en ningún archivo del repo. Este documento es solo tu respaldo para tenerlas organizadas.

---

## ✅ Checklist de una instalación nueva

- [ ] Levantar contenedores: `./install.sh`
- [ ] OmniRoute: contraseña maestra → `REQUIRE_API_KEY` → 2 API keys → 3 proveedores → 3 combos → compresión
- [ ] : `.env` + `.json` con la key de OmniRoute
- [ ] Agregar en **Providers** cada una de las 45 keys (15 por proveedor)
- [ ] Dejar los modelos de los combos en **AUTO** (para que roten entre cuentas)
- [ ] Verificar: `curl` de los 3 combos + chat en `localhost:18789`

> **Estado actual de este ecosistema:** 15/45 keys agregadas (5 cuentas × 3 proveedores) y rotación AUTO activa. Faltan solo las 10 cuentas restantes (30 keys).
