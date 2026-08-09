import csv
from sqlalchemy import text
from database import SessionLocal, engine, Base
from models import Dia, Hermandad, InfoPaso, TipoPaso, Usuario, Emisora, Noticia, Itinerario, ItemItinerario, DiaItinerario
from hashing import get_password_hash
from datetime import datetime
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


def hora_a_minutos(hora):
    return hora.hour * 60 + hora.minute

def minutos_a_hora(minutos):
    minutos = minutos % 1440
    horas = minutos // 60
    mins = minutos % 60
    return datetime.strptime(f"{horas:02d}:{mins:02d}", "%H:%M").time()


def load_infopasos(db):
    grupos_por_hermandad_tipo = {}
    with open(os.path.join(CSV_DIR, "infopasos.csv"), encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            hora_str = row.get('hora', '').strip()
            dif_hora_str = row.get('difHora', '').strip() if row.get('difHora') else ''
            tipo_paso_str = row['tipoPaso'].strip()
            tipo_paso_enum = TipoPaso[tipo_paso_str.upper()]
            
            es_carrera_str = row.get('esCarreraOficial', '0').strip()
            entrada = {
                'hora': datetime.strptime(hora_str, "%H:%M").time(),
                'tipoPaso': tipo_paso_enum,
                'localizacion': row['localizacion'],
                'idHermandad': int(row['idHermandad']),
                'difHora': datetime.strptime(dif_hora_str, "%H:%M").time() if dif_hora_str else None,
                'esCarreraOficial': int(es_carrera_str) if es_carrera_str else 0
            }
            clave = (entrada['idHermandad'], tipo_paso_str.upper())
            grupos_por_hermandad_tipo.setdefault(clave, []).append(entrada)

    #Para cada grupo, rellenar huecos mayores de 30 minutos entre entradas consecutivas
    #para que cada franja de media hora tenga su propio registro en la base de datis
    for clave, entradas in grupos_por_hermandad_tipo.items():
        entradas_a_insertar = []
        for i in range(len(entradas) - 1):
            entrada_actual = entradas[i]
            entrada_siguiente = entradas[i + 1]
            minutos_actual = hora_a_minutos(entrada_actual['hora'])
            minutos_siguiente = hora_a_minutos(entrada_siguiente['hora'])
            
            if minutos_siguiente <= minutos_actual:
                minutos_siguiente += 1440
            dif = minutos_siguiente - minutos_actual
            
            if dif > 30:
                minutos_relleno = minutos_actual + 30
                while minutos_relleno < minutos_siguiente:
                    entrada_relleno = {
                        'hora': minutos_a_hora(minutos_relleno),
                        'tipoPaso': entrada_actual['tipoPaso'],
                        'localizacion': entrada_actual['localizacion'],
                        'idHermandad': entrada_actual['idHermandad'],
                        'difHora': None,
                        'esCarreraOficial': entrada_actual['esCarreraOficial']
                    }
                    entradas_a_insertar.append(entrada_relleno)
                    minutos_relleno += 30
        entradas.extend(entradas_a_insertar)
        entradas.sort(key=lambda e: hora_a_minutos(e['hora']))

    for entradas in grupos_por_hermandad_tipo.values():
        for entrada in entradas:
            info_paso = InfoPaso(
                hora=entrada['hora'],
                tipoPaso=entrada['tipoPaso'],
                localizacion=entrada['localizacion'],
                idHermandad=entrada['idHermandad'],
                difHora=entrada['difHora'],
                esCarreraOficial=entrada['esCarreraOficial']
            )
            db.add(info_paso)
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