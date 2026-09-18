from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import crud
import schemas
from database import get_db
from auth import crear_token, obtener_admin_actual, obtener_usuario_actual
import models

router = APIRouter()


def _verificar_acceso_usuario(usuario_id: int, usuario_actual: models.Usuario) -> None:
    if usuario_actual.id != usuario_id and usuario_actual.admin != 1:
        raise HTTPException(status_code=403, detail="No tienes permisos sobre este usuario")

@router.post("/login", response_model=schemas.LoginResponse, status_code=200)
def login(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    db_usuario = crud.authenticate_usuario(db, email=login_data.email, contrasena=login_data.contrasena)
    if not db_usuario:
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    token = crear_token(db_usuario.id, db_usuario.admin == 1)
    return schemas.LoginResponse(
        access_token=token,
        token_type="bearer",
        usuario=db_usuario
    )

@router.post("/", response_model=schemas.UsuarioResponse, status_code=201)
def create_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    if crud.usuario_exists_by_email(db, email=usuario.email):
        raise HTTPException(status_code=400, detail="Email ya registrado")
    return crud.create_usuario(db=db, usuario=usuario)

@router.get("/", response_model=List[schemas.UsuarioResponse])
def read_usuarios(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(obtener_admin_actual),
):
    return crud.get_usuarios(db, skip=skip, limit=limit)


@router.get("/{usuario_id}", response_model=schemas.UsuarioResponse)
def read_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _verificar_acceso_usuario(usuario_id, usuario_actual)
    db_usuario = crud.get_usuario(db, usuario_id=usuario_id)
    if db_usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return db_usuario

@router.put("/{usuario_id}", response_model=schemas.UsuarioResponse)
def update_usuario(
    usuario_id: int,
    usuario: schemas.UsuarioUpdate,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _verificar_acceso_usuario(usuario_id, usuario_actual)
    db_usuario = crud.update_usuario(db, usuario_id=usuario_id, usuario=usuario)
    if db_usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return db_usuario

@router.put("/{usuario_id}/change-password", response_model=schemas.UsuarioResponse)
def change_password(
    usuario_id: int,
    data: schemas.ChangePassword,
    db: Session = Depends(get_db),
    usuario_actual: models.Usuario = Depends(obtener_usuario_actual),
):
    _verificar_acceso_usuario(usuario_id, usuario_actual)
    try:
        return crud.change_password(
            db,
            usuario_id=usuario_id,
            contrasena_actual=data.contrasena_actual,
            contrasena_nueva=data.contrasena_nueva,
        )
    except ValueError as e:
        status = 404 if "no encontrado" in str(e) else 400
        raise HTTPException(status_code=status, detail=str(e))

@router.put("/admin/{usuario_id}", response_model=schemas.UsuarioResponse)
def update_admin_usuario(
    usuario_id: int,
    usuario: schemas.UsuarioUpdateAdmin,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(obtener_admin_actual),
):
    db_usuario = crud.update_admin_usuario(db, usuario_id=usuario_id, usuario=usuario)
    if db_usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return db_usuario

@router.delete("/{usuario_id}", status_code=204)
def delete_usuario(
    usuario_id: int,
    db: Session = Depends(get_db),
    admin: models.Usuario = Depends(obtener_admin_actual),
):
    success = crud.delete_usuario(db, usuario_id=usuario_id)
    if not success:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return None
