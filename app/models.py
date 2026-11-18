import enum
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class Severity(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class Status(str, enum.Enum):
    open = "open"
    resolved = "resolved"

def utcnow() -> datetime:
    return datetime.now(timezone.utc)

class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    severity: Mapped[Severity] = mapped_column(Enum(Severity))
    status: Mapped[Status] = mapped_column(Enum(Status), default=Status.open)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
