def create_mountain(auth_client, name="Эльбрус"):
    response = auth_client.post(
        "/api/mountains",
        json={
            "name": name,
            "country": "Россия",
            "region": "Кавказ",
            "height_m": 5642,
        },
    )
    assert response.status_code == 201
    return response.json()


def create_climber(auth_client):
    response = auth_client.post(
        "/api/climbers",
        json={
            "full_name": "Иванов Иван Иванович",
            "email": "ivanov@example.com",
            "birth_date": "2000-01-01",
            "experience_level": "intermediate",
            "medical_clearance": True,
        },
    )
    assert response.status_code == 201
    return response.json()


def create_group(auth_client, name="Группа 1"):
    response = auth_client.post(
        "/api/groups",
        json={
            "name": name,
            "description": "Тестовая группа",
        },
    )
    assert response.status_code == 201
    return response.json()


def create_ascent(auth_client, mountain_id, group_id):
    response = auth_client.post(
        "/api/ascents",
        json={
            "mountain_id": mountain_id,
            "group_id": group_id,
            "route_name": "Классический маршрут",
            "start_date": "2026-09-01",
            "end_date": "2026-09-05",
            "notes": "Тестовое восхождение",
        },
    )
    assert response.status_code == 201
    return response.json()


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200

    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "ok"


def test_create_mountain(auth_client):
    mountain = create_mountain(auth_client)
    assert mountain["id"] == 1
    assert mountain["name"] == "Эльбрус"


def test_create_mountain_invalid_height(auth_client):
    response = auth_client.post(
        "/api/mountains",
        json={
            "name": "Некорректная гора",
            "country": "Россия",
            "height_m": 0,
        },
    )
    assert response.status_code == 422


def test_ascent_invalid_dates(auth_client):
    mountain = create_mountain(auth_client)
    group = create_group(auth_client)

    response = auth_client.post(
        "/api/ascents",
        json={
            "mountain_id": mountain["id"],
            "group_id": group["id"],
            "start_date": "2026-09-05",
            "end_date": "2026-09-01",
        },
    )
    assert response.status_code == 422


def test_complete_ascent_without_participants(auth_client):
    mountain = create_mountain(auth_client)
    group = create_group(auth_client)
    ascent = create_ascent(auth_client, mountain["id"], group["id"])

    response = auth_client.post(f"/api/ascents/{ascent['id']}/complete")
    assert response.status_code == 409


def test_full_flow(auth_client):
    mountain = create_mountain(auth_client)
    climber = create_climber(auth_client)
    group = create_group(auth_client)

    response = auth_client.post(
        f"/api/groups/{group['id']}/climbers",
        json={
            "climber_id": climber["id"],
            "role": "leader",
        },
    )
    assert response.status_code == 201

    ascent = create_ascent(auth_client, mountain["id"], group["id"])

    response = auth_client.post(
        "/api/reports",
        json={
            "ascent_id": ascent["id"],
            "title": "Итоговый отчёт",
            "summary": "Отчёт до завершения восхождения",
        },
    )
    assert response.status_code == 409

    response = auth_client.post(f"/api/ascents/{ascent['id']}/complete")
    assert response.status_code == 200
    assert response.json()["status"] == "completed"

    response = auth_client.post(
        "/api/reports",
        json={
            "ascent_id": ascent["id"],
            "title": "Итоговый отчёт",
            "summary": "Восхождение завершено без происшествий",
        },
    )
    assert response.status_code == 201


def test_list_climbers_requires_auth(client):
    response = client.get("/api/climbers")
    assert response.status_code == 401


def test_list_groups_requires_auth(client):
    response = client.get("/api/groups")
    assert response.status_code == 401


def test_list_ascents_requires_auth(client):
    response = client.get("/api/ascents")
    assert response.status_code == 401


def test_list_reports_requires_auth(client):
    response = client.get("/api/reports")
    assert response.status_code == 401
