-- LatticeLock Pattern Database Schema
-- PostgreSQL schema for storing and verifying encrypted patterns

-- Drop existing tables if they exist (for clean migrations)
DROP TABLE IF EXISTS verification_logs CASCADE;
DROP TABLE IF EXISTS patterns CASCADE;
DROP TABLE IF EXISTS material_profiles CASCADE;

-- Material Profiles Table
-- Stores different material ink configurations
CREATE TABLE material_profiles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    num_inks INTEGER NOT NULL DEFAULT 5,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Patterns Table
-- Core table storing generated patterns for verification
CREATE TABLE patterns (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- Input information
    input_text VARCHAR(500) NOT NULL,  -- Batch code or identifier
    algorithm VARCHAR(100) NOT NULL,   -- Chaos algorithm used

    -- Pattern data
    pattern INTEGER[] NOT NULL,        -- Array of 64 ink IDs (0-4)
    grid_size INTEGER NOT NULL DEFAULT 8,
    pattern_hash VARCHAR(64),          -- SHA-256 hash for quick lookup

    -- Material information
    material_profile_id INTEGER REFERENCES material_profiles(id),
    material_colors JSONB,              -- Dynamic color mapping: {"0": {"r": 0, "g": 229, "b": 255}}

    -- Metadata
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    manufacturer_id VARCHAR(100),
    additional_data JSONB,             -- Flexible metadata storage

    -- Digital signature (optional)
    signature TEXT,                    -- Base64-encoded digital signature

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT patterns_pattern_length CHECK (array_length(pattern, 1) = grid_size * grid_size),
    CONSTRAINT patterns_grid_size_range CHECK (grid_size BETWEEN 3 AND 32)
);

-- Verification Logs Table
-- Audit trail for scanner verifications
CREATE TABLE verification_logs (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),

    -- Verification request
    pattern_input INTEGER[] NOT NULL,  -- Pattern from scanned image
    algorithm VARCHAR(100) DEFAULT 'auto-detect',

    -- Verification result
    found BOOLEAN NOT NULL,
    matched_pattern_id INTEGER REFERENCES patterns(id),
    confidence FLOAT,                  -- Match confidence (0.0 - 1.0)

    -- Scan metadata
    scanned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,

    -- Response time tracking
    response_time_ms INTEGER,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_patterns_input_text ON patterns(input_text);
CREATE INDEX idx_patterns_pattern_hash ON patterns(pattern_hash);
CREATE INDEX idx_patterns_timestamp ON patterns(timestamp DESC);
CREATE INDEX idx_patterns_algorithm ON patterns(algorithm);
CREATE INDEX idx_verification_logs_scanned_at ON verification_logs(scanned_at DESC);
CREATE INDEX idx_verification_logs_found ON verification_logs(found);

-- GIN index for JSONB queries (material colors, additional data)
CREATE INDEX idx_patterns_material_colors ON patterns USING GIN (material_colors);
CREATE INDEX idx_patterns_additional_data ON patterns USING GIN (additional_data);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update updated_at
CREATE TRIGGER update_material_profiles_updated_at
    BEFORE UPDATE ON material_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patterns_updated_at
    BEFORE UPDATE ON patterns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default material profile
INSERT INTO material_profiles (name, description, num_inks) VALUES
('Standard Temperature-Reactive Inks',
 'Default material profile with 5 temperature-reactive inks for anti-counterfeiting', 5);

-- Create view for pattern statistics
CREATE OR REPLACE VIEW pattern_stats AS
SELECT
    DATE_TRUNC('day', timestamp) AS date,
    COUNT(*) AS total_patterns,
    COUNT(DISTINCT input_text) AS unique_batch_codes,
    COUNT(DISTINCT algorithm) AS unique_algorithms,
    AVG(array_length(pattern, 1)) AS avg_pattern_length
FROM patterns
GROUP BY DATE_TRUNC('day', timestamp)
ORDER BY date DESC;

-- Create view for verification statistics
CREATE OR REPLACE VIEW verification_stats AS
SELECT
    DATE_TRUNC('day', scanned_at) AS date,
    COUNT(*) AS total_scans,
    SUM(CASE WHEN found THEN 1 ELSE 0 END) AS successful_verifications,
    SUM(CASE WHEN NOT found THEN 1 ELSE 0 END) AS failed_verifications,
    AVG(CASE WHEN confidence IS NOT NULL THEN confidence END) AS avg_confidence
FROM verification_logs
GROUP BY DATE_TRUNC('day', scanned_at)
ORDER BY date DESC;

-- Grant permissions (adjust username as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO latticelock_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO latticelock_user;
