-- Crear Base de Datos
CREATE DATABASE SistemaInventarioDB;
GO

-- Seleccionar la Base de Datos
USE SistemaInventarioDB;
GO

USE SistemaInventarioDB;
GO

-- Tabla Categorias
CREATE TABLE Categorias (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria VARCHAR(100) NOT NULL
);
GO

-- Tabla Proveedores
CREATE TABLE Proveedores (
    IdProveedor INT IDENTITY(1,1) PRIMARY KEY,
    NombreProveedor VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20),
    Correo VARCHAR(100)
);
GO

-- Tabla Clientes
CREATE TABLE Clientes (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    NombreCliente VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20)
);
GO

-- Tabla Productos
CREATE TABLE Productos (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    NombreProducto VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL,
    IdCategoria INT NOT NULL,
    IdProveedor INT NOT NULL,

    CONSTRAINT FK_Productos_Categorias
        FOREIGN KEY (IdCategoria)
        REFERENCES Categorias(IdCategoria),

    CONSTRAINT FK_Productos_Proveedores
        FOREIGN KEY (IdProveedor)
        REFERENCES Proveedores(IdProveedor)
);
GO

-- Tabla Ventas
CREATE TABLE Ventas (
    IdVenta INT IDENTITY(1,1) PRIMARY KEY,
    FechaVenta DATETIME DEFAULT GETDATE(),
    IdCliente INT NOT NULL,
    Total DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Ventas_Clientes
        FOREIGN KEY (IdCliente)
        REFERENCES Clientes(IdCliente)
);
GO

-- Tabla DetalleVenta
CREATE TABLE DetalleVenta (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IdVenta INT NOT NULL,
    IdProducto INT NOT NULL,
    Cantidad INT NOT NULL,
    Subtotal DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_DetalleVenta_Ventas
        FOREIGN KEY (IdVenta)
        REFERENCES Ventas(IdVenta),

    CONSTRAINT FK_DetalleVenta_Productos
        FOREIGN KEY (IdProducto)
        REFERENCES Productos(IdProducto)
);
GO


-- Categorias
INSERT INTO Categorias (NombreCategoria)
VALUES
('Laptops'),
('Accesorios'),
('Monitores');

-- Proveedores
INSERT INTO Proveedores (NombreProveedor, Telefono, Correo)
VALUES
('Tech Supply', '8888-1111', 'tech@correo.com'),
('Global Store', '8888-2222', 'global@correo.com');

-- Clientes
INSERT INTO Clientes (NombreCliente, Telefono)
VALUES
('Juan Perez', '8888-3333'),
('Maria Lopez', '8888-4444');

-- Productos
INSERT INTO Productos
(NombreProducto, Precio, Stock, IdCategoria, IdProveedor)
VALUES
('Laptop HP', 850.00, 10, 1, 1),
('Mouse Logitech', 25.00, 50, 2, 2),
('Monitor Samsung', 220.00, 15, 3, 1);

-- Ventas
INSERT INTO Ventas
(IdCliente, Total)
VALUES
(1, 900.00),
(2, 245.00);

-- DetalleVenta
INSERT INTO DetalleVenta
(IdVenta, IdProducto, Cantidad, Subtotal)
VALUES
(1, 1, 1, 850.00),
(1, 2, 2, 50.00),
(2, 3, 1, 220.00),
(2, 2, 1, 25.00);

SELECT * FROM Categorias;
SELECT * FROM Proveedores;
SELECT * FROM Clientes;
SELECT * FROM Productos;
SELECT * FROM Ventas;
SELECT * FROM DetalleVenta;
