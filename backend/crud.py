from sqlalchemy.orm import Session
from typing import List, Optional
import models
import schemas
import os
import google.generativeai as genai
from hashing import get_password_hash, verify_password
from datetime import time, datetime

#Día
def get_dia(db: Session, dia_id: int) -> Optional[models.Dia]:
    return db.query(models.Dia).filter(models.Dia.id == dia_id).first()

def get_dias(db: Session, skip: int = 0, limit: int = 100) -> List[models.Dia]:
    return db.query(models.Dia).offset(skip).limit(limit).all()

def create_dia(db: Session, dia: schemas.DiaCreate) -> models.Dia:
    db_dia = models.Dia(**dia.model_dump())
    db.add(db_dia)
    db.commit()
    db.refresh(db_dia)
    return db_dia

def update_dia(db: Session, dia_id: int, dia: schemas.DiaUpdate) -> Optional[models.Dia]:
    db_dia = get_dia(db, dia_id)
    if db_dia:
        update_data = dia.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_dia, key, value)
        db.commit()
        db.refresh(db_dia)
    return db_dia

def delete_dia(db: Session, dia_id: int) -> bool:
    db_dia = get_dia(db, dia_id)
    if db_dia:
        db.delete(db_dia)
        db.commit()
        return True
    return False


#Hermandad
def get_hermandad(db: Session, hermandad_id: int) -> Optional[models.Hermandad]:
    return db.query(models.Hermandad).filter(models.Hermandad.id == hermandad_id).first()

def get_hermandades(db: Session, skip: int = 0, limit: int = 100) -> List[models.Hermandad]:
    return db.query(models.Hermandad).offset(skip).limit(limit).all()

def get_hermandades_by_dia(db: Session, dia_id: int) -> List[models.Hermandad]:
    return db.query(models.Hermandad).filter(models.Hermandad.idDia == dia_id).all()

def create_hermandad(db: Session, hermandad: schemas.HermandadCreate) -> models.Hermandad:
    db_hermandad = models.Hermandad(**hermandad.model_dump())
    db.add(db_hermandad)
    db.commit()
    db.refresh(db_hermandad)
    return db_hermandad

def update_hermandad(db: Session, hermandad_id: int, hermandad: schemas.HermandadUpdate) -> Optional[models.Hermandad]:
    db_hermandad = get_hermandad(db, hermandad_id)
    if db_hermandad:
        update_data = hermandad.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_hermandad, key, value)
        db.commit()
        db.refresh(db_hermandad)
    return db_hermandad

def delete_hermandad(db: Session, hermandad_id: int) -> bool:
    db_hermandad = get_hermandad(db, hermandad_id)
    if db_hermandad:
        db.delete(db_hermandad)
        db.commit()
        return True
    return False


#InfoPaso
def get_infopaso(db: Session, infopaso_id: int) -> Optional[models.InfoPaso]:
    return db.query(models.InfoPaso).filter(models.InfoPaso.id == infopaso_id).first()

def get_infopasos(db: Session, skip: int = 0, limit: int = 100) -> List[models.InfoPaso]:
    return db.query(models.InfoPaso).offset(skip).limit(limit).all()

def get_infopasos_by_hermandad(db: Session, hermandad_id: int) -> List[models.InfoPaso]:
    return db.query(models.InfoPaso).filter(models.InfoPaso.idHermandad == hermandad_id).all()

def create_infopaso(db: Session, infopaso: schemas.InfoPasoCreate) -> models.InfoPaso:
    db_infopaso = models.InfoPaso(**infopaso.model_dump())
    db.add(db_infopaso)
    db.commit()
    db.refresh(db_infopaso)
    return db_infopaso

def update_infopaso(db: Session, infopaso_id: int, infopaso: schemas.InfoPasoUpdate) -> Optional[models.InfoPaso]:
    db_infopaso = get_infopaso(db, infopaso_id)
    if db_infopaso:
        update_data = infopaso.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_infopaso, key, value)
        db.commit()
        db.refresh(db_infopaso)
    return db_infopaso

def delete_infopaso(db: Session, infopaso_id: int) -> bool:
    db_infopaso = get_infopaso(db, infopaso_id)
    if db_infopaso:
        db.delete(db_infopaso)
        db.commit()
        return True
    return False

