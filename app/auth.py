import hashlib
import secrets

from fastapi import Request
from sqlalchemy.orm import Session as DbSession

from app.models import Session, User


def hash_password(password: str, salt: str | None = None) -> str:
    if salt is None:
        salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode(), salt.encode(), 100000
    ).hex()
    return salt + "$" + digest


def check_password(password: str, stored: str) -> bool:
    salt = stored.split("$")[0]
    return hash_password(password, salt) == stored


def get_current_user(request: Request, db: DbSession) -> User | None:
    token = request.cookies.get("token")
    if not token:
        return None
    session = db.query(Session).filter(Session.token == token).first()
    if session is None:
        return None
    return db.get(User, session.user_id)
