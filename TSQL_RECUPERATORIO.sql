
/*NOTAS IMPORTANTES PARA NO OLVIDARSE EN EL EXAMEN

FUNCIONES: son las unicas que retornar cosas


PROCEDURES:
- procedimientos almacenados
- es un method como en un lenguaje, puede recibir parametros como no
- Los usamos cuando queremos corregir, actualizar informacion, completar datos en una tabla, recategorizar cosas, reasignar, migrar datos


TRIGGERS: (se dispara cuando se genera una accion en otra tabla, o dice actualmente)

- Si estoy usando un insert o deleted, las subconsultas que haga dentro del tipo de objeto tienen que ser a las tablas INSERTED o DELETED
- En los triggers, se puede volver todo atras con un ROLLBACK TRANSACTION
- En los casos que nos piden que algo NUNCA se cumpla, dependiendo el resto de la consigna, se puede usar un after y la operacion que siga,
  usando un rollback transaction borrando ese valor que no cumple 
- Cuando tenemos que evaluar una condicion muy grande, utilizar las funciones como atajos
- Si nos piden que no se cumpla o que se cumpla alguna condicion usualmente implementamos un for (operacion) 

- INSTEAD OF : antes de que suceda evento, se ejecuta lo que esta en el trigger
  (para darse cuenta leer como esta explicado, puede decir ante el intento de borrar o agregar, ahi ya sabemos que es esto )
- observacion: el instead of insert es para que NO SE HAGA el insert (o la operaicon que sea) y se haga lo que esta dentro del trigger


- FOR / AFTER : despues del evento, se ejecuta lo que esta dentro del trigger
- observacion: el for insert es para que se dispare antes de hacer el insert
- observacion: el after insert es para que se dispare despues de hacer el insert


OPERACIONES UPDATE, INSERT, DELETE:

- En el update, una vez que puse set desp le pongo los nuevos valores a las variables, y al final se le puede agregar como no una condicion


*/

--MI PRIMER PARCIAL
/*Actualmente el campo fact_vendedor representa al empleado que vendio la factura. 
Implementar el/los objetos necesarios para respetar la integridad referenciales de 
dicho campo suponiendo que no existe una foreign key entre ambos*/

--Por un lado preguntamos si no existe una relacion entre codigo del empleado y el vendedor, tenemos que insertar y updetear
CREATE TRIGGER fk_fact_vendedor_constraint ON Factura FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS(SELECT * FROM Empleado  WHERE empl_codigo IN (SELECT fact_vendedor FROM inserted))
	BEGIN
		PRINT 'No se puede tener facturas donde el codigo del vendedor no es el de un empleado, fk constraint'
		ROLLBACK TRANSACTION
	END
END
GO

--Por otro lado preguntamos si ya existe la relacion entre ambas, entonces no tenemos que eliminarla
CREATE TRIGGER fk_fact_vendedor_empleado_constraint ON Empleado FOR DELETE
AS 
BEGIN
	IF EXISTS (SELECT * FROM Factura WHERE fact_vendedor IN (SELECT empl_codigo FROM deleted))
	BEGIN	
		PRINT 'No se puede eliminar a estos empleados ya que al menos uno se encuentra como vendedor de una factura, FK constraint'
		ROLLBACK TRANSACTION
	END
END
GO

-- MI RECUPERATORIO DEL PRIMER PARCIAL
create table AUD_STOCK(
auds_renglon bigint,
auds_operacion char(3),
auds_fecha_hora smalldatetime,
auds_cantidad decimal(12,2),
auds_punto_reposicion decimal(12,2),
auds_stock_maximo decimal(12,2),
auds_detalle char(100),
auds_proxima_reposicion smalldatetime,
auds_producto char(8),
auds_deposito char(2))

