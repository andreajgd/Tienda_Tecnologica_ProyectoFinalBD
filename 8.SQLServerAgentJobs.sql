-- 8. SQL Server Agent Jobs

USE msdb;
GO

-- JOB 1: Mantenimiento Nocturno de SistemaInventarioDB

-- Eliminar el job si ya existe
IF EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs
    WHERE name = N'Mantenimiento_SistemaInventarioDB'
)
BEGIN
    EXEC msdb.dbo.sp_delete_job
        @job_name = N'Mantenimiento_SistemaInventarioDB',
        @delete_unused_schedule = 1;
END;
GO

-- Crear el Job 1
EXEC msdb.dbo.sp_add_job
    @job_name         = N'Mantenimiento_SistemaInventarioDB',
    @enabled          = 1,
    @description      = N'Verifica integridad, actualiza estadisticas y reorganiza indices en SistemaInventarioDB.',
    @category_name    = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa';
GO

-- Paso 1: Verificacion de integridad
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = N'Mantenimiento_SistemaInventarioDB',
    @step_name         = N'Paso 1 - Verificar Integridad',
    @step_id           = 1,
    @subsystem         = N'TSQL',
    @database_name     = N'SistemaInventarioDB',
    @command           = N'DBCC CHECKDB (SistemaInventarioDB) WITH NO_INFOMSGS, ALL_ERRORMSGS;',
    @on_success_action = 3,
    @on_fail_action    = 2;
GO

-- Paso 2: Actualizacion de estadisticas
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = N'Mantenimiento_SistemaInventarioDB',
    @step_name         = N'Paso 2 - Actualizar Estadisticas',
    @step_id           = 2,
    @subsystem         = N'TSQL',
    @database_name     = N'SistemaInventarioDB',
    @command           = N'
UPDATE STATISTICS Categorias;
UPDATE STATISTICS Proveedores;
UPDATE STATISTICS Clientes;
UPDATE STATISTICS Productos;
UPDATE STATISTICS Ventas;
UPDATE STATISTICS DetalleVenta;',
    @on_success_action = 3,
    @on_fail_action    = 2;
GO

-- Paso 3: Reorganizacion de indices
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = N'Mantenimiento_SistemaInventarioDB',
    @step_name         = N'Paso 3 - Reorganizar Indices',
    @step_id           = 3,
    @subsystem         = N'TSQL',
    @database_name     = N'SistemaInventarioDB',
    @command           = N'
ALTER INDEX ALL ON Categorias   REORGANIZE;
ALTER INDEX ALL ON Proveedores  REORGANIZE;
ALTER INDEX ALL ON Clientes     REORGANIZE;
ALTER INDEX ALL ON Productos    REORGANIZE;
ALTER INDEX ALL ON Ventas       REORGANIZE;
ALTER INDEX ALL ON DetalleVenta REORGANIZE;',
    @on_success_action = 1,
    @on_fail_action    = 2;
GO

-- Definir paso de inicio
EXEC msdb.dbo.sp_update_job
    @job_name      = N'Mantenimiento_SistemaInventarioDB',
    @start_step_id = 1;
GO

-- Horario: todos los dias a las 2:00 AM
EXEC msdb.dbo.sp_add_jobschedule
    @job_name          = N'Mantenimiento_SistemaInventarioDB',
    @name              = N'Horario_Mantenimiento_Nocturno',
    @enabled           = 1,
    @freq_type         = 4,
    @freq_interval     = 1,
    @active_start_time = 020000;
GO

-- Agregar al servidor local
EXEC msdb.dbo.sp_add_jobserver
    @job_name    = N'Mantenimiento_SistemaInventarioDB',
    @server_name = N'(LOCAL)';
GO

-- ============================================================
-- JOB 2: Alerta de Stock Bajo
-- ============================================================

-- Eliminar el job si ya existe
IF EXISTS (
    SELECT 1 FROM msdb.dbo.sysjobs
    WHERE name = N'Alerta_StockBajo_SistemaInventarioDB'
)
BEGIN
    EXEC msdb.dbo.sp_delete_job
        @job_name = N'Alerta_StockBajo_SistemaInventarioDB',
        @delete_unused_schedule = 1;
END;
GO

