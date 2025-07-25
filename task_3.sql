-- Create COMPANY database
CREATE DATABASE COMP;
GO

USE COMP;
GO

-- Create DEPARTMENT table
CREATE TABLE DEPARTMENT (
    DNUM INT IDENTITY(1,1) PRIMARY KEY,
    DName VARCHAR(50) NOT NULL UNIQUE,
    ManagerStartDate DATE NOT NULL DEFAULT GETDATE()
);
GO

-- Create EMPLOYEE table with circular dependency handling
CREATE TABLE EMPLOYEE (
    SSN CHAR(9) PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    Department_DNUM INT NULL, -- Temporarily nullable
    Supervisor_SSN CHAR(9) NULL
);
GO

-- Create PROJECT table
CREATE TABLE PROJECT (
    PNumber INT IDENTITY(100,10) PRIMARY KEY,
    Pname VARCHAR(50) NOT NULL,
    LocationCity VARCHAR(50) DEFAULT 'Headquarters',
    Department_DNUM INT NOT NULL
);
GO

-- Create DEPENDENT table
CREATE TABLE DEPENDENT (
    Employee_SSN CHAR(9) NOT NULL,
    DependentName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    PRIMARY KEY (Employee_SSN, DependentName)
);
GO

-- Create WORKS_ON table (M:N relationship)
CREATE TABLE WORKS_ON (
    Employee_SSN CHAR(9) NOT NULL,
    Project_PNumber INT NOT NULL,
    Hours DECIMAL(5,2) NOT NULL DEFAULT 0.0 CHECK (Hours >= 0),
    PRIMARY KEY (Employee_SSN, Project_PNumber)
);
GO

-- Add foreign keys after table creation
ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_Employee_Department
    FOREIGN KEY (Department_DNUM) REFERENCES DEPARTMENT(DNUM) ON UPDATE CASCADE
ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_Employee_Supervisor
    FOREIGN KEY (Supervisor_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE NO ACTION;
GO

ALTER TABLE DEPARTMENT
ADD Manager_SSN CHAR(9) NULL

ALTER TABLE DEPARTMENT
ADD CONSTRAINT FK_Department_Manager
    FOREIGN KEY (Manager_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE NO ACTION;
GO

ALTER TABLE PROJECT
ADD CONSTRAINT FK_Project_Department
    FOREIGN KEY (Department_DNUM) REFERENCES DEPARTMENT(DNUM) ON DELETE CASCADE;
GO

ALTER TABLE DEPENDENT
ADD CONSTRAINT FK_Dependent_Employee
    FOREIGN KEY (Employee_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE CASCADE;
GO

ALTER TABLE WORKS_ON
ADD CONSTRAINT FK_WorksOn_Employee
    FOREIGN KEY (Employee_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE CASCADE
ALTER TABLE WORKS_ON
ADD CONSTRAINT FK_WorksOn_Project
    FOREIGN KEY (Project_PNumber) REFERENCES PROJECT(PNumber) ON DELETE CASCADE;
GO

-- Insert sample data (resolve circular references)
INSERT INTO DEPARTMENT (DName, ManagerStartDate) 
VALUES 
('HR', '2020-01-01'),
('IT', '2019-05-15'),
('Finance', '2021-03-10');

INSERT INTO EMPLOYEE (SSN, Fname, Lname, BirthDate, Gender) 
VALUES 
('111223333', 'ALI', 'AHMED', '1985-07-20', 'M'),
('222334444', 'JanA', 'SAMY', '1990-11-30', 'F'),
('333445555', 'MALEK', 'MOHAMMED', '1978-03-12', 'M'),
('444556666', 'Sarah', 'REDA', '1995-09-05', 'F'),
('555667777', 'Alex', 'JHON', '1988-12-15', 'M');

UPDATE EMPLOYEE SET 
    Department_DNUM = CASE 
        WHEN SSN = '111223333' THEN 1 
        WHEN SSN = '222334444' THEN 2 
        WHEN SSN = '333445555' THEN 3 
        ELSE 2 
    END,
    Supervisor_SSN = CASE
        WHEN SSN = '222334444' THEN '111223333'
        WHEN SSN = '333445555' THEN '111223333'
        WHEN SSN = '444556666' THEN '222334444'
        WHEN SSN = '555667777' THEN '333445555'
        ELSE NULL 
    END;

UPDATE DEPARTMENT SET Manager_SSN = 
    CASE DNUM
        WHEN 1 THEN '111223333'
        WHEN 2 THEN '222334444'
        WHEN 3 THEN '333445555'
    END;

INSERT INTO PROJECT (Pname, Department_DNUM) 
VALUES 
('Recruitment Portal', 1),
('Database Upgrade', 2),
('Payroll System', 3);

INSERT INTO DEPENDENT (Employee_SSN, DependentName, BirthDate, Gender) 
VALUES 
('111223333', 'BASMA SAID', '2010-05-12', 'F'),
('111223333', 'AYMAN MOHAMMED', '2015-08-23', 'M'),
('333445555', 'ISRAA YASSER', '2018-02-14', 'F');

INSERT INTO WORKS_ON (Employee_SSN, Project_PNumber, Hours) 
VALUES 
('222334444', 100, 20.5),
('444556666', 100, 15.0),
('333445555', 110, 30.0),
('555667777', 110, 10.5),
('111223333', 120, 25.0);

-- ALTER TABLE Demonstrations
-- 1. Add new column
ALTER TABLE EMPLOYEE
ADD Email VARCHAR(100) NULL;

-- 2. Add new foreign key constraint
ALTER TABLE DEPARTMENT
ADD CONSTRAINT UQ_Department_Manager UNIQUE (Manager_SSN);

-- 3. Modify column data type
ALTER TABLE DEPENDENT
ALTER COLUMN DependentName VARCHAR(100) NOT NULL;

-- 4. Drop existing constraint
ALTER TABLE WORKS_ON
DROP CONSTRAINT FK_WorksOn_Project;

-- Re-add with proper action
ALTER TABLE WORKS_ON
ADD CONSTRAINT FK_WorksOn_Project
    FOREIGN KEY (Project_PNumber) REFERENCES PROJECT(PNumber) ON DELETE CASCADE;

SELECT * FROM EMPLOYEE