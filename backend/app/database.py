import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

# Example Neon connection string (set as env var DATABASE_URL on Render):
# postgresql+asyncpg://<user>:<password>@<host>/<dbname>?ssl=require
DATABASE_URL = os.environ.get("DATABASE_URL", "").replace(
    "postgresql://", "postgresql+asyncpg://", 1
)

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set")

# pool_pre_ping guards against Neon closing idle connections during autosuspend
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=5,
    pool_recycle=300,
)

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
