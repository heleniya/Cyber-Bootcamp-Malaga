import requests
from fastapi import  HTTPException, APIRouter
from model.dtos import UserDto
import os


USER_URL = os.environ.get('USER_API_URL', 'http://localhost:8080/users') 
GET_USERS = f"{USER_URL}/users"
CREATE_USER = f"{USER_URL}/create"
UPDATE_USER = f"{USER_URL}/update"
GET_USER = f"{USER_URL}/users"
DELETE_USERS = f"{USER_URL}/user"
CREATE_USER_CSV = f"{USER_URL}/create-user-csv"

HEADERS = {"Content-Type": "application/json"}

USER_CSV_PATH = os.environ.get('user_csv_path', './data/usuarios.csv')  

router = APIRouter()


@router.get("/users")
def get_users():
    response = requests.get(GET_USERS)

    if response.status_code == 200:
        return response.json()
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)


@router.post("/create")
def create_user(user: UserDto):
   
    response = requests.post(CREATE_USER, json=user.model_dump(), headers=HEADERS)

    if response.status_code == 200:
        return response.json()  
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)

@router.post("/update")
def update_user(user: UserDto):
    response = requests.put(UPDATE_USER, json=user.model_dump(), headers=HEADERS)

    if response.status_code == 200:
        return response.json()  
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)


@router.get("/users/{user_id}")
def get_user(user_id):
    url = f"{GET_USER}/{user_id}"
    response = requests.get(url, headers=HEADERS)

    if response.status_code == 200:
        return response.json()  
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)


@router.delete("/delete/{user_id}")
def delete_user(user_id):

    url = f"{DELETE_USERS}/{user_id}"
    response = requests.delete(url, headers=HEADERS)

    if response.status_code == 200:
        return response.json()  
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)

@router.post("/create-user-csv")
def create_user(user: UserDto):
    response = requests.post(CREATE_USER_CSV, json=user.model_dump(), headers=HEADERS)

    if response.status_code == 200:
        return response.json()  
    else:
        raise HTTPException(response.status_code, detail="Error fetching api "+response.text)
    
@router.get("/users-csv")
def get_users_csv():
    users = []

    with open(USER_CSV_PATH, newline='') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',', quotechar='"')
        print(spamreader)
      
        for row in spamreader:
            user = UserDto(id=row[0] ,nombre=row[1], apellido=row[2], email=row[3])
            users.append(user)

    return users
