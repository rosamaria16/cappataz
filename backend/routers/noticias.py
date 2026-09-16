from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
import models
from database import SessionLocal, get_db
from auth import obtener_admin_actual

router = APIRouter()


def _regenerar_resumen_bg() -> None:
    db = SessionLocal()
    try:
        crud.regenerar_resumen(db)

    finally:
        db.close()


@router.get("/", response_model=List[schemas.NoticiaResponse])
def read_noticias(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_noticias(db, skip=skip, limit=limit)

@router.get("/summary", response_model=schemas.ResumenResponse)
def leer_resumen(db: Session = Depends(get_db)):
    resumen = crud.get_resumen(db)
    if resumen is None:
        try:
            resumen = crud.regenerar_resumen(db)
        except ValueError:
            raise HTTPException(status_code=503, detail="El servicio de resumen no está disponible")
        except RuntimeError:
            raise HTTPException(status_code=502, detail="No se pudo generar el resumen")
    return resumen
    
@router.post("/regenerar-resumen", response_model=schemas.ResumenResponse)
def forzar_regenerar_resumen(
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    try:
        return crud.regenerar_resumen(db)
    except ValueError:
        raise HTTPException(status_code=503, detail="El servicio de resumen no está disponible")
    except RuntimeError:
        raise HTTPException(status_code=502, detail="No se pudo generar el resumen")


@router.get("/{noticia_id}", response_model=schemas.NoticiaResponse)
def read_noticia(noticia_id: int, db: Session = Depends(get_db)):
    db_noticia = crud.get_noticia(db, noticia_id=noticia_id)
    if db_noticia is None:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    return db_noticia


@router.post("/", response_model=schemas.NoticiaResponse, status_code=201)
def create_noticia(
    noticia: schemas.NoticiaCreate,
    background_tasks: BackgroundTasks,
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    db_noticia = crud.create_noticia(db=db, noticia=noticia)
    background_tasks.add_task(_regenerar_resumen_bg)
    return db_noticia


@router.put("/{noticia_id}", response_model=schemas.NoticiaResponse)
def update_noticia(
    noticia_id: int,
    noticia: schemas.NoticiaUpdate,
    background_tasks: BackgroundTasks,
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    db_noticia = crud.update_noticia(db, noticia_id=noticia_id, noticia=noticia)
    if db_noticia is None:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    background_tasks.add_task(_regenerar_resumen_bg)
    return db_noticia


@router.delete("/{noticia_id}", status_code=204)
def delete_noticia(
    noticia_id: int,
    background_tasks: BackgroundTasks,
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    success = crud.delete_noticia(db, noticia_id=noticia_id)
    if not success:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    background_tasks.add_task(_regenerar_resumen_bg)
    return None