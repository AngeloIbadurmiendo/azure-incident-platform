import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.main import app


@pytest.fixture
def client():
    # SQLite en memoria, aislada por prueba. StaticPool = una sola conexión compartida.
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "healthy"}


def test_create_and_get_incident(client):
    r = client.post("/incidents", json={"title": "DB caída", "severity": "high"})
    assert r.status_code == 201
    body = r.json()
    assert body["status"] == "open"
    assert body["description"] == ""

    r = client.get(f"/incidents/{body['id']}")
    assert r.status_code == 200
    assert r.json()["title"] == "DB caída"


def test_list_incidents(client):
    client.post("/incidents", json={"title": "A", "severity": "low"})
    client.post("/incidents", json={"title": "B", "severity": "critical"})
    r = client.get("/incidents")
    assert [i["title"] for i in r.json()] == ["A", "B"]


def test_invalid_severity_returns_422(client):
    r = client.post("/incidents", json={"title": "X", "severity": "banana"})
    assert r.status_code == 422


def test_resolve_incident(client):
    created = client.post("/incidents", json={"title": "X", "severity": "low"}).json()
    r = client.patch(f"/incidents/{created['id']}", json={"status": "resolved"})
    assert r.status_code == 200
    assert r.json()["status"] == "resolved"


def test_not_found(client):
    assert client.get("/incidents/999").status_code == 404
    assert client.patch("/incidents/999", json={"status": "resolved"}).status_code == 404
