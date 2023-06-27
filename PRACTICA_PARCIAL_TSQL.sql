/*2) Se requiere recategorizar los encargados asignados a los depositos. 
Para ello cree el o los objetos de bases de datos necesarios que lo resuelva, 
teniendo en cuenta que un deposito no puede tener como encargado un empleado que 
pertenezca a un departamente que no sea de la misma zona que el deposito, si esto 
ocurrea dicho deposito debera asignarsele el empleado con menos depositos asignados
que pertenezca a un departamento de esa zona.*/

--tipo de objeto: procedure

--recategorizar encargados asignados a depositos

--Un deposito no puede tener como encargado un empleado que pertenezca a un departamento
--que no sea de la misma zona que el deposito

--si se cumple eso el deposito debera asignarsele el empleado con menos depositos asignados
--que pertenezca a un departamento de esa zona

CREATE PROCEDURE ejercicio2
AS
BEGIN

    DECLARE @encargadoCod NUMERIC(6,0)
    DECLARE @zonadeposito CHAR(3)
    DECLARE @depoCod CHAR(2)

    DECLARE cursor_depo CURSOR FOR (SELECT depo_codigo, depo_zona
                                    FROM DEPOSITO
                                    JOIN Empleado ON (depo_encargado = empl_codigo)
                                    JOIN Departamento ON (empl_departamento = depa_codigo)
                                    WHERE depo_zona <> depa_zona) 
    OPEN cursor_depo

    FETCH NEXT FROM cursor_depo
    INTO @depoCod

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @encargadoCod = (SELECT TOP 1 empl_codigo
                             FROM Empleado
                                JOIN Departamento ON (empl_departamento = depa_codigo)
                                JOIN DEPOSITO ON (empl_codigo = depo_encargado)
                            WHERE depa_zona = @zonadeposito
                            GROUP BY empl_codigo
                            ORDER BY COUNT(depo_codigo) ASC)

        UPDATE DEPOSITO SET depo_encargado = @encargadoCod WHERE depo_codigo = @deposito

        FETCH NEXT FROM cursor_depo
		INTO @depoCod, @zonadeposito
    END
    CLOSE cursor_depo
	DEALLOCATE cursor_depo
END

GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--PARCIAL 2 (de una clase de repaso de 2020)

/*2) Implementar los objetos necesarios para que mediante la instruccion update se puedas cambiar
el codigo de un cliente. Ademas no debera permitir al usuario que haga updates de codigos que
afecten a mas de una fila*/

GO
CREATE TRIGGER cambiarCod ON Cliente INSTEAD OF UPDATE
AS

BEGIN

	IF (SELECT COUNT(*) FROM deleted) > 1
		BEGIN
			PRINT 'No puede actualizar mas de un codigo de cliente.'
		END

	ELSE IF ((SELECT clie_codigo FROM inserted) != (SELECT clie_codigo FROM deleted))
	BEGIN
		INSERT INTO Cliente
		SELECT * FROM inserted 

		UPDATE Factura
		SET fact_cliente = (SELECT clie_codigo FROM inserted)
		WHERE fact_cliente = (SELECT clie_codigo FROM deleted)

		DELETE FROM Cliente
		WHERE clie_codigo = (SELECT clie_codigo FROM deleted)
	END	

END
GO

--El primer IF es para verificar que no hagan updates masivos
--El else if verifica que el update que se hizo fue para cambiar el codigo 
--No se puede hacer update en cliente sino llama al trigger devuelta. Por eso hay que hacer insert de lo nuevo y delete de lo viejo
--inserted y deleted van a tener un campo solo cada una por el if que hicimos al principio
--Este punto es imposible en la vida real ya que tendrias que verificar campo por campo para ver que es lo que cambia el update usando la funcion COLUMN

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock 
suficiente del producto en el deposito ‘00’.

Nota: En caso de que se facture un producto compuesto, por ejemplo, combo1, deberá controlar que exista stock en el deposito ‘00’ 
de cada uno de sus componentes
*/

--FUNCION Y TRIGGER

--con la funcion controlo si el deposito tiene stock suficiente del producto
--el trigger usa la funcion y va verificando con cada producto si se cumple lo de la funcion para controlar si puede factura o no el deposito


