# azure-incident-platform

API de registro de incidentes desplegada en Azure, construida de punta a punta como proyecto de aprendizaje: **código, contenedores, infraestructura como código, CI/CD seguro y monitoreo**, incluyendo un incidente simulado documentado con su runbook y postmortem.

## Qué demuestra este proyecto

| Área | Qué se hace |
|---|---|
| **Backend** | API REST con FastAPI y PostgreSQL, validación de datos y pruebas automáticas |
| **Contenedores** | Imagen Docker ligera, con usuario sin privilegios, y entorno local con Docker Compose |
| **Infraestructura como código** | Todo en Azure se crea y se destruye con Terraform, sin clics en el portal |
| **CI/CD seguro** | GitHub Actions con autenticación OIDC (sin contraseñas guardadas) y escaneo de secretos, código e imágenes |
| **Observabilidad** | Logs y métricas en Application Insights y Log Analytics, con alertas y dashboard |
| **Operación** | Un incidente simulado, resuelto y documentado con runbook y postmortem |
| **Control de costos** | Presupuesto con alertas creado antes que cualquier otro recurso |

## Arquitectura

La API corre como contenedor en Azure Container Apps, guarda sus datos en PostgreSQL y envía logs y telemetría a Application Insights y Log Analytics, donde se evalúan las alertas.

```mermaid
flowchart LR
    user([Cliente]) -->|HTTPS| api

    subgraph azure [Azure - gestionado con Terraform]
        subgraph env [Container Apps Environment]
            api[API FastAPI]
        end
        db[(PostgreSQL)]
        ai[Application Insights]
        law[Log Analytics]
        alerts[Alertas]
    end

    api --> db
    api -. telemetria .-> ai
    env -. logs .-> law
    ai --> law
    law --> alerts
    alerts -->|correo| oncall([Responsable])

    ghcr[(GHCR - imagen Docker)] -->|pull| api
```

## Flujo de CI/CD

```mermaid
flowchart LR
    dev([Desarrollador]) -->|pull request| pr

    subgraph pr [pr.yml - validación]
        direction TB
        t[Pruebas] --> b[Bandit - análisis de código]
        b --> g[Gitleaks - secretos]
        g --> tr[Trivy - imagen y dependencias]
    end

    pr -->|merge a main| deploy

    subgraph deploy [deploy.yml - despliegue]
        direction TB
        bi[Build de la imagen] --> push[Push a GHCR]
        push --> login[Login en Azure con OIDC]
        login --> rel[Actualiza Container App]
    end
```

**OIDC en una línea:** GitHub Actions obtiene un token temporal de Azure por cada ejecución, así que no existen contraseñas ni secretos de larga duración en el repositorio.

## Stack

| Capa | Tecnología |
|---|---|
| API | Python 3.12, FastAPI, SQLAlchemy 2, Pydantic |
| Base de datos | PostgreSQL 16 |
| Contenedores | Docker, Docker Compose |
| Infraestructura | Terraform (provider `azurerm`) |
| Nube | Azure: Container Apps, Log Analytics, Application Insights |
| Registro de imágenes | GitHub Container Registry (GHCR) |
| CI/CD | GitHub Actions con OIDC |
| Seguridad | Gitleaks, Bandit, Trivy |

## API

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/health` | Estado del servicio (usado por las sondas de salud) |
| `POST` | `/incidents` | Registra un incidente (`title`, `description`, `severity`) |
| `GET` | `/incidents` | Lista los incidentes |
| `GET` | `/incidents/{id}` | Detalle de un incidente |
| `PATCH` | `/incidents/{id}` | Cambia el estado (`open` / `resolved`) |

`severity` acepta `low`, `medium`, `high` y `critical`; cualquier otro valor se rechaza con `422`. La documentación interactiva queda en `/docs`.

## Ejecutar en local

Requisitos: Docker Desktop.

```bash
docker compose up --build
```

La API queda en `http://127.0.0.1:8000` (documentación en `/docs`) y los datos de PostgreSQL persisten entre reinicios.

```bash
curl http://127.0.0.1:8000/health
```

Pruebas (usan SQLite en memoria, no necesitan Docker):

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1        # Windows. En Linux/macOS: source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

## Estructura del repositorio

```
.
├── app/                  # API: rutas, modelos, esquemas y configuración
├── tests/                # Pruebas de la API
├── infra/                # Terraform: presupuesto, resource group y el resto de la infraestructura
├── Dockerfile            # Imagen de la API (usuario no-root)
├── docker-compose.yml    # API + PostgreSQL para desarrollo local
├── requirements.txt      # Dependencias de producción
└── requirements-dev.txt  # Dependencias de desarrollo y pruebas
```

## Decisiones de diseño

- **Presupuesto primero.** La alerta de costos se crea antes que cualquier recurso, porque la nube factura por uso.
- **Configuración por entorno.** La API lee `DATABASE_URL` de una variable de entorno; el mismo código corre con SQLite en pruebas, PostgreSQL en local y Azure en producción.
- **Dependencias separadas.** La imagen solo instala lo que la API necesita; `pytest` y compañía quedan fuera, lo que reduce el tamaño y la superficie de ataque.
- **Nada sensible en el repositorio.** Los valores personales van en `terraform.tfvars` (ignorado por git) y las credenciales de CI se obtienen por OIDC.
- **Todo reproducible.** La infraestructura completa se crea con `terraform apply` y se elimina con `terraform destroy`.

## Cómo se construyó

1. **App local:** API, Dockerfile, docker-compose y pruebas
2. **Terraform:** presupuesto con alertas e infraestructura base en Azure
3. **Primer despliegue manual:** imagen en GHCR y API en Container Apps
4. **CI/CD:** `pr.yml` y `deploy.yml` con OIDC y escaneos de seguridad
5. **Observabilidad:** 3 alertas y dashboard
6. **Documentación operativa:** runbook, postmortem del incidente simulado y ADRs

## Documentación operativa

- [Runbook](docs/runbook.md): cómo detectar y resolver incidentes del servicio
- [Postmortem](docs/postmortem.md): análisis del incidente simulado
- [ADRs](docs/adr/): decisiones de arquitectura y su justificación