create trigger ejercicio on stock instead of insert,update,delete
AS
BEGIN
declare @renglon bigint
declare @operacion char(3)
declare @fechar_hora smalldatetime
declare @cantidad decimal(12,2)
declare @punto_reposicion decimal(12,2)
declare @stock_maximo decimal(12,2)
declare @detalle char(100)
declare @proxima_reposicion smalldatetime
declare @producto char(8)
declare @deposito char(2)

    -- Operación de inserción
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
	DECLARE cursor_stock_ins CURSOR FOR (SELECT  stoc_cantidad,stoc_punto_reposicion,stoc_detalle,stoc_stock_maximo,stoc_proxima_reposicion,stoc_producto,stoc_deposito FROM inserted)

	open cursor_stock_ins
	FETCH NEXT FROM cursor_stock_ins
	INTO @cantidad,@punto_reposicion,@detalle, @stock_maximo, @proxima_reposicion, @producto, @deposito

	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @renglon = 1
		if exists (select * from AUD_STOCK)
		begin
			set @renglon = (select top 1 auds_renglon from AUD_STOCK order by auds_renglon desc) + 1
		end
		set @fechar_hora = GETDATE()
		set @operacion = 'INS'

	insert into AUD_STOCK values (@renglon,@operacion,@fechar_hora,@cantidad,@punto_reposicion,@stock_maximo,@detalle,@proxima_reposicion,@producto,@deposito)
	
	FETCH NEXT FROM cursor_stock_ins
	END

CLOSE cursor_stock_ins

DEALLOCATE cursor_stock_ins

    END;
    
    -- Operación de actualización
   ELSE IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
	DECLARE cursor_stock_up2 CURSOR FOR (SELECT  stoc_cantidad,stoc_punto_reposicion,stoc_detalle,stoc_stock_maximo,stoc_proxima_reposicion,stoc_producto,stoc_deposito FROM inserted)

	open cursor_stock_up2
	FETCH NEXT FROM cursor_stock_up2
	INTO @cantidad,@punto_reposicion,@detalle, @stock_maximo, @proxima_reposicion, @producto, @deposito

	WHILE @@FETCH_STATUS = 0
	BEGIN
		set @renglon = 1
		if exists (select * from AUD_STOCK)
		begin
			set @renglon = (select top 1 auds_renglon from AUD_STOCK order by auds_renglon desc) + 1
		end
		set @fechar_hora = GETDATE()
		set @operacion = 'UP2'

		insert into AUD_STOCK values (@renglon,@operacion,@fechar_hora,@cantidad,@punto_reposicion,@stock_maximo,@detalle,@proxima_reposicion,@producto,@deposito)
	FETCH NEXT FROM cursor_stock_up2
	END

	CLOSE cursor_stock_up2

	DEALLOCATE cursor_stock_up2

	DECLARE cursor_stock_up1 CURSOR FOR (SELECT  stoc_cantidad,stoc_punto_reposicion,stoc_detalle,stoc_stock_maximo,stoc_proxima_reposicion,stoc_producto,stoc_deposito FROM deleted)

	open cursor_stock_up1
	FETCH NEXT FROM cursor_stock_up1
	INTO @cantidad,@punto_reposicion,@detalle, @stock_maximo, @proxima_reposicion, @producto, @deposito

	WHILE @@FETCH_STATUS = 0
	BEGIN
	set @renglon = 1
	if exists (select * from AUD_STOCK)
	begin
	set @renglon = (select top 1 auds_renglon from AUD_STOCK order by auds_renglon desc) + 1
	end
	set @fechar_hora = GETDATE()
	set @operacion = 'UP1'

	insert into AUD_STOCK values (@renglon,@operacion,@fechar_hora,@cantidad,@punto_reposicion,@stock_maximo,@detalle,@proxima_reposicion,@producto,@deposito)
	
	FETCH NEXT FROM cursor_stock_up1
	END

	CLOSE cursor_stock_up1

	DEALLOCATE cursor_stock_up1

    END;
    
    -- Operación de eliminación
   ELSE IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)

    BEGIN
	DECLARE cursor_stock_del CURSOR FOR (SELECT  stoc_cantidad,stoc_punto_reposicion,stoc_detalle,stoc_stock_maximo,stoc_proxima_reposicion,stoc_producto,stoc_deposito FROM deleted)

	open cursor_stock_del
	FETCH NEXT FROM cursor_stock_del
	INTO @cantidad,@punto_reposicion,@detalle, @stock_maximo, @proxima_reposicion, @producto, @deposito

	WHILE @@FETCH_STATUS = 0
	BEGIN
	set @renglon = 1
	if exists (select * from AUD_STOCK)
	begin
	set @renglon = (select top 1 auds_renglon from AUD_STOCK order by auds_renglon desc) + 1
	end
	set @fechar_hora = GETDATE()
	set @operacion = 'DEL'

	insert into AUD_STOCK values (@renglon,@operacion,@fechar_hora,@cantidad,@punto_reposicion,@stock_maximo,@detalle,@proxima_reposicion,@producto,@deposito)
	
	FETCH NEXT FROM cursor_stock_del
	END

	CLOSE cursor_stock_del

	DEALLOCATE cursor_stock_del
    END;

