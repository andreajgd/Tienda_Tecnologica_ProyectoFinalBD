USE master;
GO

-- 1. Habilitar la característica avanzada en el motor
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE;
GO

-- 2. Crear la cuenta de correo SMTP externa
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'AlertasInventarioAccount',
    @description = 'Cuenta SMTP para el envío automatizado de alertas de base de datos.',
    @email_address = 'alertas.bd.uam@gmail.com',
    @display_name = 'SQL Server - SistemaInventarioDB',
    @mailserver_name = 'smtp.gmail.com',         
    @port = 587,                                 
    @username = 'alertas.bd.uam@gmail.com',
    @password = 'TuContraseñaDeAplicacion',      
    @enable_ssl = 1;                             
GO

-- 3. Crear el Perfil de Database Mail
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'PerfilAlertasInventario',
    @description = 'Perfil general de notificaciones del sistema de inventario.';
GO

-- 4. Asociar la Cuenta al Perfil
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'PerfilAlertasInventario',
    @account_name = 'AlertasInventarioAccount',
    @sequence_number = 1;
GO

-- 5. Conceder acceso público al perfil en msdb
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'PerfilAlertasInventario',
    @principal_name = 'public',
    @is_default = 1;
GO


EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'PerfilAlertasInventario',
    @recipients = 'lcguadamuz@uamv.edu.ni',
    @body = 'Confirmación de funcionamiento: El servicio Database Mail de SQL Server se encuentra activo y enviando notificaciones con éxito.',
    @subject = 'Prueba Exitosa de Notificación - Base de Datos UAM';
GO

SELECT 
    a.mailitem_id, 
    a.recipients, 
    a.send_request_date, 
    a.sent_status, 
    l.description AS [Mensaje_Error]
FROM msdb.dbo.sysmail_allitems a
LEFT JOIN msdb.dbo.sysmail_event_log l 
    ON a.mailitem_id = l.mailitem_id;



USE SistemaInventarioDB;
GO

CREATE PROCEDURE sp_RegistrarVenta
    @IdCliente INT,
    @IdProducto INT,
    @Cantidad INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @Precio DECIMAL(10,2);
        DECLARE @Subtotal DECIMAL(10,2);
        DECLARE @IdVenta INT;
        DECLARE @StockActual INT;

        -- Verificar Stock disponible en tiempo real
        SELECT @Precio = Precio, @StockActual = Stock FROM Productos WHERE IdProducto = @IdProducto;
        
        IF @StockActual < @Cantidad
        BEGIN
            RAISERROR('Stock insuficiente para realizar la venta.', 16, 1);
        END

        -- Calcular subtotal de la línea
        SET @Subtotal = @Precio * @Cantidad;

        -- 1. Registrar la cabecera de la Venta
        INSERT INTO Ventas (IdCliente, Total) VALUES (@IdCliente, @Subtotal);
        SET @IdVenta = SCOPE_IDENTITY();

        -- 2. Registrar el desglose en el Detalle de Venta
        INSERT INTO DetalleVenta (IdVenta, IdProducto, Cantidad, Subtotal)
        VALUES (@IdVenta, @IdProducto, @Cantidad, @Subtotal);

        -- 3. Descontar stock de la tabla Productos
        UPDATE Productos
        SET Stock = Stock - @Cantidad
        WHERE IdProducto = @IdProducto;

        COMMIT TRANSACTION;
        PRINT 'Operación Completada: Venta registrada y Stock actualizado correctamente.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO




EXEC sp_RegistrarVenta @IdCliente = 1, @IdProducto = 1, @Cantidad = 2;





USE SistemaInventarioDB;
GO

CREATE VIEW v_InventarioDetallado AS
SELECT 
    p.IdProducto AS [Código],
    p.NombreProducto AS [Producto],
    p.Precio AS [Precio Unitario],
    p.Stock AS [Existencias],
    c.NombreCategoria AS [Categoría],
    pr.NombreProveedor AS [Proveedor Contacto]
FROM Productos p
INNER JOIN Categorias c ON p.IdCategoria = c.IdCategoria
INNER JOIN Proveedores pr ON p.IdProveedor = pr.IdProveedor;
GO

SELECT * FROM v_InventarioDetallado;

USE SistemaInventarioDB;
GO

CREATE FUNCTION fn_CalcularValorInventario (@IdProducto INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @ValorTotal DECIMAL(10,2);

    SELECT @ValorTotal = (Precio * Stock)
    FROM Productos
    WHERE IdProducto = @IdProducto;

    RETURN ISNULL(@ValorTotal, 0);
END;
GO


SELECT *, dbo.fn_CalcularValorInventario([Código]) AS [Valor Financiero Almacén] 
FROM v_InventarioDetallado;