CREATE FUNCTION dbo.funcion_hay_stock (@Producto CHAR(8), @Cantidad INT)
RETURNS INT
AS
BEGIN
	DECLARE @Resultado INT

	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Producto) --(si no es un producto compuesto entra aca)
	BEGIN
		IF((SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = @Producto AND stoc_deposito = '00') > @Cantidad)
			SET @Resultado = 1
		ELSE 
			SET @Resultado = 0
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM STOCK JOIN Composicion c ON (c.comp_producto = @Producto AND stoc_cantidad = c.comp_componente)
					WHERE stoc_cantidad < c.comp_cantidad * @Cantidad AND stoc_deposito = '00') --(analiza si existe al menos un prod con componentes que NO tenga stock)
			SET @Resultado = 0
		ELSE
			SET @Resultado = 1
	END
RETURN @Resultado
END

GO

CREATE TRIGGER dbo.noFacturar ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	DECLARE @Producto CHAR(8)
	DECLARE @Cantidad INT

	DECLARE cursor_item CURSOR FOR (SELECT i.item_producto, i.item_cantidad FROM inserted i)

	OPEN cursor_item

    FETCH NEXT FROM cursor_item
    INTO @Producto, @Cantidad

    WHILE @@FETCH_STATUS = 0
    BEGIN
		
		IF(dbo.funcion_hay_stock(@Producto, @Cantidad) = 1)
		BEGIN
			INSERT INTO Item_Factura
				SELECT * FROM inserted i WHERE i.item_producto = @Producto AND i.item_cantidad = @Cantidad
		END
		ELSE
			RAISERROR('EL producto no tiene stock',1,1)

		FETCH NEXT FROM cursor_item
		INTO  @Producto, @Cantidad
    END

    CLOSE cursor_item

	DEALLOCATE cursor_item
END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
Implementar el/los objetos necesarios para poder registrar cuáles son los productos que requieren reponer su stock. 
Como tarea preventiva, semanalmente se analizará esta información para que la falta de stock no sea una traba al momento 
de realizar una venta.

Esto se calcula teniendo en cuenta el stoc_punto_reposicion, es decir, si éste supera en un 10% al stoc_cantidad 
deberá registrarse el producto y la cantidad a reponer.

Considerar que la cantidad a reponer no debe ser mayor a stoc_stock_maximo (cant_reponer= stoc_stock_maximo - stoc_cantidad)
*/

--Registrar cuales son los productos que requieren reponer stock

--indica el tiempo en que se realiza, puede ser un trigger 

--si stoc_punto_resposicion > al 10% de stoc_cantidad => registrar producto y cantidad a reponer

--cant_reponer < stoc_stock_maximo (SI O SI)

--cant_reponer= stoc_stock_maximo - stoc_cantidad

--el trigger tiene que verificar las condiciones mencionadas y el prod que lo cumpla registrarlo y su cant a reponer

CREATE TRIGGER dbo.reponerStock ON STOCK FOR INSERT
AS
BEGIN
	DECLARE @ProdReponer CHAR(8)
	DECLARE @StockReponer INT

	DECLARE cursor_stock CURSOR FOR (SELECT stoc_producto, stoc_cantidad FROM STOCK)

	OPEN cursor_stock

	FETCH NEXT FROM cursor_sotck
	INTO @ProdReponer, @StockReponer

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @StockReponer = ISNULL((SELECT (stoc_stock_maximo - stoc_cantidad) AS cant_reponer FROM STOCK
									WHERE (stoc_punto_reposicion > (0.10 * stoc_cantidad)) AND (stoc_stock_maximo - stoc_cantidad) < stoc_stock_maximo AND stoc_producto = @ProdReponer),0) 
		SET @ProdReponer = (SELECT stoc_producto FROM STOCK
							WHERE (stoc_punto_reposicion > (0.10 * stoc_cantidad)) AND (stoc_stock_maximo - stoc_cantidad) < stoc_stock_maximo AND stoc_cantidad = @StockReponer)
	END

	CLOSE cursor_stock

	DEALLOCATE cursor_stock

END

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
Implementar el/los objetos necesarios para implementar la siguiente restricción en linea:

“Toda Composición (Ej: COMBO 1) debe estar compuesta solamente por productos simples 
(Ej: COMBO4 compuesto por: 4 Hamburguesas, 2 gaseosas y 2 papas). 
No se permitirá que un combo este compuesto por ningún otro combo.”

Se sabe que en la actualidad dicha regla se cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos y tecnologías.
*/

--al decir que en la actualidad la regla funciona => usamos trigger

--usamos instead of para indicar que nomas pase el evento que sea remplazado por lo del trigger, o actualizado si ya estaba mal

--no olvidar que no solo es un insert, sino que tambien update porque ya hay combos que pueden estar mal y hay que arreglar

--nuestro universo es Composicion ya que habla de ese en especifico

--lo hago con cursores para recorrer todos los combos que hay

