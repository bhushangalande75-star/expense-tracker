import uuid
import datetime as dt
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from .. import crud, schemas
from ..database import get_db

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.get("/export")
async def export_expenses(
    start: dt.date | None = None,
    end: dt.date | None = None,
    db: AsyncSession = Depends(get_db),
):
    csv_text = await crud.export_expenses_csv(db, start, end)
    filename = "expenses_report.csv"
    return Response(
        content=csv_text,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.post("", response_model=schemas.ExpenseOut)
async def create_expense(payload: schemas.ExpenseCreate, db: AsyncSession = Depends(get_db)):
    return await crud.create_expense(db, payload)


@router.get("", response_model=list[schemas.ExpenseOut])
async def list_expenses(
    start: dt.date | None = None,
    end: dt.date | None = None,
    db: AsyncSession = Depends(get_db),
):
    return await crud.list_expenses(db, start, end)


@router.patch("/{expense_id}", response_model=schemas.ExpenseOut)
async def update_expense(
    expense_id: uuid.UUID, payload: schemas.ExpenseUpdate, db: AsyncSession = Depends(get_db)
):
    updated = await crud.update_expense(db, expense_id, payload)
    if not updated:
        raise HTTPException(status_code=404, detail="Expense not found")
    return updated


@router.delete("/{expense_id}")
async def delete_expense(expense_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    ok = await crud.delete_expense(db, expense_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Expense not found")
    return {"deleted": True}
