import os
import time
from typing import Optional

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://oneclick_user:oneclick_pass@localhost:5432/oneclick_cars_db"
)


def create_engine_with_retry(max_retries: int = 10, delay_seconds: int = 3):
    last_error: Optional[Exception] = None
    for attempt in range(max_retries):
        try:
            engine = create_engine(DATABASE_URL)
            with engine.connect() as connection:
                connection.execute("SELECT 1")
            return engine
        except OperationalError as exc:
            last_error = exc
            if attempt < max_retries - 1:
                time.sleep(delay_seconds)
                continue
            raise

    raise last_error


engine = create_engine_with_retry()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
