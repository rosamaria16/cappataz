from contextlib import asynccontextmanager
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from seed import create_tables
import uvicorn
from routers import dias, hermandades, infopasos, usuarios, itinerarios, noticias, emisoras, admin

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_tables()
    yield

app = FastAPI(lifespan=lifespan)

_default_origins = "http://localhost:3000,http://127.0.0.1:3000"
allowed_origins = [o.strip() for o in os.getenv("ALLOWED_ORIGINS", _default_origins).split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1):\d+",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Semana Santa Sevilla"}

app.include_router(dias.router, prefix="/api/v1/dias", tags=["Días"])
app.include_router(hermandades.router, prefix="/api/v1/hermandades", tags=["Hermandades"])
app.include_router(infopasos.router, prefix="/api/v1/infopasos", tags=["InfoPasos"])
app.include_router(usuarios.router, prefix="/api/v1/usuarios", tags=["Usuarios"])
app.include_router(itinerarios.router, prefix="/api/v1/itinerarios", tags=["Itinerarios"])
app.include_router(noticias.router, prefix="/api/v1/noticias", tags=["Noticias"])
app.include_router(emisoras.router, prefix="/api/v1/emisoras", tags=["Emisoras"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin"])

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)