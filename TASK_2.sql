CREATE DATABASE COMPANEY
USE COMPANEY
-- Phase 1: Table creation without circular FK constraints
CREATE TABLE EMPLOYEE (
    SSN INT PRIMARY KEY,
    Fname VARCHAR(50) NOT NULL,
    Lname VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    Department_DNUM INT NULL, -- Temporarily nullable
    Supervisor_SSN INT NULL   -- Temporarily nullable
);

CREATE TABLE DEPARTMENT (
    DNUM INT PRIMARY KEY,
    DName VARCHAR(50) NOT NULL,
    Manager_SSN INT NULL,     -- Temporarily nullable
    Manager_StartDate DATE NOT NULL
);

-- Other tables remain unchanged
CREATE TABLE DEPARTMENT_LOCATION (
    Department_DNUM INT NOT NULL,
    Location VARCHAR(50) NOT NULL,
    PRIMARY KEY (Department_DNUM, Location)
);

CREATE TABLE PROJECT (
    PNumber INT PRIMARY KEY,
    Pname VARCHAR(50) NOT NULL,
    LocationCity VARCHAR(50),
    Department_DNUM INT NOT NULL
);

CREATE TABLE DEPENDENT (
    Employee_SSN INT NOT NULL,
    DependentName VARCHAR(50) NOT NULL,
    BirthDate DATE NOT NULL,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    PRIMARY KEY (Employee_SSN, DependentName)
);

CREATE TABLE WORKS_ON (
    Employee_SSN INT NOT NULL,
    Project_PNumber INT NOT NULL,
    Hours DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (Employee_SSN, Project_PNumber)
);

-- Phase 2: Insert sample data (resolve circular references)
INSERT INTO EMPLOYEE (SSN, Fname, Lname, BirthDate, Gender)
VALUES 
(1001, 'ALI', 'AHMED', '1985-07-20', 'M'),
(1002, 'JanA', 'SAMY', '1990-11-30', 'F'),
(1003, 'MALEK', 'MOHAMMED', '1978-03-12', 'M'),
(1004, 'Sarah', 'ALI', '1995-09-05', 'F'),
(1005, 'Alex', 'SAMIR', '1988-12-15', 'M');

INSERT INTO DEPARTMENT (DNUM, DName, Manager_StartDate)
VALUES 
(1, 'HR', '2020-01-01'),
(2, 'IT', '2019-05-15'),
(3, 'Finance', '2021-03-10');

-- Update references
UPDATE EMPLOYEE SET 
    Department_DNUM = CASE SSN
        WHEN 1001 THEN 1 
        WHEN 1002 THEN 2 
        WHEN 1003 THEN 3 
        WHEN 1004 THEN 2 
        WHEN 1005 THEN 3 
    END,
    Supervisor_SSN = CASE SSN
        WHEN 1001 THEN NULL
        WHEN 1002 THEN 1001
        WHEN 1003 THEN 1001
        WHEN 1004 THEN 1002
        WHEN 1005 THEN 1003
    END;

UPDATE DEPARTMENT SET 
    Manager_SSN = CASE DNUM
        WHEN 1 THEN 1001
        WHEN 2 THEN 1002
        WHEN 3 THEN 1003
    END;

-- Phase 3: Add FK constraints
ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_Employee_Department 
    FOREIGN KEY (Department_DNUM) REFERENCES DEPARTMENT(DNUM)
ALTER TABLE EMPLOYEE
ADD CONSTRAINT FK_Employee_Supervisor 
    FOREIGN KEY (Supervisor_SSN) REFERENCES EMPLOYEE(SSN);

ALTER TABLE DEPARTMENT
ADD CONSTRAINT FK_Department_Manager 
    FOREIGN KEY (Manager_SSN) REFERENCES EMPLOYEE(SSN);

ALTER TABLE DEPARTMENT_LOCATION
ADD CONSTRAINT FK_DeptLocation_Department 
    FOREIGN KEY (Department_DNUM) REFERENCES DEPARTMENT(DNUM) ON DELETE CASCADE;

ALTER TABLE PROJECT
ADD CONSTRAINT FK_Project_Department 
    FOREIGN KEY (Department_DNUM) REFERENCES DEPARTMENT(DNUM) ON DELETE CASCADE;

ALTER TABLE DEPENDENT
ADD CONSTRAINT FK_Dependent_Employee 
    FOREIGN KEY (Employee_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE CASCADE;

ALTER TABLE WORKS_ON
ADD CONSTRAINT FK_WorksOn_Employee 
    FOREIGN KEY (Employee_SSN) REFERENCES EMPLOYEE(SSN) ON DELETE CASCADE
ALTER TABLE WORKS_ON
ADD CONSTRAINT FK_WorksOn_Project 
    FOREIGN KEY (Project_PNumber) REFERENCES PROJECT(PNumber) ON DELETE CASCADE;

-- Phase 4: Insert remaining data
INSERT INTO PROJECT (PNumber, Pname, LocationCity, Department_DNUM)
VALUES 
(101, 'Database Upgrade', 'New York', 2),
(102, 'Payroll System', 'Chicago', 3),
(103, 'Recruitment Portal', 'Austin', 1);

INSERT INTO DEPENDENT (Employee_SSN, DependentName, BirthDate, Gender)
VALUES 
(1001, 'BASMALA ADEL', '2010-05-12', 'F'),
(1001, 'AYMAN MOHAMMED', '2015-08-23', 'M'),
(1003, 'ISRAA YASSER', '2018-02-14', 'F');

INSERT INTO WORKS_ON (Employee_SSN, Project_PNumber, Hours)
VALUES 
(1002, 101, 20.5),
(1004, 101, 15.0),
(1003, 102, 30.0),
(1005, 102, 10.5),
(1001, 103, 25.0);

-- Phase 5: Example operations
-- Update employee's department
UPDATE EMPLOYEE
SET Department_DNUM = 3
WHERE SSN = 1004;

-- Delete a dependent
DELETE FROM DEPENDENT 
WHERE Employee_SSN = 1001 AND DependentName = 'ALI AHMED';

-- Retrieve IT department employees
SELECT * 
FROM EMPLOYEE 
WHERE Department_DNUM = 2;

-- Get employee assignments
SELECT 
    E.Fname + ' ' + E.Lname AS EmployeeName,
    P.Pname AS Project,
    W.Hours AS Hours
FROM WORKS_ON W
JOIN EMPLOYEE E ON W.Employee_SSN = E.SSN
JOIN PROJECT P ON W.Project_PNumber = P.PNumber;