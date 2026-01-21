"""
LatticeLock SQLite Database Initialization
Simple, file-based database for POC/testing
"""

import sqlite3
import os
from datetime import datetime
from pathlib import Path

# Database file path
DB_PATH = os.getenv("DB_PATH", "latticelock.db")


def init_database():
    """Initialize SQLite database with schema"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Create material_profiles table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS material_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            num_inks INTEGER DEFAULT 5,
            is_active BOOLEAN DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Create patterns table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            input_text TEXT NOT NULL,
            algorithm TEXT NOT NULL,
            pattern TEXT NOT NULL,
            grid_size INTEGER DEFAULT 8,
            pattern_hash TEXT,
            material_profile_id INTEGER,
            material_colors TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            manufacturer_id TEXT,
            additional_data TEXT,
            signature TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (material_profile_id) REFERENCES material_profiles(id)
        )
    """)

    # Create verification_logs table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS verification_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            pattern_input TEXT NOT NULL,
            algorithm TEXT DEFAULT 'auto-detect',
            found BOOLEAN NOT NULL,
            matched_pattern_id INTEGER,
            confidence REAL,
            scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            ip_address TEXT,
            user_agent TEXT,
            response_time_ms INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (matched_pattern_id) REFERENCES patterns(id)
        )
    """)

    # Create indexes for performance
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_patterns_input_text ON patterns(input_text)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_patterns_pattern_hash ON patterns(pattern_hash)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_patterns_timestamp ON patterns(timestamp DESC)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_verification_logs_scanned_at ON verification_logs(scanned_at DESC)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_verification_logs_found ON verification_logs(found)")

    # Insert default material profile
    cursor.execute("""
        INSERT OR IGNORE INTO material_profiles (name, description, num_inks)
        VALUES (?, ?, ?)
    """, (
        "Standard Temperature-Reactive Inks",
        "Default material profile with 5 temperature-reactive inks for anti-counterfeiting",
        5
    ))

    conn.commit()
    conn.close()

    print(f"[OK] SQLite database initialized: {os.path.abspath(DB_PATH)}")


if __name__ == "__main__":
    init_database()