end

--PRIMER PARCIAL NICO
/*Realizar un stored procedure que reciba un codigo de producto y una fecha y devuelva la mayor cantidad 
de dias consecutivos a partir de esa fecha que el producto tuvo al menos a la venta de una unidad en el dia,
el sistema de ventas on line esta habilitado 24-7 por que se deben evaluar todos los dias incluyendo domingos 
y feriados.*/

--recibe el prod_codigo y un fact_fecha
--nos devuelve la mayor cantidad de dias consecutivos a partir de esa fecha que el producto tuvo al menos
--a la venta de una unidad en el dia

CREATE PROC punto2 (@producto char(8), 
					@fecha datetime, 
					@max_dias_consecutivos int output)
AS
BEGIN
	DECLARE @dias_consecutivos INT
	DECLARE @fecha_venta DATETIME
	DECLARE @fecha_anterior DATETIME


	set @max_dias_consecutivos = 0	
	SET @dias_consecutivos = 0
	SET @fecha_anterior = GETDATE()

	declare cVentasDelProducto CURSOR FOR
	select fact_fecha 
	from Factura JOIN Item_Factura ON item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
	WHERE	item_producto = @producto AND
			fact_fecha > @fecha
	GROUP BY fact_fecha
	ORDER BY fact_fecha ASC

	open cVentasDelProducto
	FETCH NEXT FROM cVentasDelProducto INTO @fecha_venta
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if(@fecha_venta = dateadd(day, 1, @fecha_anterior))
		begin
			SET @dias_consecutivos = @dias_consecutivos + 1
		end
		else
		begin
			if(@dias_consecutivos > @max_dias_consecutivos)
			begin
				set @max_dias_consecutivos = @dias_consecutivos
			end
			SET @dias_consecutivos = 0
		end
		
		set @fecha_anterior = @fecha_venta
		FETCH NEXT FROM cVentasDelProducto INTO @fecha_venta
	END
	CLOSE cVentasDelProducto
	DEALLOCATE cVentasDelProducto

	return @max_dias_consecutivos
END
GO

--RECU PRIMER PARCIAL NICO
/*Se requiere realizar una verificacion de los precios de los COMBOS, para ello se solicita que cree el o los 
objetos necesarios para realizar una operacion que actualice que el precio de un producto compuesto (COMBO)
es el 90% de la suma de los precios de sus componentes por las cantidades que los componen. Se debe considerar
que un producto compuesto puede estar compuesto por otros productos compuestos*/

CREATE PROCEDURE nuevosPrecios
AS
BEGIN
	
	DECLARE @Combo CHAR(8)

	DECLARE cursor_combo CURSOR FOR (SELECT comp_producto FROM Producto JOIN Composicion ON (prod_codigo = comp_producto))

	OPEN cursor_combo 

	FETCH NEXT FROM cursor_combo
	INTO @Combo

	WHILE @@FETCH_STATUS = 0
	BEGIN
		UPDATE Producto
		SET prod_precio = 0.90 * precioNuevoCombo(@Combo)
		WHERE prod_codigo = @Combo
	END

END


