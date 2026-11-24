# ADR-004: Regla `allow_azure_services` en PostgreSQL en lugar de red privada

- **Estado:** Aceptada
- **Contexto:** `ca-incidents-api-dev` necesita conectarse a `psql-incidents-dev-ai01` sobre TLS (`sslmode=require`). Integrar VNet + Private Endpoint/Delegated Subnet añade complejidad y costos fijos de red.
- **Decisión:** Habilitar la regla de firewall `allow_azure_services` (`0.0.0.0` – `0.0.0.0`) junto con `sslmode=require` y contraseña aleatoria de 32 caracteres generada por Terraform (`random_password`), guardada como secreto en la Container App.
- **Consecuencias:**
  - **Pros:** Configuración simple, sin costos de Private Endpoint/NAT Gateway y tráfico cifrado en tránsito.
  - **Contras / Trade-off:** `0.0.0.0` permite intentos de conexión desde cualquier servicio alojado en Azure (no solo esta suscripción), confiando en las credenciales y TLS. En producción se reemplazaría por VNet Integration + Private Endpoint o autenticación con Microsoft Entra ID (sin contraseña).
