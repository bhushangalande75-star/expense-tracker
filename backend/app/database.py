import os
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

# Neon gives you a plain psycopg-style URL, e.g.
# postgresql://user:pass@host/db?sslmode=require&channel_binding=require
# asyncpg doesn't understand psycopg-only query params like "sslmode" or
# "channel_binding", so we strip any of those out and pass SSL via
# connect_args instead.
_PSYCOPG_ONLY_PARAMS = {"sslmode", "channel_binding", "options", "gssencmode"}

_raw_url = os.environ.get("DATABASE_URL", "")
if not _raw_url:
    raise RuntimeError("DATABASE_URL environment variable is not set")

_raw_url = _raw_url.replace("postgresql://", "postgresql+asyncpg://", 1)

_parts = urlsplit(_raw_url)
_query_pairs = [(k, v) for k, v in parse_qsl(_parts.query) if k.lower() not in _PSYCOPG_ONLY_PARAMS]
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