def get_infopasos_by_dia(db: Session, dia_id: int) -> List[models.InfoPaso]:
    return db.query(models.InfoPaso).join(models.Hermandad).filter(models.Hermandad.idDia == dia_id).all()

def get_infopasos_by_dia_and_hermandad(db: Session, dia_id: int, hermandad_id: int) -> List[models.InfoPaso]:
    return db.query(models.InfoPaso).join(models.Hermandad).filter(models.Hermandad.idDia == dia_id, models.Hermandad.id == hermandad_id).all()

#Usuario
def get_usuario(db: Session, usuario_id: int) -> Optional[models.Usuario]:
    return db.query(models.Usuario).filter(models.Usuario.id == usuario_id).first()

def get_usuario_by_email(db: Session, email: str) -> Optional[models.Usuario]:
    return db.query(models.Usuario).filter(models.Usuario.email == email).first()

def get_usuarios(db: Session, skip: int = 0, limit: int = 100) -> List[models.Usuario]:
    return db.query(models.Usuario).offset(skip).limit(limit).all()

def create_usuario(db: Session, usuario: schemas.UsuarioCreate) -> models.Usuario:
    user_data = usuario.model_dump()
    user_data["contrasena"] = get_password_hash(user_data["contrasena"])
    db_usuario = models.Usuario(**user_data)
    db.add(db_usuario)
    db.commit()
    db.refresh(db_usuario)
    return db_usuario

def update_usuario(db: Session, usuario_id: int, usuario: schemas.UsuarioUpdate) -> Optional[models.Usuario]:
    db_usuario = get_usuario(db, usuario_id)
    if db_usuario:
        update_data = usuario.model_dump(exclude_unset=True)
        if "contrasena" in update_data and update_data["contrasena"]:
            update_data["contrasena"] = get_password_hash(update_data["contrasena"])
        for key, value in update_data.items():
            setattr(db_usuario, key, value)
        db.commit()
        db.refresh(db_usuario)
    return db_usuario

def change_password(db: Session, usuario_id: int, contrasena_actual: str, contrasena_nueva: str) -> models.Usuario:
    db_usuario = get_usuario(db, usuario_id)
    if not db_usuario:
        raise ValueError("Usuario no encontrado")
    if not verify_password(contrasena_actual, db_usuario.contrasena):
        raise ValueError("Contraseña actual incorrecta")
    db_usuario.contrasena = get_password_hash(contrasena_nueva)
    db.commit()
    db.refresh(db_usuario)
    return db_usuario

def update_admin_usuario(db: Session, usuario_id: int, usuario: schemas.UsuarioUpdateAdmin) -> Optional[models.Usuario]:
    db_usuario = get_usuario(db, usuario_id)
    if db_usuario:
        update_data = usuario.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_usuario, key, value)
        db.commit()
        db.refresh(db_usuario)
    return db_usuario

def delete_usuario(db: Session, usuario_id: int) -> bool:
    db_usuario = get_usuario(db, usuario_id)
    if db_usuario:
        db.delete(db_usuario)
        db.commit()
        return True
    return False

def usuario_exists_by_email(db: Session, email: str) -> bool:
    return db.query(models.Usuario).filter(models.Usuario.email == email).first() is not None

def authenticate_usuario(db: Session, email: str, contrasena: str) -> Optional[models.Usuario]:
    db_usuario = get_usuario_by_email(db, email)
    if not db_usuario:
        return None
    if not verify_password(contrasena, db_usuario.contrasena):
        return None
    return db_usuario


#Itinerario
def get_itinerario(db: Session, itinerario_id: int) -> Optional[models.Itinerario]:
    return db.query(models.Itinerario).filter(models.Itinerario.id == itinerario_id).first()

def get_itinerario_by_usuario(db: Session, usuario_id: int) -> Optional[models.Itinerario]:
    return db.query(models.Itinerario).filter(models.Itinerario.idUsuario == usuario_id).first()

def get_itinerarios(db: Session, skip: int = 0, limit: int = 100) -> List[models.Itinerario]:
    return db.query(models.Itinerario).offset(skip).limit(limit).all()

