# Runbook — azure-incident-platform

Guía operativa rápida para diagnosticar y mitigar alertas del servicio **Incident API** en Azure.

## Recursos del servicio

| Componente | Recurso en Azure |
|---|---|
| Resource Group | `rg-incidents-dev` (`centralus`) |
| API (Container App) | `ca-incidents-api-dev` |
| Base de datos (PostgreSQL 16) | `psql-incidents-dev-ai01` (BD: `incidents`) |
| Telemetría (APM) | `appi-incidents-dev` (Application Insights) |
| Logs centralizados | `log-incidents-dev` (Log Analytics) |
| Alertas / Notificaciones | `ag-incidents-dev` (Action Group) |

## Triage inicial (2 minutos)

```bash
# 1. Verificar salud HTTP y acceso a BD
API_URL=$(az containerapp show -n ca-incidents-api-dev -g rg-incidents-dev --query properties.configuration.ingress.fqdn -o tsv)
curl -i "https://$API_URL/health"
curl -i "https://$API_URL/incidents"

# 2. Verificar estado de PostgreSQL
az postgres flexible-server show -g rg-incidents-dev -n psql-incidents-dev-ai01 --query state -o tsv

# 3. Ver últimos logs del contenedor
az containerapp logs show -n ca-incidents-api-dev -g rg-incidents-dev --tail 30
```

## Procedimiento por alerta

### 1. `ma-incidents-failed-request-dev` (Sev 1 — Requests fallidos ≥ 3 en 5 min)
1. Abrir **Application Insights (`appi-incidents-dev`) → Failures** y revisar la excepción predominante.
2. **Si el error es de conexión a PostgreSQL (`psycopg` / timeout):**
   - Revisar el estado del servidor (`az postgres flexible-server show ... --query state`).
   - Si está `Stopped`, iniciar el servidor:
     ```bash
     az postgres flexible-server start -g rg-incidents-dev -n psql-incidents-dev-ai01
     ```
   - Si está `Ready`, verificar la regla de firewall `allow_azure_services` y el secreto `database-url` en la Container App.
3. **Si el error comenzó tras un despliegue reciente:** ejecutar rollback (ver sección final).

### 2. `ma-incidents-high-latency-dev` (Sev 2 — Latencia promedio ≥ 1000 ms en 5 min)
1. Abrir **Application Insights (`appi-incidents-dev`) → Performance** y distinguir si el tiempo se consume en:
   - **Dependencia PostgreSQL:** indica BD detenida (timeout TCP ~13 s), saturación de CPU/conexiones o queries lentas. Revisar métricas de `psql-incidents-dev-ai01`.
   - **Código de la API / arranque en frío:** verificar en `ca-incidents-api-dev → Revisions and replicas` si hubo *cold start* desde `0` réplicas.

### 3. `ma-incidents-container-restart-dev` (Sev 1 — Reinicios ≥ 2 en 5 min)
1. Revisar logs de consola y sistema:
   ```bash
   az containerapp logs show -n ca-incidents-api-dev -g rg-incidents-dev --type console --tail 50
   az containerapp logs show -n ca-incidents-api-dev -g rg-incidents-dev --type system --tail 30
   ```
2. Causas habituales:
   - Fallo en `lifespan` al arrancar (`Base.metadata.create_all` sin conexión a PostgreSQL → `503 App port is not ready`).
   - Fallo repetido de `liveness_probe` (`GET /health` en puerto `8000`) o límite de memoria (`0.5Gi`).
3. Si el crash comenzó tras un merge reciente, hacer rollback a la imagen anterior.

## Rollback rápido

```bash
# Listar revisiones anteriores (incluyendo inactivas)
az containerapp revision list -n ca-incidents-api-dev -g rg-incidents-dev --all -o table

# Re-desplegar un tag SHA estable anterior desde GHCR
az containerapp update \
  -n ca-incidents-api-dev \
  -g rg-incidents-dev \
  --image ghcr.io/angeloibadurmiendo/azure-incident-platform:<SHA_ESTABLE>
```

## Verificación de recuperación

- `GET /health` responde `200 OK` y `GET /incidents` responde `200 OK`.
- Las alertas en **Azure Monitor → Alerts** cambian a estado **Resolved**.
