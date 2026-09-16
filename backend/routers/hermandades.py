from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import obtener_admin_actual

router = APIRouter()


@router.get("/", response_model=List[schemas.HermandadResponse])
def read_hermandades(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_hermandades(db, skip=skip, limit=limit)


@router.get("/{hermandad_id}", response_model=schemas.HermandadResponse)
def read_hermandad(hermandad_id: int, db: Session = Depends(get_db)):
    db_hermandad = crud.get_hermandad(db, hermandad_id=hermandad_id)
    if db_hermandad is None:
        raise HTTPException(status_code=404, detail="Hermandad no encontrada")
    return db_hermandad


@router.get("/dia/{dia_id}", response_model=List[schemas.HermandadResponse])
def read_hermandades_by_dia(dia_id: int, db: Session = Depends(get_db)):
    return crud.get_hermandades_by_dia(db, dia_id=dia_id)


@router.post("/", response_model=schemas.HermandadResponse, status_code=201, dependencies=[Depends(obtener_admin_actual)])
def create_hermandad(hermandad: schemas.HermandadCreate, db: Session = Depends(get_db)):
    return crud.create_hermandad(db=db, hermandad=hermandad)


@router.put("/{hermandad_id}", response_model=schemas.HermandadResponse, dependencies=[Depends(obtener_admin_actual)])
def update_hermandad(hermandad_id: int, hermandad: schemas.HermandadUpdate, db: Session = Depends(get_db)):
    db_hermandad = crud.update_hermandad(db, hermandad_id=hermandad_id, hermandad=hermandad)
    if db_hermandad is None:
        raise HTTPException(status_code=404, detail="Hermandad no encontrada")
    return db_hermandad


@router.delete("/{hermandad_id}", status_code=204, dependencies=[Depends(obtener_admin_actual)])
def delete_hermandad(hermandad_id: int, db: Session = Depends(get_db)):
    success = crud.delete_hermandad(db, hermandad_id=hermandad_id)
    if not success:
        raise HTTPException(status_code=404, detail="Hermandad no encontrada")
    return None
