import csv
from sqlalchemy import text
from database import SessionLocal, engine, Base
from models import Dia, Hermandad, InfoPaso, Usuario, Emisora, Noticia, Itinerario, ItemItinerario, DiaItinerario
from hashing import get_password_hash
from datetime import datetime
from infopasos_util import leer_infopasos_csv
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_DIR = os.path.join(BASE_DIR, "csv")

def load_dias(db):
    with open(os.path.join(CSV_DIR, "dias.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            dia = Dia(id=int(row['id']), nombre=row['nombre'], fecha=datetime.strptime(row['fecha'], "%Y-%m-%d"))
            db.add(dia)
    print("Loaded días")

         
def load_hermandades(db):
    with open(os.path.join(CSV_DIR, "hermandades.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            hermandad = Hermandad(id=int(row['id']), nombre=row['nombre'], idDia=int(row['idDia']))
            db.add(hermandad)
    print("Loaded hermandades")


def load_infopasos(db):
    with open(os.path.join(CSV_DIR, "infoPasos.csv"), encoding="utf-8") as f:
        entradas = leer_infopasos_csv(f.read())
    db.add_all([InfoPaso(**entrada) for entrada in entradas])
    print("Loaded infopasos")


def load_usuarios(db):
    with open(os.path.join(CSV_DIR, "usuarios.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            usuario = Usuario(
                id=int(row['id']),
                nombre=row['nombre'],
                email=row['email'],
                contrasena=get_password_hash(row['contrasena']),
                admin = int(row['admin'])
            )
            db.add(usuario)
    print("Loaded usuarios")


def load_emisoras(db):
    with open(os.path.join(CSV_DIR, "emisoras.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            emisora = Emisora(
                id=int(row['id']),
                nombre=row['nombre'],
                urlStream=row['urlStream'],
                urlImagen=row['urlImagen']
            )
            db.add(emisora)
    print("Loaded emisoras")


def load_noticias(db):
    with open(os.path.join(CSV_DIR, "noticias.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            noticia = Noticia(
                id=int(row['id']),
                titular=row['titular'],
                contenido=row['contenido'],
                url_imagen=row['url_imagen'],
                origen=row['origen'],
                fecha=datetime.strptime(row['fecha'], "%Y-%m-%d %H:%M:%S")
            )
            db.add(noticia)
    print("Loaded noticias")


def load_itinerarios(db):
    with open(os.path.join(CSV_DIR, "itinerarios.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            itinerario = Itinerario(
                id=int(row['id']),
                idUsuario=int(row['idUsuario'])
            )
            db.add(itinerario)
    print("Loaded itinerarios")


def load_items_itinerario(db):
    with open(os.path.join(CSV_DIR, "items_itinerario.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            item = ItemItinerario(
                id=int(row['id']),
                idItinerario=int(row['idItinerario']),
                idInfoPaso=int(row['idInfoPaso'])
            )
            db.add(item)
    print("Loaded items_itinerario")


def clear_seed_tables(db):
    db.query(DiaItinerario).delete(synchronize_session=False)
    db.query(ItemItinerario).delete(synchronize_session=False)
    db.query(Itinerario).delete(synchronize_session=False)
    db.query(InfoPaso).delete(synchronize_session=False)
    db.query(Hermandad).delete(synchronize_session=False)
    db.query(Dia).delete(synchronize_session=False)
    db.query(Noticia).delete(synchronize_session=False)
    db.query(Emisora).delete(synchronize_session=False)
    db.query(Usuario).delete(synchronize_session=False)
    
    
def reset_auto_increment(db):
    tablas = [
        "dias_itinerario", "items_itinerario", "itinerarios", "infopaso",
        "hermandades", "dias", "noticias", "emisoras", "usuarios",
    ]
    dialecto = db.get_bind().dialect.name
    for tabla in tablas:
        if dialecto == "postgresql":
            db.execute(text(
                f"SELECT setval(pg_get_serial_sequence('{tabla}', 'id'), "
                f"COALESCE((SELECT MAX(id) FROM {tabla}), 1))"
            ))
        elif dialecto == "mysql":
            db.execute(text(f"ALTER TABLE {tabla} AUTO_INCREMENT = 1"))
    db.commit()
    print("Reset ID counters")


def create_tables():
    Base.metadata.create_all(bind=engine)
    print("Created tables")
    

def seed_database():
    create_tables()
    db = SessionLocal()
    try:
        clear_seed_tables(db)
        load_dias(db)
        load_hermandades(db)
        load_infopasos(db)
        load_usuarios(db)
        load_emisoras(db)
        load_noticias(db)
        load_itinerarios(db)
        load_items_itinerario(db)
        db.commit()
        reset_auto_increment(db)
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_database()