def create_itinerario(db: Session, itinerario: schemas.ItinerarioCreate) -> models.Itinerario:
    db_itinerario = models.Itinerario(idUsuario=itinerario.idUsuario)
    db.add(db_itinerario)
    db.commit()
    db.refresh(db_itinerario)
    return db_itinerario

def delete_itinerario(db: Session, itinerario_id: int) -> bool:
    db_itinerario = get_itinerario(db, itinerario_id)
    if db_itinerario:
        db.delete(db_itinerario)
        db.commit()
        return True
    return False


#ItemItinerario
def get_item_itinerario(db: Session, item_id: int) -> Optional[models.ItemItinerario]:
    return db.query(models.ItemItinerario).filter(models.ItemItinerario.id == item_id).first()

def get_items_by_itinerario(db: Session, itinerario_id: int) -> List[models.ItemItinerario]:
    return db.query(models.ItemItinerario).filter(models.ItemItinerario.idItinerario == itinerario_id).all()

def create_item_itinerario(db: Session, itinerario_id: int, item: schemas.ItemItinerarioCreate) -> models.ItemItinerario:
    db_item = models.ItemItinerario(idItinerario=itinerario_id, idInfoPaso=item.idInfoPaso)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def delete_item_itinerario(db: Session, item_id: int) -> bool:
    db_item = get_item_itinerario(db, item_id)
    if db_item:
        db.delete(db_item)
        db.commit()
        return True
    return False


#DiaItinerario
def get_dias_by_itinerario(db: Session, itinerario_id: int) -> List[models.DiaItinerario]:
    return db.query(models.DiaItinerario).filter(models.DiaItinerario.idItinerario == itinerario_id).all()

def create_dia_itinerario(db: Session, itinerario_id: int, dia: schemas.DiaItinerarioCreate) -> models.DiaItinerario:
    db_dia = models.DiaItinerario(idItinerario=itinerario_id, idDia=dia.idDia)
    db.add(db_dia)
    db.commit()
    db.refresh(db_dia)
    return db_dia

def delete_dia_itinerario(db: Session, dia_itinerario_id: int) -> bool:
    db_dia = db.query(models.DiaItinerario).filter(models.DiaItinerario.id == dia_itinerario_id).first()
    if db_dia:
        db.delete(db_dia)
        db.commit()
        return True
    return False


#Noticia
def get_noticia(db: Session, noticia_id: int) -> Optional[models.Noticia]:
    return db.query(models.Noticia).filter(models.Noticia.id == noticia_id).first()

def get_noticias(db: Session, skip: int = 0, limit: int = 30) -> List[models.Noticia]:
    return (
        db.query(models.Noticia)
        .order_by(models.Noticia.fecha.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

def create_noticia(db: Session, noticia: schemas.NoticiaCreate) -> models.Noticia:
    db_noticia = models.Noticia(**noticia.model_dump())
    db.add(db_noticia)
    db.commit()
    db.refresh(db_noticia)
    return db_noticia

def update_noticia(db: Session, noticia_id: int, noticia: schemas.NoticiaUpdate) -> Optional[models.Noticia]:
    db_noticia = get_noticia(db, noticia_id)
    if db_noticia:
        update_data = noticia.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_noticia, key, value)
        db.commit()
        db.refresh(db_noticia)

    return db_noticia

def delete_noticia(db: Session, noticia_id: int) -> bool:
    db_noticia = get_noticia(db, noticia_id)
    if db_noticia:
        db.delete(db_noticia)
        db.commit()
        return True
    return False

#Resumen IA
GEMINI_MODEL = "gemini-flash-latest"

SYSTEM_INSTRUCTION = (
    "Eres un experto en la Semana Santa de Sevilla. "
    "Respondes siempre en español, de forma impersonal e informativa."
)
PROMPT_RESUMEN = (
    "Genera un resumen breve y claro de unas 10-15 líneas de las siguientes noticias "
    "relacionadas con la Semana Santa en Sevilla. No inventes datos que no aparezcan en las noticias."
)

def _generar_texto_resumen(db: Session) -> dict:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Falta la clave de la API de Gemini")

    noticias = get_noticias(db)
    if not noticias:
        return {"resumen": "No hay noticias disponibles para resumir.", "modelo": GEMINI_MODEL}

    bloque = "\n\n".join(f"- {n.titular}: {n.contenido}" for n in noticias)

    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            system_instruction=SYSTEM_INSTRUCTION,
        )
        response = model.generate_content(f"{PROMPT_RESUMEN}\n\nNoticias:\n{bloque}")
        texto = (response.text or "").strip()
        return {"resumen": texto, "modelo": GEMINI_MODEL}
    except Exception as e:
        raise RuntimeError(f"Error llamando a Gemini: {e}")