GO
CREATE TRIGGER dbo.soloCombosSimples ON Composicion INSTEAD OF INSERT,UPDATE
AS
BEGIN
	--en primer lugar evaluamos si el combo no estaba creado, si es asi entra directo
	IF ((SELECT COUNT(*) FROM deleted) = 0)
	BEGIN
		--declaramos los componentes que va a tener dicho combo
		DECLARE @producto CHAR(6)
		DECLARE @componente CHAR(6)


		--declaramos el cursor que va a recorrer cada variable declarada y agregarle datos
		DECLARE C_Comps CURSOR FOR (SELECT i.comp_producto,i.comp_componente FROM inserted i)

		--iniciamos el cursor
		OPEN C_Comps 

		--le indicamos su recorrido
		FETCH NEXT FROM C_Comps 
		INTO @producto,@componente
		
		WHILE @@FETCH_STATUS=0
		BEGIN
			IF EXISTS(SELECT * FROM Composicion WHERE comp_producto = @componente) -- verifica si el componente es un producto compuesto
				PRINT('La composicion solo puede ser simple')
				ELSE
					BEGIN
						INSERT INTO Composicion SELECT * FROM inserted i WHERE i.comp_componente = @componente AND i.comp_producto = @producto
					END
				FETCH NEXT FROM C_Comps INTO @producto,@componente
			END
			CLOSE C_Comps
			DEALLOCATE C_Comps
		END
		
		--ahora en este entrar los combos que ya estaban creados y va a verificar cuales cumplen o no
		ELSE
		BEGIN --En caso de ser un UPDATE //Si agregas arriba un IF UPDATE(comp_componente) deberia saltear los casos que updatearon otras cosas
			
			DECLARE @prod CHAR(6)
			DECLARE @comp CHAR(6)

			DECLARE @cant INT
			DECLARE @prodDel CHAR(6)
			DECLARE @compDel CHAR(6)

			--uno saca los que no cumplen a la tabla deleted
			DECLARE C_CompsUpd CURSOR FOR (SELECT d.comp_producto,d.comp_componente FROM deleted d)

			--el otro agrega a la tabla inserted los que cumplen
			DECLARE C_CompsNuevo CURSOR FOR (SELECT i.comp_cantidad,i.comp_producto,i.comp_componente FROM inserted i)

			OPEN C_CompsUpd 
			OPEN C_CompsNuevo

			--Necesito el cursor de deleted para hacer el DELETE en caso de tener que actualizar la info
			FETCH NEXT FROM C_CompsUpd 
			INTO @prodDel,@compDel 

			--El cursor de inserted nos permite cargar en esta tabla los nuevos valores que cumplen
			FETCH NEXT FROM C_CompsNuevo 
			INTO @cant,@prod,@comp

			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @comp)  -- verifica si el componente es un producto compuesto
					PRINT ('La composicion solo puede ser simple')

				ELSE
					BEGIN
						DELETE FROM Composicion WHERE comp_producto = @prodDel AND comp_componente = @compDel
						INSERT INTO Composicion VALUES(@cant, @prod, @comp) 
					END

				FETCH NEXT FROM C_CompsUpd INTO @prodDel, @compDel
				FETCH NEXT FROM C_CompsNuevo INTO @cant, @prod, @comp
			END

			CLOSE C_CompsUpd
			DEALLOCATE C_CompsUpd

	END
END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--PARCIAL 12-11-2019

/*2) Recalcular precios de prods con composicion
Nuevo precio: suma de precio compontentes * 0,8 
*/

--objetos: funcion y procedure

--primero consultamos si precio_compuesto no es nulo

IF OBJECT_ID('precio_compuesto') IS NOT NULL
	DROP FUNCTION precio_compuesto 
GO

