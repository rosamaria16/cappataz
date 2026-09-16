from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import obtener_admin_actual, obtener_usuario_actual
import models

router = APIRouter()


def _obtener_itinerario_propietario(
    itinerario_id: int,
    db: Session,
    usuario_actual: models.Usuario,
) -> models.Itinerario:
    db_itinerario = crud.get_itinerario(db, itinerario_id=itinerario_id)
    if db_itinerario is None:
        raise HTTPException(status_code=404, detail="Itinerario no encontrado")
    if db_itinerario.idUsuario != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No tienes permisos sobre este itinerario")
    return db_itinerario


@router.get("/", response_model=List[schemas.ItinerarioResponse])
def read_itinerarios(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(obtener_admin_actual),
):
    return crud.get_itinerarios(db, skip=skip, limit=limit)


@router.get("/{itinerario_id}", response_model=schemas.ItinerarioDetalleResponse)
def read_itinerario(
    itinerario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    db_itinerario = _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    return db_itinerario


@router.get("/usuario/{usuario_id}", response_model=schemas.ItinerarioDetalleResponse)
def read_itinerario_by_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    if usuario_id != usuario_actual.id:
        raise HTTPException(status_code=403, detail="No tienes permisos sobre este usuario")
    db_itinerario = crud.get_itinerario_by_usuario(db, usuario_id=usuario_id)
    if db_itinerario is None:
        raise HTTPException(status_code=404, detail="Itinerario no encontrado para este usuario")
    return db_itinerario


@router.post("/", response_model=schemas.ItinerarioResponse, status_code=201)
def create_itinerario(
    itinerario: schemas.ItinerarioCreate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    usuario_id = usuario_actual.id
    
    existente = crud.get_itinerario_by_usuario(db, usuario_id=usuario_id)
    if existente:
        raise HTTPException(status_code=400, detail="El usuario ya tiene un itinerario")
    itinerario_propio = schemas.ItinerarioCreate(idUsuario=usuario_id)
    return crud.create_itinerario(db=db, itinerario=itinerario_propio)


@router.delete("/{itinerario_id}", status_code=204)
def delete_itinerario(
    itinerario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    crud.delete_itinerario(db, itinerario_id=itinerario_id)
    return None


@router.get("/{itinerario_id}/items", response_model=List[schemas.ItemItinerarioResponse])
def read_items(
    itinerario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    return crud.get_items_by_itinerario(db, itinerario_id=itinerario_id)


@router.post("/{itinerario_id}/items", response_model=schemas.ItemItinerarioResponse, status_code=201)
def create_item(
    itinerario_id: int,
    item: schemas.ItemItinerarioCreate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    return crud.create_item_itinerario(db=db, itinerario_id=itinerario_id, item=item)


@router.delete("/{itinerario_id}/items/{item_id}", status_code=204)
def delete_item(
    itinerario_id: int,
    item_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    db_item = crud.get_item_itinerario(db, item_id=item_id)
    if db_item is None or db_item.idItinerario != itinerario_id:
        raise HTTPException(status_code=404, detail="Item no encontrado en este itinerario")
    crud.delete_item_itinerario(db, item_id=item_id)
    return None


@router.get("/{itinerario_id}/dias", response_model=List[schemas.DiaItinerarioResponse])
def read_dias_itinerario(
    itinerario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    return crud.get_dias_by_itinerario(db, itinerario_id=itinerario_id)


@router.post("/{itinerario_id}/dias", response_model=schemas.DiaItinerarioResponse, status_code=201)
def create_dia_itinerario(
    itinerario_id: int,
    dia: schemas.DiaItinerarioCreate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    db_dia = crud.get_dia(db, dia_id=dia.idDia)
    if db_dia is None:
        raise HTTPException(status_code=404, detail="Día no encontrado")
    return crud.create_dia_itinerario(db=db, itinerario_id=itinerario_id, dia=dia)


@router.delete("/{itinerario_id}/dias/{dia_itinerario_id}", status_code=204)
def delete_dia_itinerario(
    itinerario_id: int,
    dia_itinerario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _obtener_itinerario_propietario(itinerario_id, db, usuario_actual)
    dias = crud.get_dias_by_itinerario(db, itinerario_id=itinerario_id)
    dia_encontrado = next((d for d in dias if d.id == dia_itinerario_id), None)
    if dia_encontrado is None:
        raise HTTPException(status_code=404, detail="Día no encontrado en este itinerario")
    crud.delete_dia_itinerario(db, dia_itinerario_id=dia_itinerario_id)
    return None
