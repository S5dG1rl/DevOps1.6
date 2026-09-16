import secrets

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session as DbSession

from app.auth import check_password, get_current_user, hash_password
from app.db import get_db
from app.models import Mountain, Session, User

router = APIRouter()
templates = Jinja2Templates(directory="templates")


@router.get("/", response_class=HTMLResponse)
def index(request: Request, db: DbSession = Depends(get_db)):
    user = get_current_user(request, db)
    mountains = db.query(Mountain).all()
    return templates.TemplateResponse(
        request,
        "index.html",
        {"user": user, "mountains": mountains},
    )


@router.get("/register", response_class=HTMLResponse)
def register_page(request: Request):
    return templates.TemplateResponse(
        request,
        "register.html",
        {"error": None},
    )


@router.post("/register")
async def register(request: Request, db: DbSession = Depends(get_db)):
    form = await request.form()
    username = form.get("username", "").strip()
    email = form.get("email", "").strip()
    password = form.get("password", "")
    error = None
    if not username or not email or len(password) < 6:
        error = "Заполните все поля, пароль должен быть не короче 6 символов"
    elif db.query(User).filter(User.username == username).first() is not None:
        error = "Такой логин уже занят"
    if error is not None:
        return templates.TemplateResponse(
            request,
            "register.html",
            {"error": error},
            status_code=400,
        )
    user = User(username=username, email=email, password_hash=hash_password(password))
    db.add(user)
    db.commit()
    return RedirectResponse("/login", status_code=303)


@router.get("/login", response_class=HTMLResponse)
def login_page(request: Request):
    return templates.TemplateResponse(
        request,
        "login.html",
        {"error": None},
    )


@router.post("/login")
async def login(request: Request, db: DbSession = Depends(get_db)):
    form = await request.form()
    username = form.get("username", "").strip()
    password = form.get("password", "")
    user = db.query(User).filter(User.username == username).first()
    if user is None or not check_password(password, user.password_hash):
        return templates.TemplateResponse(
            request,
            "login.html",
            {"error": "Неверный логин или пароль"},
            status_code=400,
        )
    token = secrets.token_hex(32)
    db.add(Session(user_id=user.id, token=token))
    db.commit()
    response = RedirectResponse("/", status_code=303)
    response.set_cookie("token", token)
    return response


@router.get("/logout")
def logout(request: Request, db: DbSession = Depends(get_db)):
    token = request.cookies.get("token")
    if token:
        db.query(Session).filter(Session.token == token).delete()
        db.commit()
    response = RedirectResponse("/", status_code=303)
    response.delete_cookie("token")
    return response


@router.get("/mountains/new", response_class=HTMLResponse)
def mountain_form(request: Request, db: DbSession = Depends(get_db)):
    user = get_current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    return templates.TemplateResponse(
        request,
        "mountain_form.html",
        {"user": user, "error": None},
    )


@router.post("/mountains/new")
async def mountain_create(request: Request, db: DbSession = Depends(get_db)):
    user = get_current_user(request, db)
    if user is None:
        return RedirectResponse("/login", status_code=303)
    form = await request.form()
    name = form.get("name", "").strip()
    country = form.get("country", "").strip()
    region = form.get("region", "").strip() or None
    try:
        height = int(form.get("height_m", "0"))
    except ValueError:
        height = 0
    if not name or not country or height <= 0:
        return templates.TemplateResponse(
            request,
            "mountain_form.html",
            {
                "user": user,
                "error": "Название и страна обязательны, высота должна быть больше нуля",
            },
            status_code=400,
        )
    mountain = Mountain(name=name, country=country, region=region, height_m=height)
    db.add(mountain)
    db.commit()
    return RedirectResponse("/", status_code=303)
