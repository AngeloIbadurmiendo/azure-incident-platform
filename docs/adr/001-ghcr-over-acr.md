# ADR-001: Usar GHCR en lugar de Azure Container Registry (ACR)

- **Estado:** Aceptada
- **Contexto:** La API se despliega como contenedor en Azure Container Apps y se construye desde GitHub Actions. Necesitamos un registro de imágenes con bajo costo operativo.
- **Decisión:** Publicar las imágenes en **GitHub Container Registry (GHCR)** como paquete público, etiquetadas con el commit SHA (`ghcr.io/angeloibadurmiendo/azure-incident-platform:<sha>`) usando `GITHUB_TOKEN` en `deploy.yml`.
- **Consecuencias:**
  - **Pros:** Costo $0 (ACR Basic cuesta ~$5 USD/mes), integración nativa con GitHub Actions sin credenciales adicionales y pull sin secretos desde Container Apps.
  - **Contras / Trade-off:** La imagen es pública. En un entorno productivo con código propietario se usaría ACR privado con `AcrPull` mediante Managed Identity.