CREATE FUNCTION precio_compuesto (@Producto CHAR(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
	DECLARE @Precio DECIMAL(12,2)

	/*If a product has no componentes, its price is its own price.
	If it has N componentes, its price is the sum of its components*/

	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Producto)
		BEGIN
			SET @Precio = (SELECT prod_precio FROM Producto WHERE prod_codigo = @Producto)
			RETURN @Precio
		END

	--si llego aca es porque hay al menos un componente en mi producto

	DECLARE @Componente CHAR(8)
	DECLARE @Componente_cant DECIMAL(12,2)

	DECLARE cursor_2 CURSOR FOR (SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @Producto)

	OPEN cursor_2

	FETCH NEXT FROM cursor_2
	INTO @Componente, @Componente_cant

	WHILE @@FETCH_STATUS = 1
	BEGIN
		SET @Precio = @Precio + dbo.precio_compuesto(@Componente) * @Componente_cant * 0.8 --80% del componente
		
		FETCH NEXT FROM cursor_2 
		INTO @Componente, @Componente_cant
	END

	CLOSE cursor_2

	DEALLOCATE cursor_2

	RETURN @Precio
END
GO

IF OBJECT_ID('NUEVO_PRECIO') IS NOT NULL
	DROP PROCEDURE NUEVO_PRECIO 
GO

CREATE PROCEDURE NUEVO_PRECIO
AS
BEGIN
	DECLARE @prod_codigo CHAR(8)

	--obtengo productos con composicion

	DECLARE cursor_1 CURSOR FOR (SELECT prod_codigo FROM Producto JOIN Composicion ON (comp_producto = prod_codigo))

	OPEN cursor_1

	FETCH NEXT cursor_1
	INTO @prod_codigo

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE Producto
		SET prod_precio = dbo.precio_compuesto(@prod_codigo)
						  WHERE prod_codigo = @prod_codigo
		FETCH NEXT FROM cursor_1 
		INTO @prod_codigo
	END

	CLOSE cursor_1

	DEALLOCATE cursor_1
END
GO


/*--------------------------------------------------------------------------------------------------------------------------------------*/

--PARCIAL 2020

/*2)Implementar el/los objetos necesarios para implementar la siguiente restricción en línea:

Cuando se inserta en una venta un COMBO, nunca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes.
 
 Nota: Se sabe que actualmente todos los artículos guardados de ventas están descompuestos en sus componentes.*/

 /*ACLARACIONES*/
 /*Se debe crear un trigger para poder automatizar el chequeo pedido cada vez que se inserta, no un stored procedure porque debería llamarse y tampoco una función porque
 no busca retornar nada, sólo causar efecto*/

 /*Sería correcto que no se inserte el combo, sino en lugar de insertar el combo se inserten sus componentes, también podría utilizarse un FOR/AFTER pero considero que es preferible
 no insertar antes que insertar algo erroneo y luego borrarlo*/

 /*NO se contemplan combos dentro de otros combos, se toman los componentes como productos atómicos*/

 --Si bien habla de ventas, al guardar cada componente por separado esto lo hacemos en Item_Factura


CREATE TRIGGER ejercicio2 ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	
	--pensar que estamos guardando un nuevo item en la tabla Item_Factura, y por eso requiere completar todos los parametros de Item_Factura
	DECLARE @CompTipo CHAR(1)
	DECLARE @CompSucursal CHAR(4)
	DECLARE @CompNumero CHAR(8)
	DECLARE @CompProducto CHAR(8)
	DECLARE @CompCantidad DECIMAL(12,2)
	DECLARE @CompPrecio DECIMAL(12,2)

	DECLARE cursor_componente CURSOR FOR (SELECT item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio FROM Item_Factura)

	OPEN cursor_componente
	
	FETCH NEXT FROM cursor_componente
	INTO @CompTipo, @CompSucursal, @CompNumero, @CompProducto, @CompCantidad, @CompPrecio

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--pregunto si existe el combo
		IF EXISTS (SELECT 1 FROM Composicion WHERE comp_producto = @CompProducto)
		BEGIN
		--En este caso como ya existia el combo lo que tenemos que hacer guardar sus componentes por separado
			INSERT INTO Item_Factura SELECT @CompTipo, @CompSucursal, @CompNumero, c.comp_componente, c.comp_cantidad, prod_precio
									 FROM Composicion c
										JOIN Producto ON (prod_codigo = c.comp_componente)
									 WHERE c.comp_producto = @CompProducto
		END

		ELSE
		BEGIN
		--En el caso de que no exista lo guarda tal cual en la tabla
			INSERT INTO Item_Factura VALUES (@CompTipo, @CompSucursal, @CompNumero, @CompProducto, @CompCantidad, @CompPrecio)
		END
		FETCH NEXT FROM cursor_componente INTO @CompTipo, @CompSucursal, @CompNumero, @CompProducto, @CompCantidad, @CompPrecio

	END

	CLOSE cursor_componente

	DEALLOCATE cursor_componente

END

--PRUEBA, EL '00001104' ES UN COMBO DE 2 PRODUCTOS
  INSERT INTO Item_Factura VALUES ('A', '0003', '00089605', '00001104', 1, 100)


--EN SU LUGAR SE DEBEN INSERTAR LOS PRODUCTOS '00001109' Y '00001123'
 SELECT * FROM Item_Factura  WHERE ITEM_NUMERO = '00089605' ORDER BY item_numero

 --Efectivamente, a los 3 registros previos con esa factura se le agregan los 2 nuevos productos mencionados.

 
/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
De las 10 familias de productos que menores ventas tuvieron en el 2011 
(considerar como menor también si no se tuvo ventas), se le pide mostrar:
Detalle de la Familia
Monto total Facturado por familia en el año
Cantidad de productos distintos comprados de la familia
Cantidad de productos con composición que tiene la familia
Cliente que más compro productos de esa familia.
Nota: No se permiten sub select en el FROM.
*/

-- PARTE T-SQL

/*Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las ventas de unidades promedio 
de los últimos 3 meses anteriores A UNA FECHA. 

Se solicita que se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado.
*/

CREATE TABLE Reposicion(
	
	producto CHAR(8),
	cant_reponer DECIMAL(12,2)
);

CREATE PROCEDURE estimar_stock (@Fecha smalldatetime)
AS
BEGIN
	INSERT INTO Reposicion
	SELECT item_producto, SUM(item_cantidad)/3 
	FROM Item_Factura 
		JOIN Factura ON (fact_numero + fact_tipo + fact_sucursal = item_numero + item_tipo + item_sucursal)
	WHERE MONTH(@Fecha) - MONTH(fact_fecha) <= 3
	GROUP BY item_producto
END
GO

--forma de hacer con cursores

/*--OTRA SOLUCIÓN CON CURSOR
CREATE PROCEDURE EJERCICIO (@FECHA smalldatetime)
AS
BEGIN
	DECLARE @PRODUCTO char(8)
	DECLARE @CANTREPONER decimal(12,2)

	DECLARE C1 CURSOR FOR (SELECT item_producto,SUM(item_cantidad) / 3 FROM Factura
						   JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
						   WHERE fact_fecha BETWEEN (MONTH(@FECHA)-3) AND @FECHA
						   GROUP BY item_producto 
						   )
	OPEN C1
	FETCH NEXT FROM C1
	INTO @PRODUCTO,@CANTREPONER
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Reposicion
		VALUES(@PRODUCTO,@CANTREPONER)

		FETCH NEXT FROM C1
		INTO @PRODUCTO,@CANTREPONER
	END
	CLOSE C1
	DEALLOCATE C1
END*/

/*--------------------------------------------------------------------------------------------------------------------------------------*/


/* Dada una tabla llamada TOP_Cliente, en la cual está el cliente que más unidades compro de todos los productos 
en todos los tiempos se le pide que implemente el/los objetos necesarios para que la misma esté siempre actualizada. 

La estructura de la tabla es TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos y 
cumplen con la condición.
*/

CREATE TABLE TOP_CLIENTE(
	ID_CLIENTE CHAR(6),
	CANTIDAD_TOTAL_COMPRADA DECIMAL(12,2)
);

 /*está el cliente que más unidades compro de todos los productos 
en todos los tiempos*/

CREATE TRIGGER ejercicio ON Item_Factura FOR INSERT,UPDATE
AS
BEGIN
	
	DECLARE @ClieCod CHAR(6)
	DECLARE @CantComprClie DECIMAL(12,2)
	DECLARE @CantEnTabla DECIMAL(12,2)

	SET @CantEnTabla = (SELECT MAX(CANTIDAD_TOTAL_COMPRADA) FROM TOP_CLIENTE)

	DECLARE cursor_clie CURSOR FOR (SELECT fact_cliente, SUM(item_cantidad) 
									FROM inserted
										JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
									GROUP BY fact_cliente)
	OPEN cursor_clie

	FETCH NEXT FROM cursor_clie
	INTO @ClieCod, @CantComprClie

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@CantEnTabla < @CantComprClie)
		BEGIN
			UPDATE TOP_CLIENTE SET 
			ID_CLIENTE = @ClieCod,
			CANTIDAD_TOTAL_COMPRADA = @CantComprClie FROM TOP_CLIENTE WHERE CANTIDAD_TOTAL_COMPRADA = @CantEnTabla 
		END
		FETCH NEXT FROM cursor_clie
		INTO @ClieCod,@CantComprClie
	END

	CLOSE cursor_clie

	DEALLOCATE cursor_clie