-- Crear el Job 2
EXEC msdb.dbo.sp_add_job
    @job_name         = N'Alerta_StockBajo_SistemaInventarioDB',
    @enabled          = 1,
    @description      = N'Detecta productos con stock menor a 5 unidades y registra la alerta en LogStockBajo.',
    @category_name    = N'[Uncategorized (Local)]',
    @owner_login_name = N'sa';
GO

-- Paso 1: Crear tabla LogStockBajo si no existe
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = N'Alerta_StockBajo_SistemaInventarioDB',
    @step_name         = N'Paso 1 - Crear Tabla LogStockBajo',
    @step_id           = 1,
    @subsystem         = N'TSQL',
    @database_name     = N'SistemaInventarioDB',
    @command           = N'
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = ''LogStockBajo''
)
BEGIN
    CREATE TABLE LogStockBajo (
        IdLog          INT IDENTITY(1,1) PRIMARY KEY,
        IdProducto     INT NOT NULL,
        NombreProducto VARCHAR(100) NOT NULL,
        StockActual    INT NOT NULL,
        FechaAlerta    DATETIME DEFAULT GETDATE()
    );
END;',
    @on_success_action = 3,
    @on_fail_action    = 2;
GO

-- Paso 2: Insertar productos con stock critico
EXEC msdb.dbo.sp_add_jobstep
    @job_name          = N'Alerta_StockBajo_SistemaInventarioDB',
    @step_name         = N'Paso 2 - Registrar Alertas de Stock Bajo',
    @step_id           = 2,
    @subsystem         = N'TSQL',
    @database_name     = N'SistemaInventarioDB',
    @command           = N'
INSERT INTO LogStockBajo (IdProducto, NombreProducto, StockActual, FechaAlerta)
SELECT IdProducto, NombreProducto, Stock, GETDATE()
FROM Productos
WHERE Stock < 5;',
    @on_success_action = 1,
    @on_fail_action    = 2;
GO

-- Definir paso de inicio
EXEC msdb.dbo.sp_update_job
    @job_name      = N'Alerta_StockBajo_SistemaInventarioDB',
    @start_step_id = 1;
GO

-- Horario: cada 6 horas
EXEC msdb.dbo.sp_add_jobschedule
    @job_name             = N'Alerta_StockBajo_SistemaInventarioDB',
    @name                 = N'Horario_Alerta_StockBajo',
    @enabled              = 1,
    @freq_type            = 4,
    @freq_interval        = 1,
    @freq_subday_type     = 8,
    @freq_subday_interval = 6,
    @active_start_time    = 000000;
GO

-- Agregar al servidor local
EXEC msdb.dbo.sp_add_jobserver
    @job_name    = N'Alerta_StockBajo_SistemaInventarioDB',
    @server_name = N'(LOCAL)';
GO

-- EJECUCION MANUAL PARA PRUEBA Y EVIDENCIA

EXEC msdb.dbo.sp_start_job
    @job_name = N'Mantenimiento_SistemaInventarioDB';
GO

WAITFOR DELAY '00:00:05';
GO

EXEC msdb.dbo.sp_start_job
    @job_name = N'Alerta_StockBajo_SistemaInventarioDB';
GO

WAITFOR DELAY '00:00:05';
GO

-- VERIFICACION: Historial de ejecucion

SELECT
    j.name      AS NombreJob,
    jh.step_id  AS PasoID,
    jh.step_name AS NombrePaso,
    CASE jh.run_status
        WHEN 0 THEN 'Fallido'
        WHEN 1 THEN 'Exitoso'
        WHEN 2 THEN 'Reintentando'
        WHEN 3 THEN 'Cancelado'
        ELSE 'Desconocido'
    END          AS EstadoEjecucion,
    jh.message   AS Mensaje
FROM msdb.dbo.sysjobhistory jh
INNER JOIN msdb.dbo.sysjobs j ON jh.job_id = j.job_id
WHERE j.name IN (
    N'Mantenimiento_SistemaInventarioDB',
    N'Alerta_StockBajo_SistemaInventarioDB'
)
ORDER BY jh.instance_id DESC;
GO

-- VERIFICACION: Log de stock bajo generado

USE SistemaInventarioDB;
GO

SELECT
    IdLog,
    IdProducto,
    NombreProducto,
    StockActual,
    FechaAlerta
FROM LogStockBajo
ORDER BY FechaAlerta DESC;
GO