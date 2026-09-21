import csv
from datetime import time
from io import StringIO


def hora_a_minutos(hora: time) -> int:
    return hora.hour * 60 + hora.minute

def rellenar_franjas(registros: list[dict]) -> list[dict]:
    grupos = {}
    for entrada in registros:
        clave = (entrada['idHermandad'], entrada['tipoPaso'])
        grupos.setdefault(clave, []).append(entrada)

    resultado = []
    for entradas in grupos.values():
        relleno = []
        for actual, siguiente in zip(entradas, entradas[1:]):
            inicio = hora_a_minutos(actual['hora'])
            fin = hora_a_minutos(siguiente['hora'])
            if fin <= inicio:
                fin += 1440
            for minutos in range(inicio + 30, fin, 30):
                minutos_del_dia = minutos % 1440
                relleno.append({
                    **actual,
                    'hora': time(minutos_del_dia // 60, minutos_del_dia % 60),
                    'difHora': None,
                })
        resultado.extend(sorted(entradas + relleno, key=lambda e: hora_a_minutos(e['hora'])))
    return resultado

def leer_infopasos_csv(csv_content: str) -> list[dict]:
    
    try:
        filas = list(csv.reader(StringIO(csv_content.strip()), delimiter=";", strict=True))
    except csv.Error as error:
        raise ValueError("Formato CSV incorrecto") from error
    if len(filas) < 2:
        raise ValueError("El CSV debe tener al menos una cabecera y una fila de datos")
    
    header = filas[0]
    expected = ["idHermandad", "tipoPaso", "hora", "localizacion", "difHora", "esCarreraOficial"]
    if header != expected:
        raise ValueError(f"Cabecera incorrecta. Se esperaba: {';'.join(expected)}")
    
    tipos_paso_validos = ["CRUZGUIA", "PALIO", "DUELO", "PASO"]
    registros = []
    
    for i, campos in enumerate(filas[1:], start=2):
        if not campos or (len(campos) == 1 and not campos[0].strip()):
            continue
        
        if len(campos) != 6:
            raise ValueError(f"Línea {i}: se esperaban 6 campos, se encontraron {len(campos)}")
        
        id_hermandad_str = campos[0].strip()
        tipo_paso = campos[1].strip().upper()
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
            raise ValueError(f"Línea {i}: hora debe tener formato HH:MM")
        
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
                raise ValueError(f"Línea {i}: difHora debe tener formato HH:MM o estar vacío")
        
        if es_carrera_oficial:
            if es_carrera_oficial not in ("0", "1"):
                raise ValueError(f"Línea {i}: esCarreraOficial debe ser 0, 1 o estar vacío")
            es_carrera_oficial = int(es_carrera_oficial)
        else:
            es_carrera_oficial = 0
        
        infopaso = dict(
            idHermandad=id_hermandad,
            tipoPaso=tipo_paso,
            hora=hora,
            localizacion=localizacion,
            difHora=dif_hora,
            esCarreraOficial=es_carrera_oficial,
        )
        registros.append(infopaso)
    
    return rellenar_franjas(registros)