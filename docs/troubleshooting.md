# 🛠️ Troubleshooting — errores comunes y soluciones

Guía práctica de los errores típicos del ecosistema y cómo resolverlos.

---

## 2. Error de `max_tokens` / "output tokens" / respuestas cortadas

**Síntoma:** pides usar un modelo y OmniRoute devuelve un error tipo *"model must support max_tokens"*, *"option not supported"* o el texto se corta a los 2048/4096 tokens.

**Causa:** cada modelo tiene un **límite de salida**. OmniRoute, al agrupar modelos en un combo, usa el **mínimo común denominador (LCD)** de esos límites. Si pides `max_tokens=128000` y en tu combo hay un modelo de 2K, OmniRoute descarta ese modelo → error.

**Soluciones (en orden de prioridad):**
1. **Usa combo IDs, no IDs de modelos crudos.** Pídele a OpenCode `model: combo-medio` (OmniRoute aplica sus propias reglas).
2. **Ajusta `max_tokens` a valores seguros:** **4096** es seguro para casi todos los modelos gratuitos; 8192 para casi todos los de Gemini/Groq:
   ```text
   # Configuración: en tu cliente (OpenCode u otro) define model=combo-* 
   # con max_tokens razonables (4096–8192).
   ```
3. Si modificaste el combo, mete modelos **homogéneos** (mismos límites de salida) para no arrastrar el minimizador.
4. Activa la **compresión de contexto** en OmniRoute (Dashboard → Context → Engine Grid): reduce las llamadas grandes y evita los límites.

---

## 3. Modelo retirado / fallo en la capa gratuita (cualquier proveedor)

**Síntoma:** un modelo de un combo empieza a fallar con `502`, `403`, `404`, `429` o "model not found".

**Causa:** los proveedores gratuitos **retiran o cambian modelos sin avisar** (en 2026 pasó con los `:free` de OpenRouter: quitaron Qwen3 Coder y DeepSeek R1), y los nombres de modelos de Gemini/Groq/Mistral cambian a menudo.

