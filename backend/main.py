from fastapi import FastAPI
from backend.database import Base, engine
from backend.models import *

app = FastAPI()

Base.metadata.create_all(bind=engine)

@app.get("/")
def read_root():
    return {"Hello": "World"}
