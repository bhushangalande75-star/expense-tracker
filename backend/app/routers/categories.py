from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from .. import crud, schemas
from ..database import get_db

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[schemas.CategoryOut])
async def list_categories(db: AsyncSession = Depends(get_db)):
    return await crud.get_categories(db)


@router.post("", response_model=schemas.CategoryOut)
async def create_category(payload: schemas.CategoryCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create_category(db, payload)