CREATE FUNCTION precioNuevoCombo (@Combo CHAR(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
	
	DECLARE @PrecioNuevo DECIMAL(12,2)

	SET @PrecioNuevo = 0

	DECLARE @Componente CHAR(8)

	DECLARE cursor_comp CURSOR FOR (SELECT comp_componente 
										  FROM Composicion 
										  JOIN Producto ON (comp_componente = prod_codigo) 
										  WHERE comp_producto = @Combo)
	OPEN cursor_comp

	FETCH NEXT FROM cursor_comp
	INTO @Componente

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS(SELECT comp_componente 
				  FROM Composicion 
				  JOIN Producto ON (comp_componente = prod_codigo) 
				  WHERE comp_producto = @Combo AND comp_componente = @Componente)
		BEGIN
			DECLARE @prodPrecio DECIMAL(12,2)
			DECLARE @ProdCantidad DECIMAL(12,2)

			DECLARE cursor_prodComp CURSOR FOR (SELECT prod_precio, comp_cantidad
												FROM Composicion 
												JOIN Producto ON (comp_componente = prod_codigo)
												WHERE comp_producto = @Combo AND prod_codigo = @Componente)
			OPEN cursor_prodComp
			FETCH NEXT FROM cursor_prodComp
			INTO @prodPrecio, @ProdCantidad 

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @PrecioNuevo +=  @ProdCantidad * @prodPrecio

				FETCH NEXT FROM cursor_prodComp 
				INTO @ProdComponente, @prodPrecio, @ProdCantidad 
			END

			CLOSE cursor_prodComp
			DEALLOCATE cursor_prodComp
		END
		ELSE
		BEGIN
			SET @PrecioNuevo += (SELECT SUM(comp_componente)*prod_precio 
								 FROM Composicion 
								 JOIN Producto ON (comp_componente = prod_codigo) 
								 WHERE comp_producto = @Combo AND comp_componente = @Componente)
		END 
		FETCH NEXT FROM cursor_comp 
		INTO @Componente
	END

	CLOSE cursor_comp
	
	DEALLOCATE cursor_comp

	RETURN @PrecioNuevo

END






-- PRACTICAS DE TSQL
/*Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las ventas de unidades promedio 
de los últimos 3 meses anteriores a una fecha. 
Se solicita que se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado.
*/

CREATE TABLE PROD_A_REPONER (
PRODUCTO CHAR(8) PRIMARY KEY NOT NULL,
CANT_REPONER DECIMAL(12,2)
);

--calcular la cantidad de stock por producto a reponer

--como hacer eso: tomar la estimacion de las ventas de unidades promedio de los ultimos 3 meses anterior a una fecha

CREATE PROCEDURE stoc_reponer (@Fecha SMALLDATETIME)
AS
BEGIN
	INSERT INTO PROD_A_REPONER
	SELECT item_producto, SUM(item_cantidad)/3
	FROM Item_Factura
	JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
	WHERE MONTH(@Fecha) - MONTH(fact_fecha) <= 3
	GROUP BY item_producto
END
GO


/* Dada una tabla llamada TOP_Cliente, en la cual está el cliente que más unidades compro de todos los productos 
en todos los tiempos se le pide que implemente el/los objetos necesarios para que la misma esté siempre actualizada. 
La estructura de la tabla es TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos y 
cumplen con la condición.
*/

-- se guarda el cliente que mas unidades compro de todos los productos en todos los tiempos
CREATE TABLE TOP_CLIENTE(
ID_CLIENTE CHAR(8) PRIMARY KEY NOT NULL,
CANTIDAD_TOTAL_COMPRADA DECIMAL(12,2)
);

CREATE TRIGGER cliente_mas_compro ON Factura FOR INSERT,UPDATE
AS
BEGIN
	DECLARE @Cliente CHAR(8)
	DECLARE @CantComprada DECIMAL(12,2)
	DECLARE @CantTabla DECIMAL(12,2)

	SET @CantTabla = (SELECT MAX(CANTIDAD_TOTAL_COMPRADA) FROM TOP_CLIENTE)

	DECLARE cursor_clie CURSOR FOR (SELECT fact_cliente, SUM(item_cantidad) 
									FROM inserted 
									JOIN Item_Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero))

	OPEN cursor_clie 

	FETCH NEXT cursor_clie
	INTO @Cliente, @CantComprada

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@CantTabla < @CantComprada)
		BEGIN
			UPDATE TOP_CLIENTE SET
			ID_CLIENTE = @Cliente,
			CANTIDAD_TOTAL_COMPRADA = @CantComprada 
			WHERE CANTIDAD_TOTAL_COMPRADA = @CantTabla
		END

	END
