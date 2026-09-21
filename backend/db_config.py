"""Configuración compartida por la API y las migraciones."""

import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy.engine import URL, make_url
from sqlalchemy.exc import ArgumentError


load_dotenv(Path(__file__).resolve().parent.parent / ".env", override=False)

def required_env(name: str) -> str:
    value = os.getenv(name)
    if value is None or not value.strip():
        raise ValueError(f"Falta la variable de configuración obligatoria {name}")
    return value

def get_database_url() -> URL:
    if os.getenv("DATABASE_URL") is not None:
        value = required_env("DATABASE_URL")
        try:
            url = make_url(value)
        except (ArgumentError, ValueError):
            raise ValueError("DATABASE_URL no tiene un formato válido") from None
        if url.drivername in ("postgres", "postgresql"):
            url = url.set(drivername="postgresql+psycopg")
        return url

    user = required_env("DB_USER")
    password = required_env("DB_PASSWORD")
    host = required_env("DB_HOST")
    port_value = required_env("DB_PORT")
    name = required_env("DB_NAME")
    try:
        port = int(port_value)
    except ValueError:
        raise ValueError("DB_PORT debe ser un entero entre 1 y 65535") from None
    if not 1 <= port <= 65535:
        raise ValueError("DB_PORT debe ser un entero entre 1 y 65535")

    return URL.create(
        "mysql+pymysql", username=user, password=password,
        host=host, port=port, database=name,
    )