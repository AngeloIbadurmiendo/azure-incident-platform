# ADR-003: Container Apps con scale-to-zero y PostgreSQL Burstable

- **Estado:** Aceptada
- **Contexto:** Es un proyecto personal con presupuesto acotado y tráfico intermitente, respaldado por una alerta de presupuesto mensual creada antes que el resto de los recursos.
- **Decisión:** Configurar Container Apps con `min_replicas = 0`, `max_replicas = 2`, `0.25 vCPU` / `0.5Gi` RAM, y PostgreSQL Flexible Server en SKU `B_Standard_B1ms` (32 GiB), deteniendo la BD fuera de sesiones de trabajo.
- **Consecuencias:**
  - **Pros:** Container Apps opera dentro de la capa gratuita sin tráfico y PostgreSQL minimiza el gasto mensual.
  - **Contras / Trade-off:** El primer request tras inactividad sufre *cold start* (unos segundos). Como se observó en el [postmortem](../postmortem.md), `min_replicas = 0` también oculta fallos de arranque a las alertas internas si no existe un ping externo. En producción crítica se usaría `min_replicas >= 1` y un SKU de BD con alta disponibilidad.
