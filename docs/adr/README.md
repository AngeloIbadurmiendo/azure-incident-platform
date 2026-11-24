# Architecture Decision Records (ADRs)

Registro breve de las principales decisiones de arquitectura, seguridad y costos del proyecto.

| ADR | Decisión | Estado |
|---|---|---|
| [ADR-001](001-ghcr-over-acr.md) | Usar GitHub Container Registry (GHCR) en lugar de Azure Container Registry (ACR) | Aceptada |
| [ADR-002](002-managed-identity-oidc.md) | Autenticación de CI/CD con User-Assigned Managed Identity y OIDC | Aceptada |
| [ADR-003](003-scale-to-zero-and-burstable-db.md) | Container Apps con `min_replicas = 0` y PostgreSQL Flexible Server `B_Standard_B1ms` | Aceptada |
| [ADR-004](004-postgres-public-access-azure-services.md) | Regla `allow_azure_services` (`0.0.0.0`) en PostgreSQL en lugar de VNet / Private Endpoint | Aceptada |
