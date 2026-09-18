from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from datetime import timedelta
import crud
import schemas
import models
from database import get_db
from auth import obtener_admin_actual

router = APIRouter()

MAX_CSV_SIZE_BYTES = 5 * 1024 * 1024


async def _read_csv_upload(file: UploadFile) -> str:
    filename = file.filename or ""
    if not filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="El archivo debe ser un CSV")

    contenido = await file.read(MAX_CSV_SIZE_BYTES + 1)
    if len(contenido) > MAX_CSV_SIZE_BYTES:
        raise HTTPException(status_code=413, detail="El archivo CSV es demasiado grande")

    try:
        return contenido.decode("utf-8")
    except UnicodeDecodeError:
        raise HTTPException(status_code=400, detail="El archivo no tiene codificación UTF-8 válida")


@router.get("/dias", response_model=List[schemas.DiaResponse])
def listar_dias(
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    return crud.get_dias(db)


@router.put("/dias/fecha-inicio", response_model=schemas.DiasActualizarFechaInicioResponse)
def actualizar_fechas_desde_inicio(
    datos: schemas.DiasActualizarFechaInicio,
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):

    dias = crud.get_dias(db)
    if not dias:
        raise HTTPException(status_code=404, detail="No hay días")

    dias_ordenados = sorted(dias, key=lambda d: d.id)

    #Madrugá y Viernes Santo comparten fecha, por eso se repite
    offsets = [0, 1, 2, 3, 4, 5, 6, 7, 7, 8, 9]

    if len(dias_ordenados) != len(offsets):
        offsets = list(range(len(dias_ordenados))) #fallback

    fecha_inicio = datos.fecha_inicio
    for i, dia in enumerate(dias_ordenados):
        nueva_fecha = fecha_inicio + timedelta(days=offsets[i])
        dia_update = schemas.DiaUpdate(fecha=nueva_fecha)
        crud.update_dia(db, dia_id=dia.id, dia=dia_update)

    return schemas.DiasActualizarFechaInicioResponse(
        mensaje=f"Se han actualizado {len(dias_ordenados)} fechas desde {fecha_inicio.strftime('%d/%m/%Y')}",
        dias_actualizados=len(dias_ordenados),
    )

@router.post("/upload-infopasos", response_model=schemas.CargarInfoPasosResponse)
async def upload_infopasos(
    file: UploadFile = File(...),
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    csv_text = await _read_csv_upload(file)

    try:
        crud.clear_infopasos(db)
        total = crud.load_infopasos_from_csv(db, csv_text)
        db.commit()
    except ValueError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="No se pudo cargar el archivo CSV")

    return schemas.CargarInfoPasosResponse(
        mensaje=f"Se cargaron {total} registros correctamente",
        registros_cargados=total,
    )


@router.post("/upload-hermandades", response_model=schemas.CargarHermandadesResponse)
async def upload_hermandades(
    file: UploadFile = File(...),
    admin: models.Usuario = Depends(obtener_admin_actual),
    db: Session = Depends(get_db),
):
    csv_text = await _read_csv_upload(file)

    try:
        crud.clear_hermandades(db)
        total = crud.load_hermandades_from_csv(db, csv_text)
        db.commit()
    except ValueError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="No se pudo cargar el archivo CSV")

    return schemas.CargarHermandadesResponse(
        mensaje=f"Se cargaron {total} hermandades correctamente",
        registros_cargados=total,
    )