END

/*T-SQL
Agregar el/los objetos necesarios para que se permita mantener la siguiente restricción:

Nunca un jefe va a poder tener más de 20 personas a cargo y menos de 1.

Nota: Considerar solo 1 nivel de la relación empleado-jefe.
*/

CREATE FUNCTION dbo.cant_empl_a_cargo (@Jefe NUMERIC(6))
RETURNS INT
AS 
BEGIN
	
	DECLARE @CantEmpleados INT


	IF NOT EXISTS(SELECT * FROM Empleado WHERE empl_jefe = @Jefe)
	BEGIN
		SET @CantEmpleados = 0
		RETURN @CantEmpleados
	END
	

	SET @CantEmpleados = @CantEmpleados + (SELECT SUM(empl_codigo) FROM Empleado WHERE empl_jefe = @Jefe)

	RETURN @CantEmpleados
END



CREATE TRIGGER jefes_que_cumplan ON Empleado AFTER INSERT, UPDATE
AS
BEGIN
	
	IF EXISTS(SELECT * FROM inserted WHERE dbo.cant_empl_a_cargo(empl_jefe) < 20  AND dbo.cant_empl_a_cargo(empl_jefe) < 1)
	BEGIN
		ROLLBACK TRANSACTION
	END
	
END


/*
Se necesita realizar una migración de los códigos de productos a una nueva codificación que va a ser
A + substring(prod_codigo,2,7). Implemente el/los objetos para llevar a cabo la migración.
Restricción a la solución: durante la migración no se podrá 
deshabilitar las contraints ni crear nuevas estructuras.
*/

--cada codigo de producto puede ser: prod_codigo, comp_producto y tambien en comp_componente, stoc_producto, item_producto


CREATE PROCEDURE migrar_cod_producto
AS
BEGIN
	
	--esta es una posible opcion para hacer en la tabla producto, lo que hace es que inserta los nuevos productos con la codificacion, y saca los viejos que no lo tienen
	INSERT INTO Producto
	SELECT 'A' + substring(p.prod_codigo,2,7),
			p.prod_detalle,
			p.prod_precio,
			p.prod_familia,
			p.prod_rubro,
			p.prod_envase
	FROM Producto p
	
	DELETE FROM Producto
	WHERE SUBSTRING(prod_codigo,1,1) <> 'A'

	UPDATE Composicion 
	SET comp_producto = 'A' + substring(comp_producto,2,7),
	comp_componente = 'A' + substring(comp_componente,2,7)

	UPDATE STOCK SET stoc_producto = 'A' + substring(stoc_producto,2,7)

	UPDATE Item_Factura SET item_producto = 'A' + substring(item_producto,2,7)

END


/* FOTO 2
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock suficiente del producto en el depósito 00.
NOTA: En caso de que se facturé un producto compuesto por ejemplo COMBO1 deberá controlar que exista stock en el depósito 00 de cada uno de sus componentes.
*/

--deposito '00'

