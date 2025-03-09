-- Ensure the database exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'resume_db') THEN
        CREATE DATABASE resume_db;
    END IF;
END $$;

\c resume_db;

-- Ensure encoding is UTF-8
SET client_encoding = 'UTF8';

-- Create tables if they do not exist
CREATE TABLE IF NOT EXISTS likes (
    id SERIAL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    text TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
