# ADR-002: Autenticación de CI/CD con User-Assigned Managed Identity y OIDC

- **Estado:** Aceptada
- **Contexto:** `deploy.yml` necesita autenticarse en Azure para actualizar la Container App. Se busca evitar contraseñas (`client_secret`) de larga duración y, además, el tenant institucional restringe la creación de App Registrations en Microsoft Entra ID.
- **Decisión:** Crear una **User-Assigned Managed Identity** (`id-incidents-deploy-dev`) dentro de `rg-incidents-dev` con una credencial federada **OIDC** restringida al repositorio y al GitHub Environment `dev` (protegido solo para la rama `main`), y asignarle el rol `Contributor` únicamente sobre `rg-incidents-dev`.
- **Consecuencias:**
  - **Pros:** Costo $0, cero secretos que rotar o filtrar, principio de mínimo privilegio (acceso limitado al Resource Group) y compatible con tenants institucionales sin permisos de administrador de Entra ID.
  - **Contras / Trade-off:** La identidad se gestiona fuera de Terraform para separar el ciclo de vida del pipeline de `terraform destroy` de la infraestructura de la app.
