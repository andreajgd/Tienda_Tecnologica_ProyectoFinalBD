--7. Extended Events

USE master;
GO

-- Creacion de evento

USE master;
GO

DROP EVENT SESSION Monitor_SistemaInventario ON SERVER;
GO

CREATE EVENT SESSION Monitor_SistemaInventario ON SERVER
ADD EVENT sqlserver.sql_statement_completed (
    ACTION (sqlserver.sql_text, sqlserver.database_name, sqlserver.username, sqlserver.session_id)
    WHERE (sqlserver.database_name = N'SistemaInventarioDB')
),
ADD EVENT sqlserver.sql_batch_completed (
    ACTION (sqlserver.sql_text, sqlserver.database_name, sqlserver.username, sqlserver.session_id)
    WHERE (sqlserver.database_name = N'SistemaInventarioDB')
),
ADD EVENT sqlserver.error_reported (
    ACTION (sqlserver.sql_text, sqlserver.database_name, sqlserver.username, sqlserver.session_id)
    WHERE (sqlserver.database_name = N'SistemaInventarioDB')
),
ADD EVENT sqlserver.attention (
    ACTION (sqlserver.sql_text, sqlserver.database_name, sqlserver.username, sqlserver.session_id)
    WHERE (sqlserver.database_name = N'SistemaInventarioDB')
)
ADD TARGET package0.event_file (
    SET filename = N'C:\AuditoriaSQL\Monitor_SistemaInventario.xel',
        max_file_size = 50,
        max_rollover_files = 5
)
WITH (
    MAX_MEMORY = 4096 KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 5 SECONDS,
    STARTUP_STATE = ON
);
GO

ALTER EVENT SESSION Monitor_SistemaInventario ON SERVER STATE = START;
GO

-- Verificar los 4 eventos
SELECT
    s.name      AS NombreSesion,
    e.name      AS NombreEvento,
    e.package   AS Paquete
FROM sys.server_event_sessions s
INNER JOIN sys.server_event_session_events e
    ON s.event_session_id = e.event_session_id
WHERE s.name = 'Monitor_SistemaInventario';
GO

-- Generar actividad en la base de datos
USE SistemaInventarioDB;
GO

SELECT * FROM Productos;
SELECT * FROM Ventas;
SELECT * FROM DetalleVenta;

SELECT
    p.NombreProducto,
    p.Precio,
    p.Stock,
    c.NombreCategoria,
    pr.NombreProveedor
FROM Productos p
INNER JOIN Categorias c ON p.IdCategoria = c.IdCategoria
INNER JOIN Proveedores pr ON p.IdProveedor = pr.IdProveedor;
GO

-- Esperar unos segundos y luego leer los eventos capturados
USE master;
GO

SELECT
    event_data_xml.value('(event/@name)[1]', 'NVARCHAR(100)')         AS NombreEvento,
    event_data_xml.value('(event/@timestamp)[1]', 'DATETIME2')        AS FechaHora,
    event_data_xml.value('(event/action[@name="database_name"]/value)[1]', 'NVARCHAR(128)') AS BaseDatos,
    event_data_xml.value('(event/action[@name="username"]/value)[1]', 'NVARCHAR(128)')      AS Usuario,
    event_data_xml.value('(event/action[@name="sql_text"]/value)[1]', 'NVARCHAR(MAX)')      AS SentenciaSQL
FROM (
    SELECT CAST(event_data AS XML) AS event_data_xml
    FROM sys.fn_xe_file_target_read_file(
        'C:\AuditoriaSQL\Monitor_SistemaInventarioPrueba*.xel',
        NULL, NULL, NULL
    )
) AS EventosXML
ORDER BY FechaHora DESC;
GO


