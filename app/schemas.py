from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from app.models import Severity, Status

class IncidentCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = ""
    severity: Severity

class IncidentUpdate(BaseModel):
    status: Status

class IncidentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str
    description: str
    severity: Severity
    status: Status
    created_at: datetime
