from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, Time, Enum, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime, time
import enum
from database import Base


class TipoPaso(enum.Enum):
    CRUZGUIA = "CRUZGUIA"
    PALIO = "PALIO"
    DUELO = "DUELO"
    PASO = "PASO"

class Usuario(Base):
    __tablename__ = "usuarios"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    admin = Column(Integer, default=0, nullable=False)
    contrasena = Column(String(255), nullable=False)
    
    itinerario = relationship("Itinerario", back_populates="usuario", uselist=False)


class Itinerario(Base):
    __tablename__ = "itinerarios"
    
    id = Column(Integer, primary_key=True, index=True)
    idUsuario = Column(Integer, ForeignKey("usuarios.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    usuario = relationship("Usuario", back_populates="itinerario")
    items = relationship("ItemItinerario", back_populates="itinerario", cascade="all, delete-orphan")
    dias = relationship("DiaItinerario", back_populates="itinerario", cascade="all, delete-orphan")


class DiaItinerario(Base):
    __tablename__ = "dias_itinerario"
    
    id = Column(Integer, primary_key=True, index=True)
    idItinerario = Column(Integer, ForeignKey("itinerarios.id", ondelete="CASCADE"), nullable=False)
    idDia = Column(Integer, ForeignKey("dias.id"), nullable=False)
    
    __table_args__ = (
        UniqueConstraint("idItinerario", "idDia", name="uq_itinerario_dia"),
    )
    
    itinerario = relationship("Itinerario", back_populates="dias")
    dia = relationship("Dia")

class ItemItinerario(Base):
    __tablename__ = "items_itinerario"
    
    id = Column(Integer, primary_key=True, index=True)
    idItinerario = Column(Integer, ForeignKey("itinerarios.id", ondelete="CASCADE"), nullable=False)
    idInfoPaso = Column(Integer, ForeignKey("infopaso.id"), nullable=False)
    
    __table_args__ = (
        UniqueConstraint("idItinerario", "idInfoPaso", name="uq_itinerario_infopaso"),
    )
    
    itinerario = relationship("Itinerario", back_populates="items")
    infopaso = relationship("InfoPaso")

class Noticia(Base):
    __tablename__ = "noticias"
    
    id = Column(Integer, primary_key=True, index=True)
    titular = Column(String(255), nullable=False)
    contenido = Column(Text, nullable=False)
    url_imagen = Column(String(500), nullable=False)
    origen = Column(String(50), nullable=False)
    fecha = Column(DateTime, default=datetime.utcnow, nullable=False)

class ResumenNoticias(Base):
    __tablename__ = "resumenes"
    
    id = Column(Integer, primary_key=True, index=True)
    resumen = Column(Text, nullable=False)
    modelo = Column(String(50), nullable=False)
    fecha_actualizacion = Column(DateTime, nullable=False)
    
class Emisora(Base):
    __tablename__ = "emisoras"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    urlStream = Column(String(500), nullable=False)
    urlImagen = Column(String(500), nullable=False)

class Dia(Base):
    __tablename__ = "dias"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(50), nullable=False)
    fecha = Column(DateTime, nullable=False)
    
    hermandades = relationship("Hermandad", back_populates="dia")

class Hermandad(Base):
    __tablename__ = "hermandades"
    
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    idDia = Column(Integer, ForeignKey("dias.id"), nullable=False)
    
    infopasos = relationship("InfoPaso", back_populates="hermandad")
    dia = relationship("Dia", back_populates="hermandades")


class InfoPaso(Base):
    __tablename__ = "infopaso"
    
    id = Column(Integer, primary_key=True, index=True)
    hora = Column(Time, nullable=False)
    tipoPaso = Column(Enum(TipoPaso), nullable=False)
    localizacion = Column(String(255), nullable=False)
    idHermandad = Column(Integer, ForeignKey("hermandades.id"), nullable=False)
    difHora = Column(Time, nullable=True)
    esCarreraOficial = Column(Integer, default=0, nullable=False)
    
    hermandad = relationship("Hermandad", back_populates="infopasos")
    

