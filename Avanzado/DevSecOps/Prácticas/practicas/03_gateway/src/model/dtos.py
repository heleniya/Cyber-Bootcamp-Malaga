from pydantic import BaseModel

class ProductDto(BaseModel):
    id: int
    nombre: str
    descripcion: str
    precio: float
    categoria: str
    stock: int
    activo: bool

class StockDto(BaseModel):
    id: int
    stock: int

class UserDto(BaseModel):
    id: int
    nombre: str
    apellido: str
    email: str