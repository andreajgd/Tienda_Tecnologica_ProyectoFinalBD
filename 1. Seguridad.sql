--Crear logins
USE master;
GO

CREATE LOGIN AdministradorLogin
WITH PASSWORD = 'Admin123$';

CREATE LOGIN VendedorLogin
WITH PASSWORD = 'Venta123$';

CREATE LOGIN AuditorLogin
WITH PASSWORD = 'Audit123$';
GO


--Crear Usuarios en la base de datos 

USE SistemaInventarioDB;
GO

CREATE USER AdministradorUser
FOR LOGIN AdministradorLogin;

CREATE USER VendedorUser
FOR LOGIN VendedorLogin;

CREATE USER AuditorUser
FOR LOGIN AuditorLogin;
GO

--Crear roles
CREATE ROLE RolAdministrador;
CREATE ROLE RolVendedor;
CREATE ROLE RolAuditor;
GO

--Asignar roles 
ALTER ROLE RolAdministrador
ADD MEMBER AdministradorUser;

ALTER ROLE RolVendedor
ADD MEMBER VendedorUser;

ALTER ROLE RolAuditor
ADD MEMBER AuditorUser;
GO

--Asignar permisos
GRANT SELECT, INSERT, UPDATE, DELETE
ON SCHEMA::dbo
TO RolAdministrador;
GO

GRANT SELECT, INSERT
ON SCHEMA::dbo
TO RolVendedor;
GO

GRANT SELECT
ON SCHEMA::dbo
TO RolAuditor;
GO

--Practicas de seguridad

-- Evitar que el auditor elimine datos
DENY DELETE
ON SCHEMA::dbo
TO RolAuditor;

-- Evitar que el auditor modifique datos
DENY UPDATE
ON SCHEMA::dbo
TO RolAuditor;
GO

--Verificacion

SELECT name
FROM sys.database_principals
WHERE type = 'R';

SELECT name
FROM sys.database_principals
WHERE type = 'S';

SELECT name
FROM sys.database_principals
WHERE type = 'S';
