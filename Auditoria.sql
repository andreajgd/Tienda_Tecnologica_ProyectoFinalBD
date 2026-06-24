USE SistemaInventarioDB;
GO

--elimina la especificación de auditoría si ya existe
IF EXISTS (
    SELECT 1
    FROM sys.database_audit_specifications
    WHERE name = 'AuditoriaDB_SistemaInventario'
)
BEGIN
    --desactiva la especificación de auditoría antes de eliminarla
    ALTER DATABASE AUDIT SPECIFICATION AuditoriaDB_SistemaInventario
    WITH (STATE = OFF);

    --elimina la especificación de auditoría existente
    DROP DATABASE AUDIT SPECIFICATION AuditoriaDB_SistemaInventario;
END;
GO


USE master;
GO

--eliminar la auditoría del servidor si ya existe
IF EXISTS (
    SELECT 1
    FROM sys.server_audits
    WHERE name = 'Auditoria_SistemaInventario'
)
BEGIN
    --desactiva la auditoría del servidor
    ALTER SERVER AUDIT Auditoria_SistemaInventario
    WITH (STATE = OFF);

    --elimina la auditoría existente
    DROP SERVER AUDIT Auditoria_SistemaInventario;
END;
GO

CREATE SERVER AUDIT Auditoria_SistemaInventario
TO FILE
(
    FILEPATH = 'C:\AuditoriaSQL\',
    MAXSIZE = 50 MB,
    MAX_ROLLOVER_FILES = 5,
    RESERVE_DISK_SPACE = OFF
)
WITH
(
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO


--después de crearla, se debe activar para que pueda empezar a registrar eventos.
ALTER SERVER AUDIT Auditoria_SistemaInventario
WITH (STATE = ON);
GO

USE SistemaInventarioDB;
GO

CREATE DATABASE AUDIT SPECIFICATION AuditoriaDB_SistemaInventario
FOR SERVER AUDIT Auditoria_SistemaInventario
ADD (SELECT ON SCHEMA::dbo BY PUBLIC),
ADD (INSERT ON SCHEMA::dbo BY PUBLIC),
ADD (UPDATE ON SCHEMA::dbo BY PUBLIC),
ADD (DELETE ON SCHEMA::dbo BY PUBLIC),
ADD (EXECUTE ON SCHEMA::dbo BY PUBLIC),
ADD (DATABASE_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);
GO



USE SistemaInventarioDB;
GO

SELECT * FROM Productos;
GO

DECLARE @IdCategoriaAudit INT;

INSERT INTO Categorias (NombreCategoria)
VALUES ('Prueba Auditoria');

SET @IdCategoriaAudit = SCOPE_IDENTITY();

UPDATE Categorias
SET NombreCategoria = 'Prueba Auditoria Modificada'
WHERE IdCategoria = @IdCategoriaAudit;

DELETE FROM Categorias
WHERE IdCategoria = @IdCategoriaAudit;
GO


SELECT
    event_time AS FechaEvento,
    action_id AS Accion,
    succeeded AS EjecutadoCorrectamente,
    server_principal_name AS Usuario,
    database_name AS BaseDatos,
    schema_name AS Esquema,
    object_name AS Objeto,
    statement AS SentenciaEjecutada
FROM sys.fn_get_audit_file
(
    'C:\AuditoriaSQL\*.sqlaudit',
    DEFAULT,
    DEFAULT
)
WHERE database_name = 'SistemaInventarioDB'
ORDER BY event_time DESC;
GO