-- LearnWeave - Database Setup Script
-- Run this in MySQL to create the database and user

-- Create the database
CREATE DATABASE IF NOT EXISTS learnweave_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Create the user (IMPORTANT: Use '%' for Docker compatibility!)
-- '%' allows connections from any host, including Docker containers
-- For production, replace '%' with specific IP addresses
-- NOTE: This password MUST match DB_PASSWORD in your .env file!
CREATE USER IF NOT EXISTS 'learnweave_user'@'%' IDENTIFIED BY 'learnweave_pass';

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON learnweave_db.* TO 'learnweave_user'@'%';

-- Apply the changes
FLUSH PRIVILEGES;

-- Verify the setup
USE learnweave_db;
SHOW TABLES;

-- Success message
SELECT 'Database setup complete! ✓' AS Status;
SELECT 'Database: learnweave_db' AS Info;
SELECT 'User: learnweave_user@% (allows Docker connections)' AS Info;
SELECT 'Now update your backend/.env file with these credentials' AS NextStep;
SELECT 'IMPORTANT: Change your_secure_password to a real password!' AS Warning;
