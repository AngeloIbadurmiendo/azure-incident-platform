from contextlib import asynccontextmanager


import logging
import os
from microsoft.opentelemetry import use_microsoft_opentelemetry
loggerName = "incident-api"
if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
    use_microsoft_opentelemetry(
        enable_azure_monitor=True,
        logger_name=loggerName,
    )
logger = logging.getLogger(loggerName)
logger.setLevel(logging.INFO)

from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import Base, engine, get_db
from app.models import Incident
from app.schemas import IncidentCreate, IncidentRead, IncidentUpdate

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield

app = FastAPI(title="Incident API", lifespan=lifespan)

@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    return {"status": "healthy"}

@app.post("/incidents", response_model=IncidentRead, status_code=status.HTTP_201_CREATED)
def create_incident(payload: IncidentCreate, db: Session = Depends(get_db)):
    incident = Incident(**payload.model_dump())
    db.add(incident)
    db.commit()
    db.refresh(incident)
    return incident

@app.get("/incidents", response_model=list[IncidentRead])
def list_incidents(db: Session = Depends(get_db)):
    return db.scalars(select(Incident).order_by(Incident.id)).all()

@app.get("/incidents/{incident_id}", response_model=IncidentRead)
def get_incident(incident_id: int, db: Session = Depends(get_db)):
    incident = db.get(Incident, incident_id)
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident

@app.patch("/incidents/{incident_id}", response_model=IncidentRead)
def update_incident(incident_id: int, payload: IncidentUpdate, db: Session = Depends(get_db)):
    incident = db.get(Incident, incident_id)
    if incident is None:
        raise HTTPException(status_code=404, detail="Incident not found")
    incident.status = payload.status
    db.commit()
    db.refresh(incident)
    return incident
