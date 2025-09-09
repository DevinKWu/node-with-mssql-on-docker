-- 建立資料庫
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'your_database_name')
BEGIN
    CREATE DATABASE [your_database_name];
END
GO

USE [your_database_name];
GO

-- 建立範例資料表
CREATE TABLE IF NOT EXISTS Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    UpdatedAt DATETIME2 DEFAULT GETDATE()
);
GO
