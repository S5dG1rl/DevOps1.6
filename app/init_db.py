cat > app/init_db.py <<'EOF'
from app import models  # noqa: F401
from app.db import Base, engine


def main():
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    main()
EOF