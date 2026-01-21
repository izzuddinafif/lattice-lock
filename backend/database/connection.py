"""
Database connection and session management for LatticeLock
Async PostgreSQL support using SQLAlchemy + asyncpg
"""

import os
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy.pool import NullPool
from contextlib import asynccontextmanager
import logging

from .models import Base

logger = logging.getLogger(__name__)

# Database URL from environment variable or default
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://latticelock:latticelock_pass@localhost:5432/latticelock"
)

# Create async engine
engine = create_async_engine(
    DATABASE_URL,
    echo=os.getenv("DATABASE_DEBUG", "false").lower() == "true",
    pool_pre_ping=True,  # Verify connections before using
    pool_size=10,  # Number of connections to maintain
    max_overflow=20,  # Additional connections allowed beyond pool_size
)

# Create async session factory
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency injection for database sessions.

    Usage in FastAPI:
        @app.get("/patterns")
        async def get_patterns(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(Pattern))
            return result.scalars().all()
    """
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@asynccontextmanager
async def get_db_context() -> AsyncGenerator[AsyncSession, None]:
    """
    Context manager for database sessions.

    Usage:
        async with get_db_context() as db:
            result = await db.execute(select(Pattern))
            patterns = result.scalars().all()
    """
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """
    Initialize database - create all tables.

    Call this on application startup:
        @app.on_event("startup")
        async def startup():
            await init_db()
    """
    try:
        async with engine.begin() as conn:
            # Import all models here to ensure they're registered with Base
            from .models import MaterialProfile, Pattern, VerificationLog

            # Create all tables
            await conn.run_sync(Base.metadata.create_all)

            logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        raise


async def close_db() -> None:
    """
    Close database connections.

    Call this on application shutdown:
        @app.on_event("shutdown")
        async def shutdown():
            await close_db()
    """
    try:
        await engine.dispose()
        logger.info("Database connections closed")
    except Exception as e:
        logger.error(f"Error closing database: {e}")


async def check_db_connection() -> bool:
    """
    Check if database connection is working.

    Returns:
        bool: True if connection successful, False otherwise
    """
    try:
        async with engine.connect() as conn:
            await conn.execute("SELECT 1")
        logger.info("Database connection check successful")
        return True
    except Exception as e:
        logger.error(f"Database connection check failed: {e}")
        return False
