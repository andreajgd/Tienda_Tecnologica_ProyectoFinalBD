use SistemaInventarioDB;
go

/* Plan de mantenimiento: Actualización de estadísticas, mantenimiento de índices, Verificación de Integridad */

create or alter procedure dbo.usp_PlanMantenimiento
as
begin
    set nocount on;

    -- 1. Actualización de estadísticas
    exec sp_updatestats;

    -- 2. Mantenimiento de índices
    alter index all on dbo.Categorias reorganize;
    alter index all on dbo.Proveedores reorganize;
    alter index all on dbo.Clientes reorganize;
    alter index all on dbo.Productos reorganize;
    alter index all on dbo.Ventas reorganize;
    alter index all on dbo.DetalleVenta reorganize;

    -- 3. Verificación de integridad
    dbcc CHECKDB ('SistemaInventarioDB') with no_infomsgs;

end;
go

-- ejecutar plan de mantenimiento
exec dbo.usp_PlanMantenimiento;
go