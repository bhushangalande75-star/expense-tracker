import uuid
import datetime as dt
from collections import defaultdict

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from . import models, schemas

DEFAULT_CATEGORIES = [
    ("Investment", "trending_up", "#2E7D32"),
    ("RD / SIP", "savings", "#1565C0"),
    ("Groceries", "shopping_cart", "#D4AF37"),
    ("Vegetables", "eco", "#66BB6A"),
    ("Non-Veg", "set_meal", "#C62828"),
    ("Petrol / Fuel", "local_gas_station", "#EF6C00"),
    ("Rent / Maintenance", "home", "#6A1B9A"),
    ("Electricity / Water / Gas", "bolt", "#F9A825"),
    ("Mobile / Internet", "wifi", "#0097A7"),
    ("Dining Out", "restaurant", "#AD1457"),
    ("Entertainment", "movie", "#5E35B1"),
    ("Healthcare", "local_hospital", "#00897B"),
    ("Shopping / Clothing", "checkroom", "#8E24AA"),
    ("Education", "school", "#3949AB"),
    ("Insurance", "shield", "#455A64"),
    ("EMI / Loan", "credit_card", "#BF360C"),
    ("Travel", "flight", "#00695C"),
    ("Miscellaneous", "more_horiz", "#757575"),
]


async def seed_default_categories(db: AsyncSession):
    existing = (await db.execute(select(models.Category.name))).scalars().all()
    existing_set = set(existing)
    for name, icon, color in DEFAULT_CATEGORIES:
        if name not in existing_set:
            db.add(models.Category(name=name, icon=icon, color_hex=color, is_default=True))
    await db.commit()


async def get_categories(db: AsyncSession):
    result = await db.execute(select(models.Category).order_by(models.Category.name))
    return result.scalars().all()


async def create_category(db: AsyncSession, payload: schemas.CategoryCreate):
    cat = models.Category(**payload.model_dump())
    db.add(cat)
    await db.commit()
    await db.refresh(cat)
    return cat


async def create_expense(db: AsyncSession, payload: schemas.ExpenseCreate):
    expense = models.Expense(**payload.model_dump())
    db.add(expense)
    await db.commit()
    result = await db.execute(
        select(models.Expense)
        .options(selectinload(models.Expense.category))
        .where(models.Expense.id == expense.id)
    )
    return result.scalar_one()


async def list_expenses(
    db: AsyncSession, start: dt.date | None = None, end: dt.date | None = None
):
    stmt = select(models.Expense).options(selectinload(models.Expense.category))
    if start:
        stmt = stmt.where(models.Expense.expense_date >= start)
    if end:
        stmt = stmt.where(models.Expense.expense_date <= end)
    stmt = stmt.order_by(models.Expense.expense_date.desc(), models.Expense.created_at.desc())
    result = await db.execute(stmt)
    return result.scalars().all()


async def update_expense(db: AsyncSession, expense_id: uuid.UUID, payload: schemas.ExpenseUpdate):
    result = await db.execute(select(models.Expense).where(models.Expense.id == expense_id))
    expense = result.scalar_one_or_none()
    if not expense:
        return None
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(expense, field, value)
    await db.commit()
    result = await db.execute(
        select(models.Expense)
        .options(selectinload(models.Expense.category))
        .where(models.Expense.id == expense_id)
    )
    return result.scalar_one()


async def delete_expense(db: AsyncSession, expense_id: uuid.UUID) -> bool:
    result = await db.execute(delete(models.Expense).where(models.Expense.id == expense_id))
    await db.commit()
    return result.rowcount > 0


def _bucket_label(period: str, d: dt.date) -> str:
    if period == "daily":
        return d.isoformat()
    if period == "weekly":
        iso = d.isocalendar()
        return f"{iso.year}-W{iso.week:02d}"
    if period == "monthly":
        return d.strftime("%Y-%m")
    if period == "yearly":
        return str(d.year)
    raise ValueError("invalid period")


async def get_dashboard(
    db: AsyncSession, period: str, start: dt.date | None, end: dt.date | None
) -> schemas.DashboardResponse:
    expenses = await list_expenses(db, start, end)

    bucket_totals: dict[str, float] = defaultdict(float)
    bucket_by_cat: dict[str, dict[str, float]] = defaultdict(lambda: defaultdict(float))

    for e in expenses:
        label = _bucket_label(period, e.expense_date)
        amount = float(e.amount)
        bucket_totals[label] += amount
        bucket_by_cat[label][e.category.name] += amount

    buckets = [
        schemas.DashboardBucket(label=label, total=total, by_category=dict(bucket_by_cat[label]))
        for label, total in sorted(bucket_totals.items())
    ]
    grand_total = sum(bucket_totals.values())

    return schemas.DashboardResponse(period=period, buckets=buckets, grand_total=grand_total)
