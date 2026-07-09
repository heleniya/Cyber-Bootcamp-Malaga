import requests
from fastapi import  HTTPException, APIRouter
from model.dtos import ProductDto, StockDto
from urllib.parse import urlencode
import os

PRODUCT_URL = os.environ.get('PRODUCT_API_URL', 'http://localhost:8081/products') 
GET_PRODUCT = f"{PRODUCT_URL}/products"
CREATE_PRODUCT = f"{PRODUCT_URL}/create"
UPDATE_PRODUCT = f"{PRODUCT_URL}/update"
GET_STOCK = f"{PRODUCT_URL}/stock"
HEADERS = {"Content-Type": "application/json"}

router = APIRouter()


@router.get("/products")
def get_products(categoria: str  = None, precioMin: float  = None, precioMax: float  = None):

    params = {}

    if categoria is not None:
        params["categoria"] = categoria
    if precioMin is not None:
        params["precioMin"] = precioMin
    if precioMax is not None:
        params["precioMax"] = precioMax


    query_string = urlencode(params)
    
    url = f"{GET_PRODUCT}?{query_string}"

    products = requests.get(url)

    if products.status_code == 200:
        return products.json()  
    else:
        raise HTTPException(products.status_code, detail="Error fetching api "+products.text)
    
@router.post("/create")
def create_product(product: ProductDto):

    product_response = requests.post(CREATE_PRODUCT, json=product.model_dump(), headers=HEADERS)

    if product_response.status_code == 200:
        return product_response.json()  
    else:
        raise HTTPException(product_response.status_code, detail="Error fetching api "+product_response.text)

@router.put("/update")
def update_product(product: ProductDto):

    product_response = requests.put(UPDATE_PRODUCT, json=product.model_dump(), headers=HEADERS)

    if product_response.status_code == 200:
        return product_response.json()  
    else:
        raise HTTPException(product_response.status_code, detail="Error fetching api "+product_response.text)


@router.post("/stock/{productId}")
def get_stock(productId):
    url = f"{GET_STOCK}/{productId}"
    product_response = requests.get(url, headers=HEADERS)

    if product_response.status_code == 200:
        return product_response.json()  
    else:
        raise HTTPException(product_response.status_code, detail="Error fetching api "+product_response.text)
