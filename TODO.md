# ✅ TODO — Lo que falta por hacer

Estado verificado en vivo (contenedores `healthy`): OmniRoute `:20128` ✅ ·  `:18789` ✅ · OpenCode v1.18.23 instalado ✅.

---

## ✅ Hecho (avance actual)

- **15/45 API keys agregadas** (5 cuentas × 3 proveedores: Gemini, Groq, Mistral). Una por cuenta, todas `active` en la DB.
- **Rotación ACTIVA:** los 3 combos tienen todos sus modelos en **AUTO** (sin conexión fija), así que OmniRoute reparte entre las cuentas y salta a la siguiente si una falla/se satura. Verificado: una cuenta que falla hace que OmniRoute pruebe otra automáticamente.
- **Combos revisados y probados** (responden `200`):
  - `combo-bajo`: `Gemini 3.5-flash-lite → Mistral Small → Groq GPT-OSS-20B`
  - `combo-medio`: `Gemini 3.6-flash → Groq GPT-OSS-120B → Mistral Medium`
  - `combo-avanzado`: `Gemini 3.7-flash → Codestral → Devstral → Mistral Large` (se bajó `mistral-large` al final por lentitud)
- **`gemini-2.5-flash-lite` sustituido** por `gemini-3.5-flash-lite` (el 1º fue retirado por Google → 404).
- **Documentación actualizada** a la configuración real (combos, rotación, 15 keys).

---

## A · Agregar las 30 API keys restantes (10 cuentas × 3 proveedores) ← LO ÚNICO QUE FALTA EN OMNIROUTE

**Situación actual (verificada en la DB):** 15 cuentas que ya tienes (01 → 05). Faltan **10 cuentas** (06 → 15), es decir **30 keys** (10 Gemini + 10 Groq + 10 Mistral).

**Qué hacer (por cada una de las 10 cuentas nuevas):**
1. Abre **http://localhost:20128** → **Providers**.
2. En cada proveedor (Gemini / Groq / Mistral) pulsa **Add Connection** y pega la key de la cuenta nueva (nombre `gemini-cuenta-06`, `groq-cuenta-06`, `mistral-cuenta-06`, etc.).
3. Guarda y espera a que OmniRoute haga la **prueba de salud** (debe quedar `active`).
4. **No toques los combos:** ya están en AUTO y rotarán solos con las nuevas cuentas.

> 🚫 NO uses OpenRouter / Cerebras / NVIDIA (descartados, ver `docs/troubleshooting.md` §9d).
> 💡 Usa la tabla de `docs/credenciales.md` para llevar la cuenta de cuáles ya agregaste.

---

## B · Verificación final de rotación (cuando agregues las 10 restantes)

1. Haz varias peticiones a un combo y mira en **Providers → Usage** que se van marcando **distintas cuentas** (01, 02, 03, …), no siempre la misma.
2. Confirma que **ningún modelo quedó anclado** (`accountPinned` a una sola cuenta). → Guía en `docs/troubleshooting.md` §9e.

---

## C · Conectar OpenCode (Paso 4) — pendiente

**Situación actual (verificada):**
- ✅ OpenCode instalado (v1.18.23).
- ⚠️ El provider `omniroute` en `~/.config/opencode/opencode.json` tiene la **key VIEJA** `sk-2c64...` (la del 401, superada).
- ⚠️ Solo existe la API key **`omniroute-`** en OmniRoute. **Falta crear `omniroute-opencode`**.
- ⚠️ `opencode/.env` también lleva la key vieja.
- ⚠️ `connect-omniroute-credentials.bash` aún no se ha ejecutado (no hay vars en `~/.bashrc`).

**Qué hacer (en orden):**
1. En **Dashboard → API Keys** crea la key **`omniroute-opencode`** y cópiala.
2. Actualiza `opencode/.env` → `OMNIROUTE_API_KEY="sk-...de omniroute-opencode"`.
3. Actualiza `~/.config/opencode/opencode.json` → en el provider `omniroute`, cambia `apiKey` (deja `baseURL: http://localhost:20128/v1` y los modelos `combo-*`).
4. (Opcional) ejecuta `./connect-omniroute-credentials.bash` dentro de `opencode/` y `source ~/.bashrc`.

---

## D · Conectar Cursor / Antigravity (cualquier cliente OpenAI) — pendiente / opcional

OmniRoute expone `http://localhost:20128/v1` (API compatible con OpenAI), así que **Cursor y Antigravity** se conectan igual:
1. Crea una API key por cliente en **Dashboard → API Keys** (p. ej. `omniroute-cursor`, `omniroute-antigravity`).
2. En el cliente, base URL = `http://localhost:20128/v1` + esa key.
3. Selecciona un modelo `combo-bajo` / `combo-medio` / `combo-avanzado`.
   → Detalles en `omniroute/README.md` → "Usar OmniRoute con Cursor / Antigravity".

---

## E · Verificación final end-to-end (cuando esté todo)

```bash
# 1. Chequeo de contenedores
docker ps | grep -E "omniroute|"

# 2. Prueba de un combo vía la API de OmniRoute
curl http://localhost:20128/v1/chat/completions \
  -H "Authorization: Bearer <tu-key>" -H "Content-Type: application/json" \
  -d '{"model":"combo-medio","messages":[{"role":"user","content":"Hola"}],"max_tokens":2048}'

# 3. Chat en 
#     http://localhost:18789  → debe responder usando OmniRoute

# 4. OpenCode / Cursor / Antigravity
#     abrir un chat y confirmar que usan el proveedor "omniroute" (modelo combo-*)
```

- [ ] 3 proveedores × 15 cuentas = 45 keys en OmniRoute → **Providers**
- [ ] Rotación reparte entre cuentas (sin `accountPinned`) → §9e
- [ ] API key `omniroute-opencode` creada en OmniRoute
- [ ] `opencode/.env` + `~/.config/opencode/opencode.json` con la key nueva
- [ ] Cursor / Antigravity conectados a `:20128/v1`
- [ ] Los 3 combos responden + chat en , OpenCode, Cursor/Antigravity

---

## 📌 Nota de seguridad (¡importante!)

Cuando **llenes** `docs/credenciales.md` con tus keys reales:
1. `git rm --cached docs/credenciales.md`
2. Añade `docs/credenciales.md` a `.gitignore`
3. Hazlo **antes** de pegar las keys, para que nunca queden rastreadas.
