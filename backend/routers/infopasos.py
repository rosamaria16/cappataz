from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import obtener_admin_actual

router = APIRouter()


@router.get("/", response_model=List[schemas.InfoPasoResponse])
def read_infopasos(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return crud.get_infopasos(db, skip=skip, limit=limit)


@router.get("/{infopaso_id}", response_model=schemas.InfoPasoResponse)
def read_infopaso(infopaso_id: int, db: Session = Depends(get_db)):
    db_infopaso = crud.get_infopaso(db, infopaso_id=infopaso_id)
    if db_infopaso is None:
        raise HTTPException(status_code=404, detail="InfoPaso no encontrado")
    return db_infopaso


@router.get("/hermandad/{hermandad_id}", response_model=List[schemas.InfoPasoResponse])
def read_infopasos_by_hermandad(hermandad_id: int, db: Session = Depends(get_db)):
    return crud.get_infopasos_by_hermandad(db, hermandad_id=hermandad_id)


@router.post("/", response_model=schemas.InfoPasoResponse, status_code=201, dependencies=[Depends(obtener_admin_actual)])
def create_infopaso(infopaso: schemas.InfoPasoCreate, db: Session = Depends(get_db)):
    return crud.create_infopaso(db=db, infopaso=infopaso)


@router.put("/{infopaso_id}", response_model=schemas.InfoPasoResponse,dependencies=[Depends(obtener_admin_actual)])
def update_infopaso(infopaso_id: int, infopaso: schemas.InfoPasoUpdate, db: Session = Depends(get_db)):
    db_infopaso = crud.update_infopaso(db, infopaso_id=infopaso_id, infopaso=infopaso)
    if db_infopaso is None:
        raise HTTPException(status_code=404, detail="InfoPaso no encontrado")
    return db_infopaso


@router.delete("/{infopaso_id}", status_code=204,dependencies=[Depends(obtener_admin_actual)])
def delete_infopaso(infopaso_id: int, db: Session = Depends(get_db)):
    success = crud.delete_infopaso(db, infopaso_id=infopaso_id)
    if not success:
        raise HTTPException(status_code=404, detail="InfoPaso no encontrado")
    return None

@router.get("/dia/{dia_id}", response_model=List[schemas.InfoPasoResponse])
def read_infopasos_by_dia(dia_id: int, db: Session = Depends(get_db)):
    return crud.get_infopasos_by_dia(db, dia_id=dia_id)

@router.get("/dia/{dia_id}/hermandad/{hermandad_id}", response_model=List[schemas.InfoPasoResponse])
def read_infopasos_by_dia_and_hermandad(dia_id: int, hermandad_id: int, db: Session = Depends(get_db)):
    return crud.get_infopasos_by_dia_and_hermandad(db, dia_id=dia_id, hermandad_id=hermandad_id)