CREATE TRIGGER fact_producto ON Item_Factura FOR INSERT
AS
BEGIN
	IF NOT EXISTS (SELECT * FROM inserted JOIN STOCK ON (item_producto = stoc_producto)
				   WHERE stoc_producto NOT IN (SELECT * FROM Composicion) AND stoc_deposito = '00'
				   GROUP BY stoc_producto
				   HAVING stoc_cantidad > 0)
	BEGIN
		ROLLBACK TRANSACTION
	END

	ELSE
	BEGIN
		IF EXISTS(SELECT * FROM inserted JOIN STOCK ON (item_producto = stoc_producto)
				   WHERE stoc_producto IN (SELECT * FROM Composicion) AND stoc_deposito = '00')
		BEGIN	
			
			DECLARE @Combo CHAR(8)

			DECLARE cursor_combo CURSOR FOR (SELECT * FROM Composicion JOIN STOCK ON (comp_producto = stoc_producto) WHERE stoc_deposito = '00')

			OPEN cursor_combo

			FETCH NEXT cursor_combo
			INTO @Combo

			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @Componente CHAR(8) 
				DECLARE cursor_comp CURSOR FOR (SELECT comp_componente 
												FROM Composicion 
												WHERE comp_producto = @Combo)

				OPEN cursor_comp

				FETCH NEXT cursor_comp
				INTO @Componente

				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF EXISTS(SELECT comp_componente FROM Composicion JOIN STOCK ON (comp_producto = stoc_producto) 
							  WHERE stoc_producto = @Combo AND comp_componente = @Componente AND stoc_cantidad < 0 )
					BEGIN
						ROLLBACK TRANSACTION
					END
				END
		END
	END
	
END
/*
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
*/


/*FOTO 5
Realizar un stored procedure que reciba un código de producto y una fecha y devuelva la mayor cantidad de día consecutivos a partir de esa fecha
que el producto tuvo al menos la venta de una unidad en el día, el sistemas de ventas on-line estará habilitado 24-7 por lo que se deben evaluar 
todos los días incluyendo domingos y feriados.
*/


CREATE PROCEDURE dias_vendidos (@Producto CHAR(8), @Fecha DATETIME)
AS
BEGIN
	
	--este es nuestro contador de dias
	DECLARE @DiasVendidos INT
	SET @DiasVendidos = 0

	--esta esta nuestra variable que devuelve los dias vendidos consecutivos
	DECLARE @MaxDiasVendidos INT
	SET @MaxDiasVendidos = 0 

	DECLARE @FechaAnterior DATETIME

	DECLARE @FechaVenta DATETIME

	--en el cursor vos ya le pones como condicion que se fije en los productos que tienen una venta como minimo en una factura
	--ya al asociar una factura con el item_factura, obligamos a que esa factura tenga al producto si o si
	DECLARE cursor_dias CURSOR FOR  SELECT fact_fecha 
									FROM Factura 
									JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
									WHERE item_producto = @Producto AND fact_fecha = @Fecha
									GROUP BY fact_fecha
									ORDER BY fact_fecha ASC

	OPEN cursor_dias 

	FETCH NEXT FROM cursor_dias
	INTO @FechaVenta

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@FechaVenta = DATEADD(DAY, 1, @FechaAnterior))
		BEGIN
			SET @DiasVendidos = @DiasVendidos + 1
		END
		ELSE
		BEGIN
		IF(@DiasVendidos > @MaxDiasVendidos)
		BEGIN
			SET @MaxDiasVendidos = @DiasVendidos
		END
			SET @DiasVendidos = 0
		END

		SET @FechaAnterior = @FechaVenta 
		FETCH NEXT FROM  cursor_dias
		INTO @FechaVenta
	END

	CLOSE cursor_dias

	DEALLOCATE cursor_dias


	RETURN @MaxDiasVendidos
END

/* FOTO 6 T-SQL
Realizar un stored procedure que dado un numero de factura,tipo y sucursal inserte un nuevo registro de item, actualicé los valores de totales de
factura más impuestos y reste el stock de ese producto en la tabla correspondiente. Se debe validar previamente la existencia del stock en ese 
depósito y en caso de no haber, no realizar nada.
Los parametros de entrada son datos de la factura,código del producto y cantidad.
Al total de factura se le suma lo correspondiente solo al nuevo item sin hacer recalculos, y en los impuestos se le suma 21% de dicho valor 
redondeado a dos decimales, se debe contemplar la posibilidad que esos dos campos esten en NULL al comienzo del procedure.
Se debe programar una transacción para que las tres operaciones se realicen atómicamente, se asume que todos los parámetros recibidos están 
validados a excepción de la cantidad de producto del stock.
Queda a criterio del alumno que acciones tomar en caso de que no se cumpla la única validación o no se produzca un error no provisto.
*/







