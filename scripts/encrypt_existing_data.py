"""
Скрипт для шифрования существующих данных в БД
Запуск: python -m scripts.encrypt_existing_data
"""
import hashlib

from app.db import SessionLocal
from app.models import Climber
from app.security import encrypt_data


def hash_email(email: str) -> str:
    """Создаёт детерминированный хэш email"""
    return hashlib.sha256(email.encode()).hexdigest()


def migrate_climbers():
    """Шифрует существующие данные альпинистов"""
    db = SessionLocal()
    
    try:
        climbers = db.query(Climber).all()
        print(f"Найдено {len(climbers)} альпинистов для миграции")
        
        for climber in climbers:
            # Проверяем, есть ли старые поля (до миграции)
            if hasattr(climber, 'full_name') and climber.full_name:
                # Шифруем full_name
                climber.full_name_encrypted = encrypt_data(climber.full_name)
                print(f"  ✓ Зашифрован full_name для climber ID={climber.id}")
            
            if hasattr(climber, 'email') and climber.email:
                # Шифруем email
                climber.email_encrypted = encrypt_data(climber.email)
                climber.email_hash = hash_email(climber.email)
                print(f"  ✓ Зашифрован email для climber ID={climber.id}")
        
        db.commit()
        print("✅ Миграция завершена успешно!")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Ошибка при миграции: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    migrate_climbers()
