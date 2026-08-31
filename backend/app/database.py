import os
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

# Neon gives you a plain psycopg-style URL, e.g.
# postgresql://user:pass@host/db?sslmode=require
# asyncpg doesn't understand "sslmode" as a query param (that's a psycopg2 thing),
# so we strip it out here and pass SSL via connect_args instead.
_raw_url = os.environ.get("DATABASE_URL", "")
if not _raw_url:
    raise RuntimeError("DATABASE_URL environment variable is not set")

_raw_url = _raw_url.replace("postgresql://", "postgresql+asyncpg://", 1)

_parts = urlsplit(_raw_url)
_query_pairs = [(k, v) for k, v in parse_qsl(_parts.query) if k.lower() != "sslmode"]
DATABASE_URL = urlunsplit(
    (_parts.scheme, _parts.netloc, _parts.path, urlencode(_query_pairs), _parts.fragment)
)

# pool_pre_ping guards against Neon closing idle connections during autosuspend
engine = create_async_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=5,
    pool_recycle=300,
    connect_args={"ssl": "require"},
)

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