def regenerar_resumen(db: Session) -> models.ResumenNoticias:
    data = _generar_texto_resumen(db)

    fila = db.query(models.ResumenNoticias).first()
    if fila is None:
        fila = models.ResumenNoticias(
            resumen=data["resumen"],
            modelo=data["modelo"],
            fecha_actualizacion=datetime.utcnow(),
        )
        db.add(fila)
    else:
        fila.resumen = data["resumen"]
        fila.modelo = data["modelo"]
        fila.fecha_actualizacion = datetime.utcnow()

    db.commit()
    db.refresh(fila)
    return fila


def get_resumen(db: Session) -> Optional[models.ResumenNoticias]:
    return db.query(models.ResumenNoticias).first()

#Emisora
def get_emisora(db: Session, emisora_id: int) -> Optional[models.Emisora]:
    return db.query(models.Emisora).filter(models.Emisora.id == emisora_id).first()

def get_emisoras(db: Session, skip: int = 0, limit: int = 100) -> List[models.Emisora]:
    return db.query(models.Emisora).offset(skip).limit(limit).all()

def create_emisora(db: Session, emisora: schemas.EmisoraCreate) -> models.Emisora:
    db_emisora = models.Emisora(**emisora.model_dump())
    db.add(db_emisora)
    db.commit()
    db.refresh(db_emisora)
    return db_emisora

def update_emisora(db: Session, emisora_id: int, emisora: schemas.EmisoraUpdate) -> Optional[models.Emisora]:
    db_emisora = get_emisora(db, emisora_id)
    if db_emisora:
        update_data = emisora.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_emisora, key, value)
        db.commit()
        db.refresh(db_emisora)
    return db_emisora

def delete_emisora(db: Session, emisora_id: int) -> bool:
    db_emisora = get_emisora(db, emisora_id)
    if db_emisora:
        db.delete(db_emisora)
        db.commit()
        return True
    return False


#Admin-Hermandades
def clear_hermandades(db: Session) -> int:
    db.query(models.DiaItinerario).delete()
    db.query(models.ItemItinerario).delete()
    db.query(models.InfoPaso).delete()
    
    count = db.query(models.Hermandad).count()
    db.query(models.Hermandad).delete()
    return count

def load_hermandades_from_csv(db: Session, csv_content: str) -> int:
    
    lines = csv_content.strip().split("\n")
    if len(lines) < 2:
        raise ValueError("El CSV debe tener al menos una cabecera y una fila de datos")
    
    header = lines[0].strip().split(";")
    expected = ["id", "nombre", "idDia"]
    if header != expected:
        raise ValueError(f"Cabecera incorrecta. Se esperaba: {';'.join(expected)}")
    
    registros = []
    
    for i, line in enumerate(lines[1:], start=2):
        line = line.strip()
        if not line:
            continue
        
        campos = line.split(";")
        if len(campos) != 3:
            raise ValueError(f"Línea {i}: se esperaban 3 campos, se encontraron {len(campos)}")
        
        id_str = campos[0].strip()
        nombre = campos[1].strip()
        id_dia_str = campos[2].strip()
        
        if not id_str:
            raise ValueError(f"Línea {i}: id no puede estar vacío")
        try:
            id_hermandad = int(id_str)
            if id_hermandad <= 0:
                raise ValueError(f"Línea {i}: id debe ser un número positivo")
        except ValueError:
            raise ValueError(f"Línea {i}: id debe ser un número entero válido")
        
        if not nombre:
            raise ValueError(f"Línea {i}: nombre no puede estar vacío")
        
        if not id_dia_str:
            raise ValueError(f"Línea {i}: idDia no puede estar vacío")
        try:
            id_dia = int(id_dia_str)
            if id_dia <= 0:
                raise ValueError(f"Línea {i}: idDia debe ser un número positivo")
        except ValueError:
            raise ValueError(f"Línea {i}: idDia debe ser un número entero válido")
        
        hermandad = models.Hermandad(
            id=id_hermandad,
            nombre=nombre,
            idDia=id_dia,
        )
        registros.append(hermandad)
    
    db.add_all(registros)
    return len(registros)


