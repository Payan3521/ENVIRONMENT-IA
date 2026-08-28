# 🛠️ Troubleshooting — errores comunes y soluciones

Guía práctica de los errores típicos del ecosistema y cómo resolverlos.

---

## 1. Error `EACCES` al arrancar 

**Síntoma:** el contenedor se reinicia en bucle y en los logs aparece `EACCES: permission denied`.

**Causa:** las carpetas `config/` y `workspace/` pertenecen a root, pero el contenedor corre como usuario `node` (UID `1000`).

**Solución:**
```bash
cd 
sudo chown -R 1000:1000 config workspace
docker compose restart
```
> El `/install.sh` ya lo hace automáticamente la primera vez.

---

## 2. Error de `max_tokens` / "output tokens" / respuestas cortadas

**Síntoma:** pides usar un modelo y OmniRoute devuelve un error tipo *"model must support max_tokens"*, *"option not supported"* o el texto se corta a los 2048/4096 tokens.

**Causa:** cada modelo tiene un **límite de salida**. OmniRoute, al agrupar modelos en un combo, usa el **mínimo común denominador (LCD)** de esos límites. Si pides `max_tokens=128000` y en tu combo hay un modelo de 2K, OmniRoute descarta ese modelo → error.

**Soluciones (en orden de prioridad):**
1. **Usa combo IDs, no IDs de modelos crudos.** Pídele a /OpenCode `model: combo-medio` (OmniRoute aplica sus propias reglas).
2. **Ajusta `max_tokens` a valores seguros:** **4096** es seguro para casi todos los modelos gratuitos; 8192 para casi todos los de Gemini/Groq:
   ```env
   # /.env o configuración del cliente
   MAX_TOKENS=4096
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
5. Para encontrar modelos gratuitos nuevos, revisa: Gemini (aistudio), Groq (console), Mistral (console). **Evita OpenRouter** salvo emergencia (ver [Planes free de 2026](#11-planes-free-en-2026--qué-usar-y-qué-evitar)).

---

## 4. OmniRoute devuelve `401 Unauthorized`

**Síntoma:** al llamar `/v1/...` te llega `401`.

**Causa (esperada):** activaste `REQUIRE_API_KEY`. Toda petición debe llevar el header:
```bash
-H "Authorization: Bearer sk-tu-api-key"
```

**Solución:** verifica que la key existe en el dashboard de OmniRoute y que la copias completa. Si sigue fallando, crea una key nueva y actualízala en el cliente ( `.env` + `.json`, u OpenCode).

---

## 4b. `401 Invalid API key` — pero solo desde  (key vieja en caché)

**Síntoma:** OmniRoute responde `200` si pruebas la key a mano con `curl`, pero  devuelve `401 Invalid API key` en la web del agente.

**Causa:** el contenedor  seguía con la **`OPENAI_API_KEY` vieja en caché** (memoria de proceso). Cambiaste la key en el `.env`, pero `docker compose restart` **no** recrea el contenedor ni re-lee el `.env` cambiado.

**Solución (recrear, no solo reiniciar):**
```bash
# 1. Pon la key correcta en /.env
# 2. Recrea el contenedor (SÍ recarga env_file)
docker compose -f /docker-compose.yml up -d --force-recreate
# 3. Verifica que tomó la key nueva
docker exec --gateway-1 sh -c 'echo $OPENAI_API_KEY'
# 4. Y que .json tiene la misma key
docker exec --gateway-1 cat /home/node/./.json
```
Ambas (env y json) deben tener la **misma** key. Tras esto, prueba en http://localhost:18789 → debería responder.

---

## 4c. `WorkspaceVanishedError` en 

**Síntoma:** al iniciar o al chatear en la web del agente, sale:
```
WorkspaceVanishedError:  workspace appears to have disappeared after a recent
initialization: /home/node/./workspace. Refusing to reseed BOOTSTRAP.md over a
recently attested workspace. Restore the workspace or remove
/home/node/./workspace-attestations/<hash>.attested if this reset was intentional.
```

**Causa:** una **attestación** (`workspace-attestations/*.attested`) certifica que el workspace ya se inicializó (con `BOOTSTRAP.md`), pero el workspace quedó **vacío** (p. ej. al recrear el contenedor o montar de nuevo la carpeta `workspace`).  se auto-protege y **no quiere reseedear** un workspace que "desapareció" sin permiso.

**Solución (segura, no borra datos):** borra solo la attestación huérfana desde dentro del contenedor:
```bash
docker exec --gateway-1 rm -f /home/node/./workspace-attestations/*.attested
docker exec --gateway-1 sh -c 'ls /home/node/./workspace'
```
Después reinicia con `docker compose -f /docker-compose.yml restart`.  re-creará el `BOOTSTRAP.md` y seguirá. Tu estado/agentes/skills (en `state/` y `agents/`) no se tocan.

---

## 5. Crash loop de  (InvalidConfigError)

**Síntoma:** el contenedor  se reinicia y en logs dice `InvalidConfigError` y algo sobre modelos.

**Causa:** el `.json` tenía modelos con formato inválido (schema incorrecto) o un `max_tokens` fuera de rango.

**Solución:**
1. Sustituye tu `.json` por la plantilla del repo:
   ```bash
   cp /config/.json.example /config/.json
   ```
2. Asegúrate de que `apiKey` y `baseUrl` apunten a OmniRoute correctamente.
3. `docker compose -f /docker-compose.yml restart`
4. Si hay un "crash loop breaker" activo, espera ~5 minutos o:
   ```bash
   docker compose -f /docker-compose.yml --force-recreate up -d
   ```

---

## 6. `host.docker.internal` no resuelve

**Síntoma:**  no llega a OmniRoute y en logs se ve `ENOTFOUND host.docker.internal`.

**Causa:** en algunos Linux el alias se resuelve vía la entrada `extra_hosts` del compose (que **ya está incluida**). Si borraste esa línea o usas otro runner/podman, falla.

**Solución:**
- Verifica que tu `/docker-compose.yml` tenga:
  ```yaml
  extra_hosts:
    - "host.docker.internal:host-gateway"
  ```
- Verifica que OmniRoute esté vivo: `docker logs omniroute-gateway`
- Como respaldo puedes cambiar el endpoint `.env` a la IP real del host (p. ej. `http://192.168.1.10:20128/v1`).

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
- **`413`** (Groq "request too large... TPM limit"): el cliente pidió demasiados tokens de salida → limita el `maxTokens` en `/config/.json` (ver §Configuración ). Ya hecho: `4096–8192`.
- **`402`** (Mistral "insufficient credits / can only afford X tokens"): la cuenta Mistral se agotó → añade más cuentas Mistral (cada cuenta free tiene ~1B tokens/mes y se renueva sola).
- **`504`** (Gemini "maxWaitMs=15000"): la única cuenta Gemini se congestiona y OmniRoute aborta en 15s → **YA RESUELTO**: subimos `requestQueue.maxWaitMs` a `120000` ms. Para un equipo nuevo, la ruta correcta es **Settings → Resilience → Request Queue → Max Queue Wait** (NO está en Routing). Más abajo en la §9c.

**Solución de raíz:** añadir las otras 14 cuentas (42 keys) en Providers para que la rotación reparta la carga. Con 1 cuenta por proveedor, cualquier pico satura el combo completo.

---

## 9c. `504` de Gemini / `maxWaitMs` (timeout de la cola de OmniRoute)

**Síntoma:** una petición a Gemini responde `504` o tarda y luego falla; en logs aparece `requestQueue.maxWaitMs=15000ms`.

**Causa:** el **límite de espera de la cola** de OmniRoute estaba en 15s. Con una sola cuenta Gemini congestionada (o un modelo de Mistral que tarda ~40s en responder, como `mistral-large-2512`), OmniRoute **abortaba antes** de que el proveedor terminara.

**Solución (ya aplicada: 120000):**
1. Abre **http://localhost:20128**.
2. Ve a **Settings → Resilience** (URL directa: **`/dashboard/settings/resilience`**). ⚠️ La tarjeta **Max Queue Wait** está en **Request Queue**, **no** en Routing.
3. Súbelo a **`120000`** ms (2 minutos) y guarda.
4. Verificado en base de datos: `resilienceSettings.requestQueue.maxWaitMs = 120000`.

> 💡 Si la respuesta tarda pero **no** sale error, es normal: con 1 cuenta por proveedor todo espera en cola. Se arregla de raíz añadiendo las 14 cuentas restantes.

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

Cuando ya hayas añadido las 14 cuentas restantes de cada proveedor, comprueba que **ningún modelo quedó "pegado"** a una sola cuenta:

1. Abre **http://localhost:20128** → **Providers** → selecciona cada proveedor.
2. Revisa si algún modelo aparece como **`accountPinned`** (fijado) a la cuenta 01 — si lo está, la rotación no repartirá carga entre las 15.
3. En ese caso, des-ancla el modelo / borra el pin en el editor del modelo para que OmniRoute elija cuenta libre según cuota.
4. Haz varias peticiones y observa en **Providers → Usage** que se van marcando distintas cuentas (Cuenta 01, 02, …) según se satura la anterior.

---

## 10. Quiero reiniciar TODO de cero

```bash
docker compose -f omniroute/docker-compose.yml down -v   # borra config de OmniRoute
docker compose -f /docker-compose.yml down       # detiene 
rm -rf /config /workspace                # borrar datos del agente
./install.sh all
```

---

## 📌 Checklist cuando algo no funciona

- [ ] ¿OmniRoute está vivo? → `docker ps | grep omniroute`
- [ ] ¿ está vivo? → `docker ps | grep `
- [ ] ¿Las 2 keys de OmniRoute existen y están copiadas bien?
- [ ] ¿Los 3 proveedores con las 45 keys creados en OmniRoute? (Gemini + Groq + Mistral)
- [ ] ¿Los 3 combos creados? (¿el modelo del combo 1 sigue activo en su proveedor?)
- [ ] ¿Los `.env` apuntan al endpoint correcto (`:20128/v1`)?
- [ ] ¿Los permisos de `config/` y `workspace/` son UID `1000`?
- [ ] ¿Los `max_tokens` ≤ 4096 en clientes problemáticos?