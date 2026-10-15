import os

os.environ["DATABASE_URL"] = "sqlite:///:memory:"

import pytest
from fastapi.testclient import TestClient

from app.db import Base, engine
from app.main import app


@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client():
    return TestClient(app)


@pytest.fixture()
def auth_client(client):
    response = client.post(
        "/auth/register",
        json={
            "username": "test_instructor",
            "email": "test_instructor@example.com",
            "password": "TestPassword123",
        },
    )
    assert response.status_code == 201, response.text

    response = client.post(
        "/auth/login",
        json={
            "username": "test_instructor",
            "password": "TestPassword123",
        },
    )
    assert response.status_code == 200, response.text

    token = response.json()["access_token"]
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client