END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*T-SQL
Agregar el/los objetos necesarios para que se permita mantener la siguiente restricción:

Nunca un jefe va a poder tener más de 20 personas a cargo y menos de 1.

Nota: Considerar solo 1 nivel de la relación empleado-jefe.
*/

--MI RESOLUCION
CREATE FUNCTION personasACargo (@Jefe numeric(6,0))
RETURNS INT 
AS 
BEGIN
	DECLARE @PersonalACargo INT 

	IF NOT EXISTS(SELECT * FROM Empleado WHERE empl_jefe = @Jefe)
	BEGIN
		SET @PersonalACargo = 0
		RETURN @PersonalACargo 
	END
	ELSE
	BEGIN
		SET @PersonalACargo = @PersonalACargo + (SELECT COUNT(dbo.personasACargo(empl_codigo))
											     FROM Empleado
												 WHERE empl_jefe = @Jefe)
		RETURN @PersonalACargo
	END
END
GO


CREATE TRIGGER restriccionJefes ON Empleado FOR INSERT, UPDATE
AS
BEGIN
	IF EXISTS(SELECT * FROM inserted i WHERE dbo.personasACargo(i.empl_jefe) < 20 AND dbo.personasACargo(i.empl_jefe) > 1)
	BEGIN
		ROLLBACK
	END
