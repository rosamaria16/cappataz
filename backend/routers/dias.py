from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import obtener_admin_actual

router = APIRouter()


@router.get("/", response_model=List[schemas.DiaResponse])
def read_dias(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_dias(db, skip=skip, limit=limit)


@router.get("/{dia_id}", response_model=schemas.DiaResponse)
def read_dia(dia_id: int, db: Session = Depends(get_db)):
    db_dia = crud.get_dia(db, dia_id=dia_id)
    if db_dia is None:
        raise HTTPException(status_code=404, detail="Día no encontrado")
    return db_dia


@router.post("/", response_model=schemas.DiaResponse, status_code=201, dependencies=[Depends(obtener_admin_actual)])
def create_dia(dia: schemas.DiaCreate, db: Session = Depends(get_db)):
    return crud.create_dia(db=db, dia=dia)


@router.put("/{dia_id}", response_model=schemas.DiaResponse, dependencies=[Depends(obtener_admin_actual)])
def update_dia(dia_id: int, dia: schemas.DiaUpdate, db: Session = Depends(get_db)):
    db_dia = crud.update_dia(db, dia_id=dia_id, dia=dia)
    if db_dia is None:
        raise HTTPException(status_code=404, detail="Día no encontrado")
    return db_dia


@router.delete("/{dia_id}", status_code=204, dependencies=[Depends(obtener_admin_actual)])
def delete_dia(dia_id: int, db: Session = Depends(get_db)):
    success = crud.delete_dia(db, dia_id=dia_id)
    if not success:
        raise HTTPException(status_code=404, detail="Día no encontrado")
    return None
