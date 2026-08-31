import uuid
import datetime as dt
from sqlalchemy import String, Numeric, ForeignKey, Date, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    icon: Mapped[str] = mapped_column(String(32), default="category")  # maps to a Flutter icon key
    color_hex: Mapped[str] = mapped_column(String(9), default="#D4AF37")  # luxurious gold default
    is_default: Mapped[bool] = mapped_column(default=False)

    expenses: Mapped[list["Expense"]] = relationship(back_populates="category")


class Expense(Base):
    __tablename__ = "expenses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    category_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("categories.id"), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    expense_date: Mapped[dt.date] = mapped_column(Date, nullable=False, default=dt.date.today)
    created_at: Mapped[dt.datetime] = mapped_column(DateTime(timezone=True), default=dt.datetime.utcnow)

    category: Mapped["Category"] = relationship(back_populates="expenses")
