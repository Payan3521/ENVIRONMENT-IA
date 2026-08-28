# ✅ TODO — Lo que falta por hacer

Estado verificado en vivo (contenedores `healthy`): OmniRoute `:20128` ✅ ·  `:18789` ✅ · OpenCode v1.18.23 instalado ✅.

---

## A · Agregar las 42 API keys restantes (14 cuentas × 3 proveedores)

**Situación actual (verificada en la DB de OmniRoute):** solo hay **3 conexiones** de las 45:

| Proveedor | Conexiones existentes | Faltan |
|---|---|---|
| Gemini | `gemini-cuenta-01` | 14 (cuenta-02 → cuenta-15) |
| Groq | `grop-cuenta-01` | 14 |
| Mistral | `mistral-cuenta-01` | 14 |

**Qué hacer:**
1. Ordena tus 45 keys en `docs/credenciales.md` (plantilla ya lista).
2. Abre **http://localhost:20128** → **Providers**.
3. En cada proveedor (Gemini / Groq / Mistral) pulsa **Add Connection / Add Key** y pega las keys de la cuenta-02 a la cuenta-15 (nombre `gemini-cuenta-02`, etc.).
4. Guarda y espera a que OmniRoute haga la **prueba de salud** de cada una.

> 🚫 NO uses OpenRouter / Cerebras / NVIDIA (descartados, ver `docs/troubleshooting.md` §9d).

---

## B · Configuración final de la rotación

1. Al agregar las 14 cuentas restantes, omniRoute debería repartir la carga **solo** al saturarse una cuenta.
2. **Verificar que ningún modelo quedó "anclado"** a la cuenta 01 (`accountPinned`): en **Providers → [proveedor]**, revisa cada modelo y des-ancla cualquier pin.
3. Haz varias peticiones y mira **Providers → Usage** que se van marcando distintas cuentas (cuenta 01, 02, …).
   → Guía completa en `docs/troubleshooting.md` §9e.

> ⚠️ Con 1 sola cuenta por proveedor la rotación no tiene a dónde ir: cualquier pico satura el combo (es lo que provocaba `421/429`). Al completar el Paso A esto se resuelve de raíz.

---

## C · OpenCode (Paso 4) — conectar a OmniRoute

**Situación actual (verificada):**
- ✅ OpenCode instalado (v1.18.23).
- ⚠️ Ya existe un provider `omniroute` en `~/.config/opencode/opencode.json`, pero con la **key VIEJA** `sk-2c64...` (la del 401, superada).
- ⚠️ Solo existe la API key **`omniroute-`** en OmniRoute. **Falta crear `omniroute-opencode`** (hoy no existe en la DB).
- ⚠️ `opencode/.env` también lleva la key vieja.
- ⚠️ `connect-omniroute-credentials.bash` todavía **no se ha ejecutado** (no hay vars en `~/.bashrc`).

**Qué hacer (en orden):**
1. En el dashboard de OmniRoute (**Dashboard → API Keys**) crea una key nueva **`omniroute-opencode`** y cópiala.
2. Actualiza `opencode/.env` → pon `OMNIROUTE_API_KEY="sk-...de omniroute-opencode"`.
3. Actualiza `~/.config/opencode/opencode.json` → en el provider `omniroute`, cambia `apiKey` por la key nueva (deja `baseURL: http://localhost:20128/v1` y los modelos `combo-*`).
4. (Opcional) ejecuta `./connect-omniroute-credentials.bash` dentro de `opencode/` para inyectar `OPENAI_BASE_URL` + `OPENAI_API_KEY` en `~/.bashrc`, y luego `source ~/.bashrc`.
5. (Opcional) revisar el **plugin oficial de OmniRoute** para que descubra los combos automáticamente en el selector de modelos.

---

## D · Verificación final end-to-end (cuando esté todo)

```bash
# 1. Chequeo de contenedores
docker ps | grep -E "omniroute|"

# 2. Prueba de un combo vía la API de OmniRoute
curl http://localhost:20128/v1/chat/completions \
  -H "Authorization: Bearer <tu-key>" -H "Content-Type: application/json" \
  -d '{"model":"combo-medio","messages":[{"role":"user","content":"Hola"}],"max_tokens":2048}'

# 3. Chat en 
#     http://localhost:18789  → debe responder usando OmniRoute

# 4. OpenCode
opencode
#     abrir un chat y confirmar que usa el provider "omniroute" (modelo combo-*)
```

- [ ] 3 proveedores × 15 cuentas = 45 keys en OmniRoute → **Providers**
- [ ] Rotación reparte entre cuentas (sin `accountPinned`) → §9e
- [ ] API key `omniroute-opencode` creada en OmniRoute
- [ ] `opencode/.env` + `~/.config/opencode/opencode.json` con la key nueva
- [ ] Los 3 combos responden + chat en  y OpenCode funcionan

---

## 📌 Nota de seguridad (¡importante!)

Cuando **llenes** `docs/credenciales.md` con tus keys reales:
1. `git rm --cached docs/credenciales.md`
2. Añade `docs/credenciales.md` a `.gitignore`
3. Hazlo **antes** de pegar las keys, para que nunca queden rastreadas.
