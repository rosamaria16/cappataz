from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db

router = APIRouter()


@router.get("/", response_model=List[schemas.NoticiaResponse])
def read_noticias(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_noticias(db, skip=skip, limit=limit)

@router.get("/summary", response_model=schemas.ResumenResponse)
def generar_resumen(db: Session = Depends(get_db)):
    try:
        return crud.create_resumen(db=db)
    except ValueError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=str(e))
    
@router.get("/{noticia_id}", response_model=schemas.NoticiaResponse)
def read_noticia(noticia_id: int, db: Session = Depends(get_db)):
    db_noticia = crud.get_noticia(db, noticia_id=noticia_id)
    if db_noticia is None:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    return db_noticia


@router.post("/", response_model=schemas.NoticiaResponse, status_code=201)
def create_noticia(noticia: schemas.NoticiaCreate, db: Session = Depends(get_db)):
    return crud.create_noticia(db=db, noticia=noticia)


@router.put("/{noticia_id}", response_model=schemas.NoticiaResponse)
def update_noticia(noticia_id: int, noticia: schemas.NoticiaUpdate, db: Session = Depends(get_db)):
    db_noticia = crud.update_noticia(db, noticia_id=noticia_id, noticia=noticia)
    if db_noticia is None:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    return db_noticia


@router.delete("/{noticia_id}", status_code=204)
def delete_noticia(noticia_id: int, db: Session = Depends(get_db)):
    success = crud.delete_noticia(db, noticia_id=noticia_id)
    if not success:
        raise HTTPException(status_code=404, detail="Noticia no encontrada")
    return None