END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--RESOLUCION DEL CHABON
CREATE TRIGGER Parcial2 ON Empleado AFTER INSERT,UPDATE
AS
BEGIN
    DECLARE @Jefe NUMERIC(6,0)

    DECLARE C1 CURSOR FOR SELECT empl_jefe FROM inserted GROUP BY empl_jefe

    OPEN C1

    FETCH NEXT FROM C1 
    INTO @Jefe
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF(SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @Jefe) > 20 AND (SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @Jefe) < 1
            BEGIN
					ROLLBACK

                    FETCH NEXT FROM C1 
                    INTO @Jefe
            END
        END

        CLOSE C1
        DEALLOCATE C1
    
END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 2
Implementar el/los objetos necesarios para contorlar que nunca se pueda facturar un producto si no hay stock suficiente del producto en el depósito 00.
NOTA: En caso de que se facturé un producto compuesto por ejemplo COMBO1 deberá controlar que exista stock en el depósito 00 de cada uno de sus componentes.
*/

--FORMA 1 DE HACERLO
CREATE FUNCTION dbo.funcion_hay_stock (@Producto CHAR(8), @Cantidad INT)
RETURNS INT
AS
BEGIN
	DECLARE @Resultado INT

	IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Producto) --(si no es un producto compuesto entra aca)
	BEGIN
		IF((SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = @Producto AND stoc_deposito = '00') > @Cantidad)
			SET @Resultado = 1
		ELSE 
			SET @Resultado = 0
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM STOCK JOIN Composicion c ON (c.comp_producto = @Producto AND stoc_cantidad = c.comp_componente)
					WHERE stoc_cantidad < c.comp_cantidad * @Cantidad AND stoc_deposito = '00') --(analiza si existe al menos un prod con componentes que NO tenga stock)
			SET @Resultado = 0
		ELSE
			SET @Resultado = 1
	END
RETURN @Resultado
END

GO

CREATE TRIGGER dbo.noFacturar ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	DECLARE @Producto CHAR(8)
	DECLARE @Cantidad INT

	DECLARE cursor_item CURSOR FOR (SELECT i.item_producto, i.item_cantidad FROM inserted i)

	OPEN cursor_item

    FETCH NEXT FROM cursor_item
    INTO @Producto, @Cantidad

    WHILE @@FETCH_STATUS = 0
    BEGIN
		
		IF(dbo.funcion_hay_stock(@Producto, @Cantidad) = 1)
		BEGIN
			INSERT INTO Item_Factura
				SELECT * FROM inserted i WHERE i.item_producto = @Producto AND i.item_cantidad = @Cantidad
		END
		ELSE
			RAISERROR('EL producto no tiene stock',1,1)

		FETCH NEXT FROM cursor_item
		INTO  @Producto, @Cantidad
    END

    CLOSE cursor_item

	DEALLOCATE cursor_item
END
GO


--FORMA 2 DE HACERLO
CREATE TRIGGER dbo.FOTO2 ON Item_Factura FOR INSERT
AS
BEGIN
		IF EXISTS (SELECT item_producto,item_cantidad FROM inserted WHERE dbo.NoCumpleStock(item_producto,item_cantidad) = 1)
		BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	
END
GO

