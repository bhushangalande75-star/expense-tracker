import uuid
import datetime as dt
from pydantic import BaseModel, ConfigDict


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    name: str
    icon: str
    color_hex: str


class CategoryCreate(BaseModel):
    name: str
    icon: str = "category"
    color_hex: str = "#D4AF37"


class ExpenseCreate(BaseModel):
    category_id: uuid.UUID
    amount: float
    note: str | None = None
    expense_date: dt.date


class ExpenseUpdate(BaseModel):
    category_id: uuid.UUID | None = None
    amount: float | None = None
    note: str | None = None
    expense_date: dt.date | None = None


class ExpenseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    category: CategoryOut
    amount: float
    note: str | None
    expense_date: dt.date
    created_at: dt.datetime


class DashboardBucket(BaseModel):
    label: str          # e.g. "2026-08-31", "Week 35", "August 2026", "2026"
    total: float
    by_category: dict[str, float]


class DashboardResponse(BaseModel):
    period: str
    buckets: list[DashboardBucket]
    grand_total: float
