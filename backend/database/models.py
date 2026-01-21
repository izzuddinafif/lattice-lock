"""
Database models for LatticeLock pattern storage and verification
Uses SQLAlchemy with asyncpg for PostgreSQL async operations
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Float, ForeignKey, ARRAY, JSON, CheckConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import UUID, JSONB, INET
from sqlalchemy.sql import func
import uuid

Base = declarative_base()


class MaterialProfile(Base):
    """Material ink profile configurations"""
    __tablename__ = "material_profiles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False, index=True)
    description = Column(Text)
    num_inks = Column(Integer, default=5, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "num_inks": self.num_inks,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Pattern(Base):
    """Generated encrypted patterns for anti-counterfeiting"""
    __tablename__ = "patterns"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, nullable=False)

    # Input information
    input_text = Column(String(500), nullable=False, index=True)
    algorithm = Column(String(100), nullable=False, index=True)

    # Pattern data
    pattern = Column(ARRAY(Integer), nullable=False)  # Array of 64 ink IDs
    grid_size = Column(Integer, default=8, nullable=False)
    pattern_hash = Column(String(64), index=True)

    # Material information
    material_profile_id = Column(Integer, ForeignKey("material_profiles.id"))
    material_colors = Column(JSONB)  # Dynamic color mapping

    # Metadata
    timestamp = Column(DateTime(timezone=True), nullable=False, default=func.now(), index=True)
    manufacturer_id = Column(String(100))
    additional_data = Column(JSONB)

    # Digital signature
    signature = Column(Text)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Constraints
    __table_args__ = (
        CheckConstraint("array_length(pattern, 1) = grid_size * grid_size", name="patterns_pattern_length"),
        CheckConstraint("grid_size BETWEEN 3 AND 32", name="patterns_grid_size_range"),
    )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "uuid": str(self.uuid),
            "input_text": self.input_text,
            "algorithm": self.algorithm,
            "pattern": self.pattern,
            "grid_size": self.grid_size,
            "pattern_hash": self.pattern_hash,
            "material_profile_id": self.material_profile_id,
            "material_colors": self.material_colors,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "manufacturer_id": self.manufacturer_id,
            "additional_data": self.additional_data,
            "signature": self.signature,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class VerificationLog(Base):
    """Audit trail for pattern verification attempts"""
    __tablename__ = "verification_logs"

    id = Column(Integer, primary_key=True, index=True)
    uuid = Column(UUID(as_uuid=True), default=uuid.uuid4, unique=True, nullable=False)

    # Verification request
    pattern_input = Column(ARRAY(Integer), nullable=False)
    algorithm = Column(String(100), default="auto-detect")

    # Verification result
    found = Column(Boolean, nullable=False, index=True)
    matched_pattern_id = Column(Integer, ForeignKey("patterns.id"))
    confidence = Column(Float)

    # Scan metadata
    scanned_at = Column(DateTime(timezone=True), default=func.now(), index=True)
    ip_address = Column(INET)
    user_agent = Column(Text)

    # Performance tracking
    response_time_ms = Column(Integer)

    # Timestamp
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "uuid": str(self.uuid),
            "pattern_input": self.pattern_input,
            "algorithm": self.algorithm,
            "found": self.found,
            "matched_pattern_id": self.matched_pattern_id,
            "confidence": self.confidence,
            "scanned_at": self.scanned_at.isoformat() if self.scanned_at else None,
            "ip_address": str(self.ip_address) if self.ip_address else None,
            "user_agent": self.user_agent,
            "response_time_ms": self.response_time_ms,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