CREATE FUNCTION dbo.NoCumpleStock(@PRODUCTO CHAR(8), @CANT_VENDIDA DECIMAL(12,2))
RETURNS INT
BEGIN
	DECLARE @PRODUCTOAUX CHAR(8)
	
	IF(SELECT stoc_cantidad FROM STOCK WHERE stoc_producto=@PRODUCTO AND stoc_deposito='00') < @CANT_VENDIDA
			RETURN 1

	DECLARE C1 CURSOR FOR SELECT comp_componente FROM Composicion WHERE comp_producto=@PRODUCTO
	OPEN C1
	FETCH NEXT FROM C1
	INTO @PRODUCTOAUX
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(dbo.NoCumpleStock(@PRODUCTOAUX ,@CANT_VENDIDA) = 1 )
			RETURN 1

		FETCH NEXT FROM C1 
		INTO @PRODUCTOAUX
	END
	CLOSE C1
	DEALLOCATE C1

	RETURN 0
END

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*FOTO 5
Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de día consecutivos a partir de esa fecha
que el producto tuvo al menos la venta de una unidad en el día, el sistemas de ventas on-line estará habilitado 24-7 por lo que se deben evaluar 
todos los días incluyendo domingos y feriados.
*/
CREATE PROCEDURE dias_consecutivos(@Producto CHAR(8), @Fecha SMALLDATETIME, @CantVentas DECIMAL(12,2) OUTPUT)
AS
BEGIN
	DECLARE @FechaVenta SMALLDATETIME

	SET @CantVentas = 0

	DECLARE cursor_ventas CURSOR FOR SELECT fact_fecha 
									  FROM Factura 
										JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
									  WHERE item_producto = @Producto
									  GROUP BY fact_fecha
									  ORDER BY fact_fecha
	OPEN cursor_ventas

	FETCH NEXT FROM cursor_ventas
	INTO @FechaVenta

	WHILE @@FETCH_STATUS = 0
	BEGIN
			IF(DATEDIFF(DD,@Fecha,@FechaVenta) < 1)
			BEGIN
				SET @CantVentas = @CantVentas + 1
				SELECT DATEADD(DD,-1, @Fecha);
			END
	FETCH NEXT FROM cursor_ventas
	INTO @FechaVenta
	END

END

--Testsssss
SELECT fact_fecha FROM Factura
JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
GROUP BY fact_fecha 
ORDER BY fact_fecha

SELECT DATEADD(month, -1, '2010-01-23');
SELECT DATEADD(month, 1, '20060831');

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 6 T-SQL
Realizar un stored procedure que dado un numero de factura,tipo y sucursal inserte un nuevo registro de item, actualicé los valores de totales de
factura más impuestos y reste el stock de ese producto en la tabla correspondiente. 
Se debe validar previamente la existencia del stock en ese depósito y en caso de no haber, no realizar nada.

--PARAMETROS
Los parametros de entrada son datos de la factura,código del producto y cantidad.

UPDATE:
Al total de factura se le suma lo correspondiente solo al nuevo item sin hacer recalculos, y en los impuestos se le suma 21% de dicho valor 
redondeado a dos decimales, se debe contemplar la posibilidad que esos dos campos esten en NULL al comienzo del procedure.

CONSIDERACIONES:
Se debe programar una transacción para que las tres operaciones se realicen atómicamente, se asume que todos los parámetros recibidos están 
validados a excepción de la cantidad de producto del stock.

Queda a criterio del alumno que acciones tomar en caso de que no se cumpla la única validación o no se produzca un error no provisto.
*/

CREATE PROCEDURE foto6 (@FactNumero CHAR(8), @FactTipo CHAR(1), @FactSucursal CHAR(4), @Producto CHAR(8),@Cantidad DECIMAL(12,2))
AS 
BEGIN
	
	DECLARE @Precio DECIMAL(12,2)
	DECLARE @Total DECIMAL(12,2)
		
	IF(SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = @Producto AND stoc_cantidad > @Cantidad)
	BEGIN
		
		--INSERT
		INSERT INTO Item_Factura
		VALUES(@FactTipo, @FactSucursal, @FactNumero, @Producto,@Cantidad, @Precio)
	
		--UPDATE
		UPDATE Factura
		SET fact_total = @Total,
		fact_total_impuestos = @Total * 0.21

		-- restar del stock la tabla correspondiente
		UPDATE STOCK
		SET stoc_cantidad = stoc_cantidad - @Cantidad
							WHERE stoc_deposito IN (SELECT TOP 1 stoc_deposito FROM  STOCK WHERE stoc_producto = @Producto)

	END
	ELSE
	BEGIN
		PRINT 'NO SE PUEDE REALIZAR LA FACTURACIÓN PORQUE NO HAY STOCK DEL PRODUCTO' 
		ROLLBACK
	END
END
GO

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 9 T-SQL
Implementar el/los objetos necesarios para controlar que la máxima cantidad de empleados por DEPARTAMENTO sea 60
*/

