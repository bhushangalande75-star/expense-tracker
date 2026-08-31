import datetime as dt
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .database import engine, Base, AsyncSessionLocal
from .routers import expenses, categories, dashboard
from . import crud

app = FastAPI(title="Expense Tracker API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten this once the app is stable
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(expenses.router)
app.include_router(categories.router)
app.include_router(dashboard.router)


@app.on_event("startup")
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await crud.seed_default_categories(session)


@app.get("/")
async def root():
    return {"status": "ok", "service": "expense-tracker-api"}


@app.get("/health")
async def health():
    """
    Hit by the keep-alive workflow every few minutes.
    Runs a trivial query so it also touches Neon and resets its idle timer,
    not just the Render web service's idle timer.
    """
    async with AsyncSessionLocal() as session:
        await session.execute(text("SELECT 1"))
    return {"status": "awake", "time": dt.datetime.utcnow().isoformat()}
