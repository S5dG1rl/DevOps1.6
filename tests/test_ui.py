def register_user(client, username="tester", password="secret123"):
    return client.post(
        "/register",
        data={
            "username": username,
            "email": username + "@example.com",
            "password": password,
        },
        follow_redirects=False,
    )


def login_user(client, username="tester", password="secret123"):
    return client.post(
        "/login",
        data={"username": username, "password": password},
    )


def test_register_page(client):
    response = client.get("/register")
    assert response.status_code == 200
    assert "Регистрация" in response.text


def test_register_creates_user(client):
    response = register_user(client)
    assert response.status_code == 303
    response = login_user(client)
    assert response.status_code == 200
    assert "Привет, tester" in response.text


def test_register_short_password(client):
    response = client.post(
        "/register",
        data={"username": "short", "email": "short@example.com", "password": "123"},
    )
    assert response.status_code == 400
    assert "не короче 6 символов" in response.text


def test_login_wrong_password(client):
    register_user(client)
    response = client.post(
        "/login",
        data={"username": "tester", "password": "wrong"},
    )
    assert response.status_code == 400
    assert "Неверный логин или пароль" in response.text


def test_mountains_new_requires_login(client):
    response = client.get("/mountains/new", follow_redirects=False)
    assert response.status_code == 303


def test_mountains_new_creates_mountain(client):
    register_user(client)
    login_user(client)
    response = client.post(
        "/mountains/new",
        data={
            "name": "Казбек",
            "country": "Россия",
            "region": "Кавказ",
            "height_m": "5033",
        },
        follow_redirects=False,
    )
    assert response.status_code == 303
    response = client.get("/")
    assert "Казбек" in response.text
