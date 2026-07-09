from fastapi import FastAPI
from controller import usuarios, productos
import uvicorn

app = FastAPI()

app.include_router(usuarios.router, prefix="/usuarios", tags=["Usuarios"])
app.include_router(productos.router, prefix="/products", tags=["Productos"])


def main():
    uvicorn.run("main:app", app_dir="src", host="0.0.0.0", port=8000, reload=True)

if __name__ == "__main__":
    main()