#Admin-InfoPasos
def clear_infopasos(db: Session) -> int:
    db.query(models.DiaItinerario).delete()
    db.query(models.ItemItinerario).delete()
    
    count = db.query(models.InfoPaso).count()
    db.query(models.InfoPaso).delete()
    return count

def load_infopasos_from_csv(db: Session, csv_content: str) -> int:
    
    lines = csv_content.strip().split("\n")
    if len(lines) < 2:
        raise ValueError("El CSV debe tener al menos una cabecera y una fila de datos")
    
    header = lines[0].strip().split(";")
    expected = ["idHermandad", "tipoPaso", "hora", "localizacion", "difHora", "esCarreraOficial"]
    if header != expected:
        raise ValueError(f"Cabecera incorrecta. Se esperaba: {';'.join(expected)}")
    
    tipos_paso_validos = ["CRUZGUIA", "PALIO", "DUELO", "PASO"]
    registros = []
    
    for i, line in enumerate(lines[1:], start=2):
        line = line.strip()
        if not line:
            continue
        
        campos = line.split(";")
        if len(campos) != 6:
            raise ValueError(f"Línea {i}: se esperaban 6 campos, se encontraron {len(campos)}")
        
        id_hermandad_str = campos[0].strip()
        tipo_paso = campos[1].strip()
        hora_str = campos[2].strip()
        localizacion = campos[3].strip()
        dif_hora_str = campos[4].strip()
        es_carrera_oficial = campos[5].strip()
        
        if not id_hermandad_str:
            raise ValueError(f"Línea {i}: idHermandad no puede estar vacío")
        try:
            id_hermandad = int(id_hermandad_str)
            if id_hermandad <= 0:
                raise ValueError(f"Línea {i}: idHermandad debe ser un número positivo")
        except ValueError:
            raise ValueError(f"Línea {i}: idHermandad debe ser un número entero válido")
        
        if not tipo_paso:
            raise ValueError(f"Línea {i}: tipoPaso no puede estar vacío")
        if tipo_paso not in tipos_paso_validos:
            raise ValueError(f"Línea {i}: tipoPaso '{tipo_paso}' no es válido. Debe ser: {', '.join(tipos_paso_validos)}")
        
        if not hora_str:
            raise ValueError(f"Línea {i}: hora no puede estar vacía")
        try:
            partes_hora = hora_str.split(":")
            if len(partes_hora) != 2:
                raise ValueError("Formato incorrecto")
            hora = time(int(partes_hora[0]), int(partes_hora[1]))
        except (ValueError, IndexError):
            raise ValueError(f"Línea {i}: hora debe tener formato HH:MM (ej: 17:30)")
        
        if not localizacion:
            raise ValueError(f"Línea {i}: localizacion no puede estar vacía")
        
        dif_hora = None
        if dif_hora_str:
            try:
                partes_dif = dif_hora_str.split(":")
                if len(partes_dif) != 2:
                    raise ValueError("Formato incorrecto")
                dif_hora = time(int(partes_dif[0]), int(partes_dif[1]))
            except (ValueError, IndexError):
                raise ValueError(f"Línea {i}: difHora debe tener formato HH:MM (ej: 17:00) o estar vacío")
        
        if es_carrera_oficial:
            if es_carrera_oficial not in ("0", "1"):
                raise ValueError(f"Línea {i}: esCarreraOficial debe ser 0, 1 o estar vacío")
            es_carrera_oficial = int(es_carrera_oficial)
        else:
            es_carrera_oficial = 0
        
        infopaso = models.InfoPaso(
            idHermandad=id_hermandad,
            tipoPaso=tipo_paso,
            hora=hora,
            localizacion=localizacion,
            difHora=dif_hora,
            esCarreraOficial=es_carrera_oficial,
        )
        registros.append(infopaso)
    
    db.add_all(registros)
    return len(registros)
