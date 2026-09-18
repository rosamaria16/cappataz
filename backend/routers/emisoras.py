from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import obtener_admin_actual

router = APIRouter()


@router.get("/", response_model=List[schemas.EmisoraResponse])
def read_emisoras(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_emisoras(db, skip=skip, limit=limit)


@router.get("/{emisora_id}", response_model=schemas.EmisoraResponse)
def read_emisora(emisora_id: int, db: Session = Depends(get_db)):
    db_emisora = crud.get_emisora(db, emisora_id=emisora_id)
    if db_emisora is None:
        raise HTTPException(status_code=404, detail="Emisora no encontrada")
    return db_emisora


@router.post("/", response_model=schemas.EmisoraResponse, status_code=201, dependencies=[Depends(obtener_admin_actual)])
def create_emisora(emisora: schemas.EmisoraCreate, db: Session = Depends(get_db)):
    return crud.create_emisora(db=db, emisora=emisora)


@router.put(
    "/{emisora_id}",
    response_model=schemas.EmisoraResponse,
    dependencies=[Depends(obtener_admin_actual)],
)
def update_emisora(emisora_id: int, emisora: schemas.EmisoraUpdate, db: Session = Depends(get_db)):
    db_emisora = crud.update_emisora(db, emisora_id=emisora_id, emisora=emisora)
    if db_emisora is None:
        raise HTTPException(status_code=404, detail="Emisora no encontrada")
    return db_emisora


@router.delete(
    "/{emisora_id}",
    status_code=204,
    dependencies=[Depends(obtener_admin_actual)],
)
def delete_emisora(emisora_id: int, db: Session = Depends(get_db)):
    success = crud.delete_emisora(db, emisora_id=emisora_id)
    if not success:
        raise HTTPException(status_code=404, detail="Emisora no encontrada")
    return None