**Solución:**
1. Verifica qué falla exactamente: `docker logs --tail 100 omniroute-gateway 2>&1 | grep -iE "model not found|404|403"`.
2. En OmniRoute → **Providers**, comprueba que el modelo siga existiendo (api key válida vs. modelo inexistente).
3. En OmniRoute → **Combos**, edita el combo y sustituye el modelo caído por uno activo del mismo proveedor.
4. Guarda. OmniRoute revalida al siguiente request.
5. Para encontrar modelos gratuitos nuevos, revisa: Gemini (aistudio), Groq (console), Mistral (console). **Evita OpenRouter** salvo emergencia (ver [Planes free de 2026](#9d-planes-gratuitos-en-2026--qué-usar-y-qué-evitar)).

---

## 4. OmniRoute devuelve `401 Unauthorized`

**Síntoma:** al llamar `/v1/...` te llega `401`.

**Causa (esperada):** activaste `REQUIRE_API_KEY`. Toda petición debe llevar el header:
```bash
-H "Authorization: Bearer sk-tu-api-key"
```

**Solución:** verifica que la key existe en el dashboard de OmniRoute y que la copias completa. Si sigue fallando, crea una key nueva y actualízala en el cliente (OpenCode).

---

## 7. El dashboard de OmniRoute no carga

**Pasos:**
1. `docker logs omniroute-gateway` → ¿errores?.
2. Puerto activo: `ss -tlnp | grep 20128`.
3. Reinicia: `docker restart omniroute-gateway`.
4. Último recurso (conservando datos): `docker compose down && docker compose up -d`.
5. ¿Nada? El volumen puede estar corrupto. **Respalda** `docker cp omniroute-gateway:/app/data ./respaldo` y luego `docker compose down -v` + levantar de nuevo (reconfigurarás todo).

---

## 8. "No active credentials for provider"

**Síntoma:** el cliente pide un modelo `provider/x` pero OmniRoute dice que no hay credenciales.

**Causa:** ese provider no se agregó, o la conexión está desactivada/agotada.

**Solución:** ve a OmniRoute → Providers, verifica que el provider exista, tenga keys válidas y esté "conectado". Si usas IDs de combos (recomendado) esto casi no ocurre.

---

## 9. Todo funciona pero las respuestas tardan / se quedan en blanco

**Causa probable:** todos los proveedores de ese combo están en cooldown (cuota agotada) o el modelo de mayor prioridad está lento.

**Solución:**
- Sube temporalmente un combo ("bajo" → "medio") para usar cuota distinta.
- Revisa en OmniRoute → Providers → Usage qué conexiones tienen saldo.
- Revisa la **compresión**: si está al 100% y ves contenido raro, baja el porcentaje.

---

## 9b. "All models are temporarily rate-limited" (421/429)

**Síntoma:** OmniRoute devuelve *"All models are temporarily rate-limited. Please try again in a few minutes."*

**Causa:** tras fallar **todos** los modelos de un combo (413/402/504) en la misma ronda, OmniRoute pone el combo en breve cooldown. Es un síntoma, no la causa: el fondo es escasez de cuentas o peticiones demasiado grandes.

**Cómo diagnosticar** (mira los logs para ver qué falló exactamente):
```bash
docker logs --tail 100 omniroute-gateway 2>&1 | grep -iE "All models|RATE-LIMIT|\[413\]|\[402\]|\[504\]"
```
- **`413`** (Groq "request too large... TPM limit"): el cliente pidió demasiados tokens de salida → limita el `max_tokens` en tu cliente (OpenCode u otro) a `4096–8192`.
- **`402`** (Mistral "insufficient credits / can only afford X tokens"): la cuenta Mistral se agotó → añade más cuentas Mistral (cada cuenta free tiene ~1B tokens/mes y se renueva sola).
- **`504`** (Gemini "maxWaitMs=15000"): la única cuenta Gemini se congestiona y OmniRoute aborta en 15s → **YA RESUELTO**: subimos `requestQueue.maxWaitMs` a `120000` ms. Para un equipo nuevo, la ruta correcta es **Settings → Resilience → Request Queue → Max Queue Wait** (NO está en Routing). Más abajo en la §9c.

**Solución de raíz:** añadir más cuentas en Providers para que la rotación reparta la carga. A partir de varias cuentas por proveedor, cualquier pico ya no satura el combo completo (actualmente 5 por proveedor; objetivo: 15).

---

## 9c. `504` de Gemini / `maxWaitMs` (timeout de la cola de OmniRoute)

**Síntoma:** una petición a Gemini responde `504` o tarda y luego falla; en logs aparece `requestQueue.maxWaitMs=15000ms`.

**Causa:** el **límite de espera de la cola** de OmniRoute estaba en 15s. Con una sola cuenta Gemini congestionada (o un modelo de Mistral que tarda ~40s en responder, como `mistral-large-2512`), OmniRoute **abortaba antes** de que el proveedor terminara.

**Solución (ya aplicada: 120000):**
1. Abre **http://localhost:20128**.
2. Ve a **Settings → Resilience** (URL directa: **`/dashboard/settings/resilience`**). ⚠️ La tarjeta **Max Queue Wait** está en **Request Queue**, **no** en Routing.
3. Súbelo a **`120000`** ms (2 minutos) y guarda.
4. Verificado en base de datos: `resilienceSettings.requestQueue.maxWaitMs = 120000`.

> 💡 Si la respuesta tarda pero **no** sale error, es normal: al arrancar con pocas cuentas todo puede esperar en cola. Se alivia añadiendo más cuentas del proveedor en cuestión (la rotación reparte la carga).

---

## 9d. Planes gratuitos en 2026 — qué usar y qué evitar

Esto lo aprendimos **en esta instalación** probando varios proveedores. **Resumen:**

| Proveedor | Veredicto | Motivo |
|---|---|---|
| ✅ **Gemini** | USAR | Plan free sin tarjeta, cuota renovable por minuto/día. 15 cuentas = mucho margen. |
| ✅ **Groq** | USAR | Plan free renovable por minuto/día (en 2026 la free se redujo a ~1K req/día). |
| ✅ **Mistral** | USAR | **~1B tokens/mes gratis renovable** y sin tarjeta. Incluye modelos de código (Codestral/Devstral). |
| ❌ **OpenRouter** | EVITAR | Da **crédito único ~$1** que se agota y **NO se renueva**. Los `:free` desaparecen sin aviso. |
| ❌ **Cerebras** | EVITAR | Devuelve `payment_required` (pide **tarjeta**). |
| ❌ **NVIDIA NIM** | EVITAR | Pide **contactar soporte** para acceso; no hay free tier directo. |
| ❌ **Together** | EVITAR | "No free tier" en 2026. |
| ⚠️ **SambaNova** | DUDOSO | Free tier permanente, pero hay contradicción sobre si pide tarjeta. Revisar antes de confiar. |

> 🎯 **Conclusión del proyecto:** nuestro objetivo son **15 cuentas × 3 (Gemini + Groq + Mistral) = 45 API keys renovables**, todas sin tarjeta. Esa es la base de la "IA infinita".

---

## 9e. Verificar que la rotación entre cuentas funciona

Cuando hayas añadido todas las cuentas de cada proveedor, comprueba que **ningún modelo quedó "pegado"** a una sola cuenta:

1. Abre **http://localhost:20128** → **Providers** → selecciona cada proveedor.
2. Revisa si algún modelo aparece como **`accountPinned`** (fijado) a la cuenta 01 — si lo está, la rotación no repartirá carga entre las 15.
3. En ese caso, des-ancla el modelo / borra el pin en el editor del modelo para que OmniRoute elija cuenta libre según cuota.
4. Haz varias peticiones y observa en **Providers → Usage** que se van marcando distintas cuentas (Cuenta 01, 02, …) según se satura la anterior.

---

## 10. Quiero reiniciar TODO de cero

```bash
docker compose -f omniroute/docker-compose.yml down -v   # borra config de OmniRoute
./install.sh all
```

---

## 📌 Checklist cuando algo no funciona

- [ ] ¿OmniRoute está vivo? → `docker ps | grep omniroute`
- [ ] ¿La API key de OmniRoute existe y está copiada bien?
- [ ] ¿Los 3 proveedores con las 45 keys creados en OmniRoute? (Gemini + Groq + Mistral)
- [ ] ¿Los 3 combos creados? (¿el modelo del combo 1 sigue activo en su proveedor?)
- [ ] ¿El cliente (OpenCode) apunta a `http://localhost:20128/v1` con su key?
- [ ] ¿Los `max_tokens` ≤ 4096 en clientes problemáticos?