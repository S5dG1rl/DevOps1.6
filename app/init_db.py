from app import models  # КРИТИЧЕСКИ ВАЖНО!
from app.db import Base, engine


def main():
    Base.metadata.create_all(bind=engine)


if __name__ == "__main__":
    main()
