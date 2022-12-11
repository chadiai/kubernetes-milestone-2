from fastapi import FastAPI
from pymongo import MongoClient
from fastapi.middleware.cors import CORSMiddleware

## Connect to MongoDB Compass
client = MongoClient("mongodb://10.0.0.51:30300")

db = client['milestone']
user_col = db['users']

init = {'id': 1, 'name': '-1'}
user_col.insert_one(init)

app = FastAPI()

origins = [
    "http://10.0.0.50",
    "http://localhost",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


#test
@app.get('/hi/{name}', tags = ['Hello'])
def hi(name:str):
    return {'message': f'hello {name}'}

# Adding data to 'user_col' collection
@app.post("/create/{name}", tags = ['Post'])
def create_user(name:str):
    user = user_col.update_one( {'id': 1} ,{ "$set": {"name": name} })
    return {'message': f"updated name to {name}"}

# Query data from MongoDB
@app.get('/user', tags = ['Get'])
def read_user(): # for response status code
    result = user_col.find_one({'id': 1})
    name = result.get('name')
    return {'name': name}
