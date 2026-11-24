# Postmortem — Caída de base de datos PostgreSQL (Incidente simulado)

| Campo | Detalle |
|---|---|
| **Fecha** | 2026-11-24 |
| **Severidad** | Sev 1 (indisponibilidad de endpoints con persistencia) |
| **Estado** | Resuelto |
| **Servicio afectado** | `ca-incidents-api-dev` / `psql-incidents-dev-ai01` |
| **MTTD (tiempo de detección)** | ~4 minutos (en escenario con réplica activa) |

## Resumen

Se simuló una caída de PostgreSQL deteniendo `psql-incidents-dev-ai01` para validar el monitoreo y las alertas en producción. El ejercicio demostró que la alerta de latencia (`ma-incidents-high-latency-dev`) se disparó correctamente en 4 minutos (latencia promedio de **13,689 ms** por timeouts TCP), y expuso dos brechas reales de observabilidad que fueron corregidas o documentadas: un punto ciego en *scale-to-zero* (`503 App port is not ready`) y una dimensión vacía en Container Apps para la alerta de errores `5xx`.

## Impacto

- **Escenario en frío (0 réplicas):** `GET /incidents` devolvió `503 Service Unavailable` (`{"error":"App port is not ready"}`).
- **Escenario en caliente (réplica activa):** `GET /incidents` devolvió `500 Internal Server Error` (7 requests fallidos registrados en Application Insights, latencia promedio de 13.7 s).

## Línea de tiempo (UTC)

| Hora (UTC) | Evento |
|---|---|
| `17:27:05` | Con PostgreSQL detenido y la Container App en `0` réplicas, se envían requests a `GET /incidents`. Azure responde `503 {"error":"App port is not ready"}`. No se registran métricas en Application Insights ni se dispara alerta. |
| `17:39:41` | Tras encender brevemente la BD para calentar una réplica y volver a detenerla, los requests a `GET /incidents` entran a FastAPI y devuelven `500 Internal Server Error`. |
| `17:42:00` | Application Insights registra `6` requests fallidos (y `1` adicional a las `17:44:00`) con latencia promedio de `13,689 ms`. |
| `17:44:00` | Se dispara la alerta **`ma-incidents-high-latency-dev`** (estado **Fired**) y llega notificación por correo vía `ag-incidents-dev`. |
| `17:47:00` | Se inicia mitigación ejecutando `az postgres flexible-server start`. |
| `17:55:00` | PostgreSQL vuelve a estado `Ready`, `GET /incidents` responde `200 OK` y Azure Monitor envía notificación **Resolved**. |

## Causa raíz

1. **Causa directa:** Detención simulada del servidor `psql-incidents-dev-ai01`.
2. **Agravante en arranque en frío:** `app/main.py` ejecuta `Base.metadata.create_all(bind=engine)` dentro de `lifespan`. Sin acceso a PostgreSQL, `uvicorn` falla antes de abrir el puerto `8000`, impidiendo que el contenedor arranque y que el SDK de OpenTelemetry reporte el fallo.
3. **Alerta silenciosa detectada:** `ma-incidents-failed-request-dev` filtraba `Requests` en Container Apps por `statusCodeCategory = 5xx`, dimensión que no se pobló en el plan Consumption durante el fallo.

## Qué salió bien / Qué salió mal

- **Salió bien:** La cadena completa **FastAPI (`microsoft-opentelemetry`) → Application Insights → Metric Alert → Action Group → Correo** funcionó en 4 minutos, y la recuperación tras iniciar PostgreSQL fue automática sin requerir re-despliegue.
- **Salió mal:** El arranque en frío con BD caída quedó invisible para las alertas internas, y la alerta de `failed_request` no disparó con la configuración inicial sobre Container Apps.

## Acciones preventivas

| Acción | Estado |
|---|---|
| Migrar `ma-incidents-failed-request-dev` a Application Insights (`requests/failed`, `Count >= 3`) en `infra/alerts.tf`. | ✅ Completada |
| Subir `ma-incidents-high-latency-dev` de `Severity 3` (Informational) a `Severity 2` (Warning). | ✅ Completada |
| Agregar un *Standard Availability Test* externo sobre `/health` (y un endpoint de readiness de BD) para detectar `503` en arranque en frío. | 📋 Pendiente |
| Separar migraciones de esquema (Alembic) del `lifespan` de arranque de FastAPI para que el contenedor pueda abrir el puerto y reportar telemetría aunque la BD falle. | 📋 Pendiente |