CREATE TRIGGER FOTO9 ON Empleado FOR INSERT,UPDATE
AS
BEGIN 
	DECLARE @CANTIDADEMPLEADOS decimal(12,2)
	DECLARE @EMPLEADO numeric(6,0)
	DECLARE @DEPARTAMENTO numeric(6,0)

	DECLARE C1 CURSOR FOR (SELECT empl_departamento FROM inserted)
	OPEN C1

	FETCH NEXT FROM C1
	INTO @DEPARTAMENTO

	WHILE @@FETCH_STATUS=0
	BEGIN
		IF(SELECT COUNT(*) FROM Empleado JOIN Departamento ON depa_codigo=empl_departamento WHERE depa_codigo=@DEPARTAMENTO) >= 60
			ROLLBACK

	END
	CLOSE C1
	DEALLOCATE C1
END
GO


/*--------------------------------------------------------------------------------------------------------------------------------------*/

--EJERCICIO DE LA GUIA CON RECURSIVIDAD SUPER DIFICIL

/*6. Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.*/

create PROCEDURE SP_UNIFICAR_PRODUCTO
AS
BEGIN
	declare @combo char(8);
	declare @combocantidad integer;
	
	declare @fact_tipo char(1);
	declare @fact_suc char(4);
	declare @fact_nro char(8);
	
	
	
	declare  cFacturas cursor for --CURSOR PARA RECORRER LAS FACTURAS
		select fact_tipo, fact_sucursal, fact_numero
		from Factura ;
		/* where para hacer una prueba acotada
		where fact_tipo = 'A' and
				fact_sucursal = '0003' and
				fact_numero='00092476'; */
		
		open cFacturas
		
		fetch next from cFacturas
		into @fact_tipo, @fact_suc, @fact_nro
		
		while @@FETCH_STATUS = 0
		begin	
			declare  cProducto cursor for
			select comp_producto --ACA NECESITAMOS UN CURSOR PORQUE PUEDE HABER MAS DE UN COMBO EN UNA FACTURA
			from Item_Factura join Composicion C1 on (item_producto = C1.comp_componente)
			where item_cantidad >= C1.comp_cantidad and
				  item_sucursal = @fact_suc and
				  item_numero = @fact_nro and
				  item_tipo = @fact_tipo
			group by C1.comp_producto
			having COUNT(*) = (select COUNT(*) from Composicion as C2 where C2.comp_producto= C1.comp_producto)
			
			open cProducto
			fetch next from cProducto into @combo
			while @@FETCH_STATUS = 0 
			begin
	  					
				select @combocantidad= MIN(FLOOR((item_cantidad/c1.comp_cantidad)))
				from Item_Factura join Composicion C1 on (item_producto = C1.comp_componente)
				where item_cantidad >= C1.comp_cantidad and
					  item_sucursal = @fact_suc and
					  item_numero = @fact_nro and
					  item_tipo = @fact_tipo and
					  c1.comp_producto = @combo	--SACAMOS CUANTOS COMBOS PUEDO ARMAR COMO MÁXIMO (POR ESO EL MIN)
				
				--INSERTAMOS LA FILA DEL COMBO CON EL PRECIO QUE CORRESPONDE
				insert into Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
				select @fact_tipo, @fact_suc, @fact_nro, @combo, @combocantidad, (@combocantidad * (select prod_precio from Producto where prod_codigo = @combo));				

				update Item_Factura  
				set 
				item_cantidad = i1.item_cantidad - (@combocantidad * (select comp_cantidad from Composicion
																		where i1.item_producto = comp_componente 
																			  and comp_producto=@combo)),
				ITEM_PRECIO = (i1.item_cantidad - (@combocantidad * (select comp_cantidad from Composicion
															where i1.item_producto = comp_componente 
																  and comp_producto=@combo))) * 	
													(select prod_precio from Producto where prod_codigo = I1.item_producto)											  															  
				from Item_Factura I1, Composicion C1 
				where I1.item_sucursal = @fact_suc and
					  I1.item_numero = @fact_nro and
					  I1.item_tipo = @fact_tipo AND
					  I1.item_producto = C1.comp_componente AND
					  C1.comp_producto = @combo
					  
				delete from Item_Factura
				where item_sucursal = @fact_suc and
					  item_numero = @fact_nro and
					  item_tipo = @fact_tipo and
					  item_cantidad = 0
				
				fetch next from cproducto into @combo
			end
			close cProducto;
			deallocate cProducto;
			
			fetch next from cFacturas into @fact_tipo, @fact_suc, @fact_nro
			end
			close cFacturas;
			deallocate cFacturas;
	end