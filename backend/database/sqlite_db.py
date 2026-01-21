"""
SQLite Database Operations for LatticeLock
Simple synchronous database for POC
"""

import sqlite3
import json
import os
import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from contextlib import contextmanager

DB_PATH = os.getenv("DB_PATH", "latticelock.db")


@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Enable column access by name
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db():
    """Initialize database - run init_db.py script"""
    from . import init_db as init_script
    init_script.init_database()


class PatternRepository:
    """Repository for Pattern CRUD operations (SQLite)"""

    @staticmethod
    def create_pattern(
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
    ) -> Dict[str, Any]:
        """Create a new pattern record"""
        pattern_uuid = str(uuid.uuid4())
        pattern_str = json.dumps(pattern)
        material_colors_str = json.dumps(material_colors) if material_colors else None
        additional_data_str = json.dumps(additional_data) if additional_data else None

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO patterns (
                    uuid, input_text, algorithm, pattern, grid_size, pattern_hash,
                    material_profile_id, material_colors, timestamp, manufacturer_id,
                    additional_data, signature
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                pattern_uuid, input_text, algorithm, pattern_str, grid_size, pattern_hash,
                material_profile_id, material_colors_str, datetime.utcnow(), manufacturer_id,
                additional_data_str, signature
            ))

            pattern_id = cursor.lastrowid

            # Fetch the created pattern
            cursor.execute("SELECT * FROM patterns WHERE id = ?", (pattern_id,))
            row = cursor.fetchone()

            return dict(row)

    @staticmethod
    def get_pattern_by_uuid(pattern_uuid: str) -> Optional[Dict[str, Any]]:
        """Get pattern by UUID"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM patterns WHERE uuid = ?", (pattern_uuid,))
            row = cursor.fetchone()
            return dict(row) if row else None

    @staticmethod
    def get_pattern_by_hash(pattern_hash: str) -> Optional[Dict[str, Any]]:
        """Get pattern by hash"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM patterns WHERE pattern_hash = ?", (pattern_hash,))
            row = cursor.fetchone()
            return dict(row) if row else None

    @staticmethod
    def find_matching_patterns(
        pattern: List[int],
        exact_match: bool = True,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """Find patterns matching the given pattern array"""
        pattern_str = json.dumps(pattern)

        with get_db_connection() as conn:
            cursor = conn.cursor()

            if exact_match:
                cursor.execute("""
                    SELECT * FROM patterns
                    WHERE pattern = ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                """, (pattern_str, limit))
            else:
                # Partial match - match first element for simplicity
                first_element = json.dumps([pattern[0]])
                cursor.execute("""
                    SELECT * FROM patterns
                    WHERE pattern LIKE ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                """, (f"{first_element}%", limit))

            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    @staticmethod
    def get_patterns_by_grid_size(grid_size: int) -> List[Dict[str, Any]]:
        """Get all patterns with a specific grid size"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM patterns
                WHERE grid_size = ?
                ORDER BY timestamp DESC
            """, (grid_size,))

            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    @staticmethod
    def get_patterns_by_input_text(input_text: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get all patterns for a given input text"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM patterns
                WHERE input_text = ?
                ORDER BY timestamp DESC
                LIMIT ?
            """, (input_text, limit))

            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    @staticmethod
    def get_recent_patterns(limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        """Get recent patterns"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM patterns
                ORDER BY timestamp DESC
                LIMIT ? OFFSET ?
            """, (limit, offset))

            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    @staticmethod
    def get_pattern_stats() -> Dict[str, Any]:
        """Get pattern statistics"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT
                    COUNT(*) as total,
                    COUNT(DISTINCT input_text) as unique_inputs,
                    COUNT(DISTINCT algorithm) as unique_algorithms
                FROM patterns
            """)
            row = cursor.fetchone()

            return {
                "total_patterns": row["total"],
                "unique_batch_codes": row["unique_inputs"],
                "unique_algorithms": row["unique_algorithms"],
            }


class VerificationRepository:
    """Repository for verification log operations (SQLite)"""

    @staticmethod
    def create_verification_log(
        pattern_input: List[int],
        found: bool,
        matched_pattern_id: Optional[int] = None,
        confidence: Optional[float] = None,
        algorithm: str = "auto-detect",
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        response_time_ms: Optional[int] = None,
    ) -> Dict[str, Any]:
        """Create a verification log entry"""
        log_uuid = str(uuid.uuid4())
        pattern_input_str = json.dumps(pattern_input)

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO verification_logs (
                    uuid, pattern_input, algorithm, found, matched_pattern_id,
                    confidence, ip_address, user_agent, response_time_ms
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                log_uuid, pattern_input_str, algorithm, found, matched_pattern_id,
                confidence, ip_address, user_agent, response_time_ms
            ))

            log_id = cursor.lastrowid

            # Fetch the created log
            cursor.execute("SELECT * FROM verification_logs WHERE id = ?", (log_id,))
            row = cursor.fetchone()

            return dict(row)

    @staticmethod
    def get_recent_verifications(limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """Get recent verification logs"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM verification_logs
                ORDER BY scanned_at DESC
                LIMIT ? OFFSET ?
            """, (limit, offset))

            rows = cursor.fetchall()
            return [dict(row) for row in rows]


class MaterialProfileRepository:
    """Repository for material profile operations (SQLite)"""

    @staticmethod
    def get_all_active_profiles() -> List[Dict[str, Any]]:
        """Get all active material profiles"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT * FROM material_profiles
                WHERE is_active = 1
                ORDER BY name
            """)
            rows = cursor.fetchall()
            return [dict(row) for row in rows]

    @staticmethod
    def get_profile_by_id(profile_id: int) -> Optional[Dict[str, Any]]:
        """Get material profile by ID"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM material_profiles WHERE id = ?", (profile_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    @staticmethod
    def get_profile_by_name(name: str) -> Optional[Dict[str, Any]]:
        """Get material profile by name"""
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM material_profiles WHERE name = ?", (name,))
            row = cursor.fetchone()
            return dict(row) if row else None
