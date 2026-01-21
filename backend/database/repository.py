"""
Repository pattern for database operations
Provides high-level database access methods
"""

from typing import List, Optional, Dict, Any
from datetime import datetime
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
import logging

from .models import Pattern, MaterialProfile, VerificationLog
from .connection import get_db_context

logger = logging.getLogger(__name__)


class PatternRepository:
    """Repository for Pattern CRUD operations"""

    @staticmethod
    async def create_pattern(
        db: AsyncSession,
        input_text: str,
        algorithm: str,
        pattern: List[int],
        grid_size: int = 8,
        pattern_hash: Optional[str] = None,
        material_profile_id: Optional[int] = None,
        material_colors: Optional[Dict[str, Any]] = None,
        manufacturer_id: Optional[str] = None,
        additional_data: Optional[Dict[str, Any]] = None,
        signature: Optional[str] = None,
    ) -> Pattern:
        """Create a new pattern record"""
        pattern_obj = Pattern(
            input_text=input_text,
            algorithm=algorithm,
            pattern=pattern,
            grid_size=grid_size,
            pattern_hash=pattern_hash,
            material_profile_id=material_profile_id,
            material_colors=material_colors,
            timestamp=datetime.utcnow(),
            manufacturer_id=manufacturer_id,
            additional_data=additional_data,
            signature=signature,
        )

        db.add(pattern_obj)
        await db.flush()
        await db.refresh(pattern_obj)

        logger.info(f"Created pattern: {pattern_obj.uuid} for input: {input_text}")
        return pattern_obj

    @staticmethod
    async def get_pattern_by_uuid(db: AsyncSession, pattern_uuid: str) -> Optional[Pattern]:
        """Get pattern by UUID"""
        result = await db.execute(
            select(Pattern).where(Pattern.uuid == pattern_uuid)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def get_pattern_by_hash(db: AsyncSession, pattern_hash: str) -> Optional[Pattern]:
        """Get pattern by hash (for fast lookup)"""
        result = await db.execute(
            select(Pattern).where(Pattern.pattern_hash == pattern_hash)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def find_matching_patterns(
        db: AsyncSession,
        pattern: List[int],
        exact_match: bool = True,
        limit: int = 10,
    ) -> List[Pattern]:
        """
        Find patterns matching the given pattern array.

        Args:
            db: Database session
            pattern: Pattern array to match
            exact_match: If True, requires exact array match. If False, finds similar patterns.
            limit: Maximum number of results to return

        Returns:
            List of matching Pattern objects
        """
        if exact_match:
            # Exact match on pattern array
            result = await db.execute(
                select(Pattern)
                .where(Pattern.pattern == pattern)
                .order_by(Pattern.timestamp.desc())
                .limit(limit)
            )
        else:
            # Partial match - find patterns with some overlap
            # This is a simplified version - production might use more sophisticated similarity
            result = await db.execute(
                select(Pattern)
                .where(Pattern.pattern[0] == pattern[0])  # Match first element
                .order_by(Pattern.timestamp.desc())
                .limit(limit)
            )

        return list(result.scalars().all())

    @staticmethod
    async def get_patterns_by_input_text(
        db: AsyncSession,
        input_text: str,
        limit: int = 100,
    ) -> List[Pattern]:
        """Get all patterns for a given input text (batch code)"""
        result = await db.execute(
            select(Pattern)
            .where(Pattern.input_text == input_text)
            .order_by(Pattern.timestamp.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_recent_patterns(
        db: AsyncSession,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Pattern]:
        """Get recent patterns"""
        result = await db.execute(
            select(Pattern)
            .order_by(Pattern.timestamp.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_pattern_stats(db: AsyncSession) -> Dict[str, Any]:
        """Get pattern statistics"""
        from sqlalchemy import func

        result = await db.execute(
            select(
                func.count(Pattern.id).label("total"),
                func.count(func.distinct(Pattern.input_text)).label("unique_inputs"),
                func.count(func.distinct(Pattern.algorithm)).label("unique_algorithms"),
            )
        )
        row = result.one()

        return {
            "total_patterns": row.total,
            "unique_batch_codes": row.unique_inputs,
            "unique_algorithms": row.unique_algorithms,
        }


class VerificationRepository:
    """Repository for verification log operations"""

    @staticmethod
    async def create_verification_log(
        db: AsyncSession,
        pattern_input: List[int],
        found: bool,
        matched_pattern_id: Optional[int] = None,
        confidence: Optional[float] = None,
        algorithm: str = "auto-detect",
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        response_time_ms: Optional[int] = None,
    ) -> VerificationLog:
        """Create a verification log entry"""
        log = VerificationLog(
            pattern_input=pattern_input,
            found=found,
            matched_pattern_id=matched_pattern_id,
            confidence=confidence,
            algorithm=algorithm,
            ip_address=ip_address,
            user_agent=user_agent,
            response_time_ms=response_time_ms,
        )

        db.add(log)
        await db.flush()
        await db.refresh(log)

        logger.info(f"Created verification log: {log.uuid}, found: {found}")
        return log

    @staticmethod
    async def get_recent_verifications(
        db: AsyncSession,
        limit: int = 100,
        offset: int = 0,
    ) -> List[VerificationLog]:
        """Get recent verification logs"""
        result = await db.execute(
            select(VerificationLog)
            .order_by(VerificationLog.scanned_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_verification_stats(
        db: AsyncSession,
        days: int = 30,
    ) -> Dict[str, Any]:
        """Get verification statistics for the last N days"""
        from sqlalchemy import func
        from datetime import timedelta

        cutoff_date = datetime.utcnow() - timedelta(days=days)

        result = await db.execute(
            select(
                func.count(VerificationLog.id).label("total"),
                func.sum(
                    func.cast(VerificationLog.found, type_=Integer)
                ).label("successful"),
            )
            .where(VerificationLog.scanned_at >= cutoff_date)
        )

        row = result.one()

        return {
            "total_scans": row.total or 0,
            "successful_verifications": row.successful or 0,
            "failed_verifications": (row.total or 0) - (row.successful or 0),
            "success_rate": (row.successful / row.total * 100) if row.total else 0.0,
        }


class MaterialProfileRepository:
    """Repository for material profile operations"""

    @staticmethod
    async def get_all_active_profiles(db: AsyncSession) -> List[MaterialProfile]:
        """Get all active material profiles"""
        result = await db.execute(
            select(MaterialProfile)
            .where(MaterialProfile.is_active == True)
            .order_by(MaterialProfile.name)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_profile_by_id(db: AsyncSession, profile_id: int) -> Optional[MaterialProfile]:
        """Get material profile by ID"""
        result = await db.execute(
            select(MaterialProfile).where(MaterialProfile.id == profile_id)
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def get_profile_by_name(db: AsyncSession, name: str) -> Optional[MaterialProfile]:
        """Get material profile by name"""
        result = await db.execute(
            select(MaterialProfile).where(MaterialProfile.name == name)
        )
        return result.scalar_one_or_none()
