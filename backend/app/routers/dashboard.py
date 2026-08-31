import datetime as dt
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from .. import crud, schemas
from ..database import get_db

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

VALID_PERIODS = {"daily", "weekly", "monthly", "yearly"}


@router.get("/{period}", response_model=schemas.DashboardResponse)
async def get_dashboard(
    period: str,
    start: dt.date | None = Query(None),
    end: dt.date | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    if period not in VALID_PERIODS:
        period = "monthly"
    return await crud.get_dashboard(db, period, start, end)
