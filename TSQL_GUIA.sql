/*1. Hacer una funci�n que dado un art�culo y un deposito devuelva un string que
indique el estado del dep�sito seg�n el art�culo. Si la cantidad almacenada es
menor al l�mite retornar �OCUPACION DEL DEPOSITO XX %� siendo XX el
% de ocupaci�n. Si la cantidad almacenada es mayor o igual al l�mite retornar
�DEPOSITO COMPLETO�.*/

--pide una funcion
--Universo: Stock y Deposito
--tengo dos condiciones, uso if, si son mas ahi si implemento el case

CREATE FUNCTION dbo.ej_1 (@articulo varchar(8), @deposito char(2))
RETURNS varchar(50)
AS 
BEGIN
	DECLARE @cantidad_actual decimal(12,2)
	DECLARE @cantidad_max decimal(12,2)
	DECLARE @mensaje varchar(50)

	SELECT @cantidad_actual = stoc_cantidad, @cantidad_max = stoc_stock_maximo
	FROM STOCK
	WHERE stoc_producto = @articulo AND stoc_deposito = @deposito

	IF(@cantidad_actual >= @cantidad_max )
		SET @mensaje = 'DEPOSITO COMPLETO'
	ELSE
		SET @mensaje = 'OCUPACION DEL DEPOSITO' + str((@cantidad_actual / @cantidad_max) * 100) + '%' 
RETURN @mensaje
END

GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*2. Realizar una funci�n que dado un art�culo y una fecha, retorne el stock que
exist�a a esa fecha*/

--pide una funcion
--Universo: Producto, Factura, Stock

CREATE FUNCTION dbo.ejercicio2(@articulo varchar(8), @fecha smalldatetime)
RETURNS decimal(12,2)
AS
BEGIN 
	DECLARE @stock_actual decimal(12,2)
	DECLARE @movimientos_post_fecha decimal(12,2)


	(SELECT @stock_actual = SUM(stoc_cantidad)
	 FROM STOCK
	 WHERE stoc_producto = @articulo)
	 

	 SELECT @movimientos_post_fecha = SUM(item_cantidad)
	 FROM Item_Factura
		JOIN Factura ON (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal)
	 WHERE item_producto = @articulo AND fact_fecha > @fecha


RETURN @stock_actual + @movimientos_post_fecha
END


--FORMA EN LA QUE LO HIZO REINOSA
/*CREATE FUNCTION dbo.ejercicio_21(@producto varchar(8), @fecha smalldatetime)
RETURNS numeric(12,2)
AS
BEGIN
RETURN (SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @producto) + 
	   (SELECT SUM(item_cantidad) FROM Item_Factura JOIN Factura ON (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal) 
	   WHERE fact_fecha >= @fecha AND item_producto = @producto)
END	 */  
	   
	    
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que deber�a existir un �nico gerente general
(deber�a ser el �nico empleado sin jefe). Si detecta que hay m�s de un empleado
sin jefe deber� elegir entre ellos el gerente general, el cual ser� seleccionado por
mayor salario. Si hay m�s de uno se seleccionara el de mayor antig�edad en la
empresa. Al finalizar la ejecuci�n del objeto la tabla deber� cumplir con la regla
de un �nico empleado sin jefe (el gerente general) y deber� retornar la cantidad
de empleados que hab�a sin jefe antes de la ejecuci�n.*/

--Tipo de objeto que tenemos que crear: un procedure ya que hayq ue corregir la tabla empleado
--nos piden en un momento determinado, por eso no es un trigger

CREATE PROCEDURE ejercicio3
AS 
BEGIN

UPDATE Empleado SET empl_jefe =
	(SELECT TOP 1 empl_codigo 
	 FROM Empleado
	 WHERE empl_jefe IS NULL
	 ORDER BY empl_salario DESC, empl_ingreso)
	 WHERE empl_jefe IS NULL AND empl_codigo <> --condicion para hacer el update, NO SIEMPRE ES NECESARIO
	(SELECT TOP 1 empl_codigo FROM Empleado
	 WHERE empl_jefe IS NULL
	 ORDER BY empl_salario DESC, empl_ingreso)

RETURN
END	

GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*4. Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del �ltimo a�o. Se deber� retornar el c�digo del vendedor
que m�s vendi� (en monto) a lo largo del �ltimo a�o.*/

CREATE PROCEDURE ejercicio4 (@vendedor NUMERIC(12,2) OUTPUT)
AS
BEGIN
UPDATE empleado SET empl_comision =
	   (SELECT SUM(fact_total)
		FROM Factura 
		WHERE fact_vendedor = empl_codigo AND YEAR(fact_fecha) = (SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY fact_fecha DESC)) --esto es el ultimo a�o que se vendio

	   SET @vendedor =
	   (SELECT TOP 1 fact_vendedor 
	   FROM Factura 
	   WHERE YEAR(fact_fecha) = (SELECT TOP 1 YEAR(fact_fecha) FROM Factura ORDER BY fact_fecha DESC)
	   GROUP BY fact_vendedor
	   ORDER BY SUM(fact_total) DESC)

RETURN @vendedor
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definici�n:
Create table Fact_table
( anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)*/

Create table Fact_table
(
anio char(4) NOT NULL, --YEAR(fact_fecha)
mes char(2) NOT NULL, --RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2)
familia char(3) NOT NULL,--prod_familia
rubro char(4) NOT NULL,--prod_rubro
zona char(3) NOT NULL,--depa_zona
cliente char(6) NOT NULL,--fact_cliente
producto char(8) NOT NULL,--item_producto
cantidad decimal(12,2) NOT NULL,--item_cantidad
monto decimal(12,2)--asumo que es item_precio debido a que es por cada producto, 
				   --asumo tambien que el precio ya esta determinado por total y no por unidad (no debe multiplicarse por cantidad)
)
Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto)
GO

CREATE PROCEDURE Ejercicio5
AS
BEGIN
	INSERT INTO Fact_table
	SELECT YEAR(fact_fecha)
		,RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2)
		,prod_familia
		,prod_rubro
		,depa_zona
		,fact_cliente
		,prod_codigo
		,SUM(item_cantidad)
		,sum(item_precio)
	FROM Factura F
		JOIN Item_Factura IFACT ON IFACT.item_tipo =f.fact_tipo AND IFACT.item_sucursal = F.fact_sucursal AND IFACT.item_numero = F.fact_numero
		JOIN Producto P ON P.prod_codigo = IFACT.item_producto
		JOIN Empleado E ON E.empl_codigo = F.fact_vendedor
		JOIN Departamento D ON D.depa_codigo = E.empl_departamento
	GROUP BY YEAR(fact_fecha)
		,RIGHT('0' + convert(varchar(2),MONTH(fact_fecha)),2)
		,prod_familia
		,prod_rubro
		,depa_zona
		,fact_cliente
		,prod_codigo
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una l�nea por cada art�culo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vac�a.*/


CREATE TABLE Ventas(
vent_codigo char(8) NULL, --C�digo del articulo
vent_detalle char(50) NULL, --Detalle del articulo
vent_movimientos int NULL, --Cantidad de movimientos de ventas (Item Factura)
vent_precio_prom decimal(12,2) NULL, --Precio promedio de venta
vent_renglon int IDENTITY(1,1) PRIMARY KEY, --Nro de linea de la tabla (PK)
vent_ganancia char(6) NOT NULL, --Precio de venta - Cantidad * Costo Actual
)


CREATE PROCEDURE Ejercicio7 (@StartingDate date, @FinishingDate date)
AS 
BEGIN 
	
	DECLARE @Codigo char(8)
	DECLARE @Detalle char(50)
	DECLARE @Cant_Mov int
	DECLARE @Precio_de_venta decimal(12,2)
	DECLARE @Renglon int
	DECLARE @Ganancia decimal(12,2)
	DECLARE cursor_articulos CURSOR
	
	FOR (SELECT prod_codigo,
				prod_detalle,
				SUM(item_cantidad),
				AVG(item_precio),
				SUM(item_cantidad * item_precio)
				FROM Producto
					JOIN Item_Factura ON (prod_codigo = item_producto)
					JOIN Factura ON (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal)
				WHERE fact_fecha BETWEEN @StartingDate AND @FinishingDate
				GROUP BY prod_codigo, prod_detalle)
	
	OPEN cursor_articulos
	SET @Renglon = 0

	FETCH NEXT FROM cursor_articulos
	INTO @Codigo, @Detalle, @Cant_Mov, @Precio_de_venta, @Ganancia

	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO Ventas
		VALUES (@Codigo, @Detalle, @Cant_Mov, @Precio_de_venta, @Ganancia)
		
		FETCH NEXT FROM cursor_articulos
		INTO @Codigo, @Detalle, @Cant_Mov, @Precio_de_venta, @Ganancia

	END 
	CLOSE cursor_articulos
	DEALLOCATE cursor_articulos

END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composici�n y en los cuales el precio de
facturaci�n sea diferente al precio del c�lculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
tambi�n puede estar compuesto por otros y as� sucesivamente, la tabla se debe
crear y est� formada por las siguientes columnas:*/

CREATE TABLE Diferencias(
	dif_codigo char(8) NULL,
	dif_detalle char(50) NULL,
	dif_cantidad int NULL,
	dif_precio_generado decimal(12,2) NULL,
	dif_precio_facturado decimal(12,2) NULL
);

CREATE FUNCTION FN_CALCULAR_SUMA_COMPONENTES (@Producto char(8))
RETURNS decimal(12,2)
AS 
BEGIN
	DECLARE @total_suma int = 0
	DECLARE @prod_actual char(8)
	DECLARE @precio_actual decimal(12,2)

	DECLARE cr_componentes CURSOR FOR
	SELECT prod_codigo, prod_precio
	FROM Composicion
		JOIN Producto ON (prod_codigo = comp_componente)
	WHERE comp_producto = @Producto

	OPEN cr_componentes;

	FETCH NEXT FROM cr_componentes INTO @prod_actual, @precio_actual;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @prod_actual)
			SET @precio_actual = dbo.FN_CALCULAR_SUMA_COMPONENTES(@prod_actual)
	
		SET @total_suma = @total_suma + @precio_actual

	RETURN @total_suma
	END
	RETURN @total_suma
END


CREATE PROCEDURE sp_diferencias
AS
BEGIN
	INSERT INTO Diferencias (dif_codigo, dif_detalle, dif_cantidad, dif_precio_generado, dif_precio_facturado)
	SELECT prod_codigo, prod_detalle, COUNT(DISTINCT comp_componente), dbo.FN_CALCULAR_SUMA_COMPONENTES(prod_codigo), item_precio
	FROM Producto 
		JOIN Item_Factura ON (prod_codigo = item_producto)
		JOIN Composicion ON (prod_codigo = comp_producto)
	WHERE item_precio <> dbo.FN_CALCULAR_SUMA_COMPONENTES(prod_codigo)
	GROUP BY prod_codigo, prod_detalle, item_precio
END


/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*9. Crear el/los objetos de base de datos que ante alguna modificaci�n de un �tem de
factura de un art�culo con composici�n realice el movimiento de sus
correspondientes componentes.*/

--en los triggers, se puede volver todo atras con un rollup
--trigger after, before,se aplica cuando es una regla global(pasa esto o esto o vuelvo todo atras),
--trigger insteadof en lugar de lo que estas por hacer, hace lo que te voy a aclarar programando
--remplazamos la operacion del trigger con insteadof, miejntras que con los primeros desencadenamos lo que iba a hacer el trigger
--trigger update

CREATE TRIGGER TR_EJE_09_UPDATE ON Item_Factura
FOR UPDATE --nos dispara otra accion, en cambio instead of nos remplaza el trigger por otra operacion 
AS
BEGIN
	DECLARE @PROD_COD CHAR(8), @PROD_CANT_I DECIMAL(12,2), @PROD_CANT_D DECIMAL(12,2)
	DECLARE UPDATE_CURSOR CURSOR 
	FOR (SELECT I.item_producto, I.item_cantidad, D.item_cantidad FROM inserted I 
		JOIN deleted D ON I.item_tipo+I.item_sucursal+I.item_numero = D.item_tipo+D.item_sucursal+D.item_numero 
		AND I.item_producto = D.item_producto)
	OPEN UPDATE_CURSOR
	FETCH NEXT FROM UPDATE_CURSOR INTO @PROD_COD, @PROD_CANT_I, @PROD_CANT_D
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @PROD_COD)
		BEGIN
			UPDATE STOCK 
			SET stoc_cantidad = stoc_cantidad + (@PROD_CANT_D - @PROD_CANT_I)
			WHERE stoc_producto = @PROD_COD
			AND stoc_deposito = (SELECT TOP 1 S2.stoc_deposito FROM STOCK S2
								WHERE S2.stoc_producto = @PROD_COD AND S2.stoc_cantidad > 0
								ORDER BY S2.stoc_cantidad)
		END
		ELSE
		BEGIN
			UPDATE STOCK
			SET stoc_cantidad = stoc_cantidad + (@PROD_CANT_D - @PROD_CANT_I)*comp_cantidad
			FROM STOCK
			JOIN Composicion C ON C.comp_producto = @PROD_COD 
								AND C.comp_componente = stoc_producto
			WHERE stoc_deposito = (SELECT TOP 1 S2.stoc_deposito FROM STOCK S2
									WHERE S2.stoc_producto = C.comp_componente AND S2.stoc_cantidad > 0
									ORDER BY S2.stoc_cantidad)
		END
		FETCH NEXT FROM UPDATE_CURSOR INTO @PROD_COD, @PROD_CANT_I, @PROD_CANT_D
	END
	CLOSE UPDATE_CURSOR
	DEALLOCATE UPDATE_CURSOR
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*10. Crear el/los objetos de base de datos que ante el intento de borrar un art�culo
verifique que no exista stock y si es as� lo borre en caso contrario que emita un
mensaje de error.*/

CREATE TRIGGER ejercicio10 ON Producto INSTEAD of DELETE
AS
BEGIN
	IF(SELECT COUNT(*) FROM deleted JOIN STOCK ON prod_codigo = stoc_producto
	GROUP BY prod_codigo
	HAVING SUM(stoc_cantidad) > 0 ) > 0
		PRINT ('No se puede borrar porque tienen stock')
	ELSE 
		DELETE FROM Producto WHERE prod_codigo IN (SELECT prod_codigo FROM deleted)
END

--OTRA FORMA PERO CON CURSORES
/*
CREATE TRIGGER tr1 ON Producto INSTEAD OF delete
AS
BEGIN
	DECLARE @producto
	DECLARE c1 CURSOR FOR (SELECT prod_codigo FORM deleted)
	OPEN c1
	FETCH NEXT INTO @producto
	WHILE @@FETCH_STATUS == 0
	BEGIN
		IF(SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = @producto) > 0
			PRINT ('No se puede borrar' + @producto + 'porque tienen stock')
		ELSE 
			DELETE Producto WHERE prod_codigo = @producto
	FETCH NEXT INTO @producto
END*/


/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*11. Cree el/los objetos de base de datos necesarios para que dado un c�digo de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un c�digo mayor que su jefe directo.*/

-- tipo de objeto: Funcion
-- Universo: Empleado (empl_codigo)
-- Retornar: cantidad de empleados que el empleado tiene a su cargo (directa o indirectamente)
-- Cuales de esos filtrar: contar los empleados (directos o indirectos) que tengan codigo mayor que su jefe directo

CREATE FUNCTION ejercicio11 (@Jefe numeric(6,0))
RETURNS int
AS 
BEGIN 

	DECLARE @CantEmplACargo int = 0
	DECLARE @JefeAux numeric(6,0) = @Jefe
	DECLARE @CodJefeAux numeric(6,0)

	IF NOT EXISTS (SELECT * FROM Empleado WHERE empl_jefe = @Jefe)
	BEGIN 
		RETURN @CantEmplACargo
	END
	
	SET @CantEmplACargo = (SELECT COUNT(*) 
						   FROM Empleado
						   WHERE empl_jefe = @Jefe AND empl_codigo > @Jefe)

	DECLARE cursor_empleado CURSOR FOR (SELECT e.empl_codigo
										FROM Empleado e 
										WHERE e.empl_jefe = @Jefe)
	OPEN cursor_empleado
	FETCH NEXT from cursor_empleado --recorre las filas de la tabla
	INTO @JefeAux --y lo mete aca creo
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @CantEmplACargo = @CantEmplACargo + dbo.Ejercicio11(@JefeAux)	
		FETCH NEXT from cursor_empleado
		INTO @JefeAux
	END
	CLOSE cursor_empleado
	DEALLOCATE cursor_empleado

	RETURN @CantEmplACargo
		
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por s� mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnolog�as. No se conoce la cantidad de niveles de composici�n existentes.*/

-- Tipo objetos: Funcion y trigger
-- Universo: Producto y Componentes
-- Condicion: un producto no puede estar compuesto por si mismo

CREATE FUNCTION ejercicio12FUNC (@Componente char(8))
RETURNS BIT
AS
BEGIN
	DECLARE @ProdAux char(8)

	IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @Componente)
	BEGIN
		RETURN 1
	END

	DECLARE cursor_componente CURSOR FOR (SELECT c.comp_producto
										  FROM Composicion c
										  WHERE c.comp_componente = @Componente)
	OPEN cursor_componente
	FETCH NEXT FROM cursor_componente
	INTO @ProdAux
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		FETCH NEXT from cursor_componente
		INTO @ProdAux
	END
	CLOSE cursor_componente
	DEALLOCATE cursor_componente
	
	RETURN 0
END
GO
		
CREATE TRIGGER Ejercicio12TRIG ON COMPOSICION AFTER INSERT
AS
BEGIN
	IF EXISTS (SELECT comp_producto FROM inserted WHERE dbo.Ejercicio12Func(comp_producto) = 1)
		BEGIN
			PRINT 'Un producto no puede componerse a si mismo ni ser parte de un producto que se compone a si mismo'
			ROLLBACK TRANSACTION
			RETURN
		END
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
�Ning�n jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)�. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnolog�as*/

CREATE FUNCTION ejercicio13Func (@Jefe numeric(6,0))
RETURNS decimal(12,2)
AS 
BEGIN 
	DECLARE @SueldoEmpl decimal(12,2)

	IF NOT EXISTS (SELECT * FROM Empleado WHERE empl_jefe = @Jefe)
	BEGIN
			SET @SueldoEmpl = 0
			RETURN @SueldoEmpl
	END
	SET @SueldoEmpl = @SueldoEmpl + (SELECT SUM(dbo.Ejercicio13Func(empl_codigo))
									 FROM Empleado
									 WHERE empl_jefe = @Jefe)
	RETURN @SueldoEmpl
END 
GO

CREATE TRIGGER Ejercicio13 ON Empleado FOR INSERT, UPDATE
AS 
BEGIN
	IF EXISTS (SELECT * FROM inserted i WHERE dbo.Ejercicio13Func(i.empl_jefe) * 0.2 > i.empl_salario)
	BEGIN 
		ROLLBACK
	END
END

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qu� precio se realiz� la
compra. No se deber� permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/

-- Objetos: funcion y trigger
-- La funcion tiene que imprimir fecha, que cliente, que productos y precio que se realizo
-- Condicion para la funcion: no permitir que el precio  sea menor a la mitad de la suma de los componentes
-- El trigger hace que el proceso se haga de forma automatica

CREATE FUNCTION EsProductoCompuesto(@producto char(8))
RETURNS BIT
AS
BEGIN
	DECLARE @esProductoCompuesto BIT = 0
	IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
		BEGIN
			SET @esProductoCompuesto = 1
		END
	RETURN @esProductoCompuesto
END

CREATE FUNCTION precioCompuesto (@producto char(8))
RETURNS decimal(12,2)
AS
BEGIN
	DECLARE @precioCompuesto decimal(12,2) = 0
	DECLARE @componenteCompuesto char(8)
	DECLARE @cantidad decimal(12,2)

	IF (dbo.EsProductoCompuesto(@producto) = 1)
		DECLARE cursor_compuesto CURSOR FOR (SELECT comp_componente, comp_cantidad
											FROM Composicion
											WHERE comp_producto = @producto)
		OPEN cursor_compuesto
		FETCH NEXT FROM cursor_compuesto
		INTO @componenteCompuesto,@cantidad
		WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @precioCompuesto = @precioCompuesto + @cantidad * (
																		SELECT prod_precio
																		FROM Producto
																		WHERE prod_codigo = @componenteCompuesto)
				FETCH NEXT FROM cursor_compuesto
				INTO @componenteCompuesto,@cantidad
			END
		CLOSE cursor_compuesto
		DEALLOCATE cursor_compuesto
		RETURN @precioCompuesto

END
GO

CREATE TRIGGER ejercicio14 ON item_factura FOR INSERT, UPDATE
AS
BEGIN
	declare @tipo char(1)
	declare @sucursal char(4)
	declare @numero char(8)
	declare @prodAInsertar char(8)
	declare @precio decimal(12,2)
	declare @fecha SMALLDATETIME
	declare @cliente char(6)
	
	DECLARE cursor_compra CURSOR FOR (SELECT item_tipo,item_sucursal,item_numero,item_producto,item_precio
									  FROM inserted)
	OPEN cursor_compra
	FETCH NEXT FROM cursor_compra
	INTO @tipo,@sucursal,@numero,@prodAInsertar,@precio
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @cliente = (
						SELECT fact_cliente
						FROM Factura
						WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
						)
		SET @fecha = (
						SELECT fact_fecha
						FROM Factura
						WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
						)
		IF dbo.EsProductoCompuesto(@prodAInsertar) = 1
			BEGIN
				IF @precio > dbo.precioCompuesto(@prodAInsertar)/2
				BEGIN
					INSERT INTO Item_Factura
						SELECT *
						FROM inserted
						where item_producto = @prodAInsertar
					
					PRINT @fecha
					PRINT @cliente
				END
			ELSE
				PRINT 'El precio producto no puede ser menor a la mitad de la suma de sus productos compuestos'
			END
		FETCH NEXT FROM cursor_compra
		INTO @tipo,@sucursal,@numero,@prodAInsertar,@precio
		END
	END
	GO
/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.*/
create function ej15 (@producto char(8))
returns decimal(12,2)
as 
begin
	DECLARE @precioProducto decimal(12,2)
	set @precioProducto = 0
	if not exists (select * from Composicion where comp_producto = @producto)
		set @precioProducto = (select prod_precio from Producto where prod_codigo = @producto)
	else
		BEGIN
			declare productosComponentes cursor for (select comp_componente, comp_cantidad from Composicion where comp_producto = @producto)
			declare @componente char(8)
			declare @cantComponente decimal(12,2)
			open productosComponentes
			fetch next from productosComponentes into @componente, @cantComponente
				while @@FETCH_STATUS = 0
					begin
						set @precioProducto = @precioProducto + (dbo.ej15(@componente) * @cantComponente)
						fetch next from productosComponentes into @componente, @cantComponente
					end
			close productosComponentes
		END
	return @precioProducto
end

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.*/

-- trigger porque dice que tiene que ser automatica
-- reutilizamos la funcion del ejercicio 14

CREATE TRIGGER Ejercicio16 ON item_factura FOR INSERT
AS
BEGIN
	DECLARE @prod char(8), @cant decimal(12,2), @comp char(8), @cantComp decimal(12,2), @depo char(2)
	DECLARE cursor_update CURSOR FOR SELECT I.item_producto
											,SUM(I.item_cantidad - D.item_cantidad) 
									FROM inserted I join deleted D 
										on I.item_tipo+I.item_sucursal+I.item_numero = D.item_tipo+D.item_sucursal+D.item_numero
											AND I.item_producto = D.item_producto
									WHERE I.item_cantidad <> D.item_cantidad
									GROUP BY I.item_producto
	OPEN cursor_update
	FETCH NEXT FROM cursor_update 
	INTO @prod,@cant
	WHILE @@FETCH_STATUS = 0
		IF (dbo.EsProductoCompuesto(@prod)) = 1
			BEGIN
				DECLARE cursor_comp CURSOR FOR SELECT comp_componente,comp_cantidad
											FROM Composicion
											WHERE comp_producto = @prod
				OPEN cursor_comp
				FETCH NEXT FROM cursor_comp
				INTO @comp,@cantComp
				WHILE @@FETCH_STATUS = 0
				BEGIN 
					DECLARE @depo decimal(12,2)
					DECLARE @cantidadDepo decimal (12,2)
					DECLARE @cantidadADescontar decimal (12,2) = @cantComp * @cant
					DECLARE cursor_stock CURSOR FOR SELECT stoc_deposito,stoc_cantidad
													FROM STOCK
													WHERE stoc_producto = @prod
													ORDER BY stoc_cantidad DESC
					OPEN cursor_stock
					FETCH NEXT FROM cursor_stock
					INTO @depo,@cantidadDepo
					WHILE @cantidadADescontar <> 0 OR @@FETCH_STATUS = 0
					BEGIN
						IF @cantidadDepo >= @cantidadADescontar * @cant
						BEGIN
							UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidadADescontar
							WHERE stoc_deposito = @depo
							SET @cantidadADescontar = 0
						END
						IF @cantidadDepo < @cantidadADescontar
						BEGIN
							SET @cantidadADescontar -= @cantidadDepo
							UPDATE STOCK SET stoc_cantidad = 0
							WHERE stoc_deposito = @depo
						END
					FETCH NEXT FROM cursor_stock
					INTO @depo,@cantidadDepo
					END
					CLOSE cursor_stock
					DEALLOCATE cursor_stock
				FETCH NEXT FROM cursor_comp
				INTO @comp,@cantComp
				END
				CLOSE cursor_comp
				DEALLOCATE cursor_comp
			END
		ELSE
			BEGIN
				DECLARE @cantidadADescontarSimple decimal (12,2) = @cant
				DECLARE cursor_stock CURSOR FOR SELECT stoc_deposito,stoc_cantidad
												FROM STOCK
												WHERE stoc_producto = @prod
												ORDER BY stoc_cantidad DESC
				OPEN cursor_stock
				FETCH NEXT FROM cursor_stock
				INTO @depo,@cantidadDepo
				WHILE @cantidadADescontar <> 0 OR @@FETCH_STATUS = 0
				BEGIN
					IF @cantidadDepo >= @cant
					BEGIN
						UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidadADescontarSimple
						WHERE stoc_deposito = @depo
						SET @cantidadADescontarSimple = 0
					END
					IF @cantidadDepo < @cantidadADescontarSimple
					BEGIN
						SET @cantidadADescontarSimple -= @cantidadDepo
						UPDATE STOCK SET stoc_cantidad = 0
						WHERE stoc_deposito = @depo
					END
				FETCH NEXT FROM cursor_stock
				INTO @depo,@cantidadDepo
				END
				CLOSE cursor_stock
				DEALLOCATE cursor_stock

			END
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock*/

--cuando dice que la regla se cumpla de forma automatica es un trigger
--el trigger se hace desde el select siempre, que es el que filtra todos los datos que cumplen o no

CREATE TRIGGER ejercicio17 ON STOCK FOR insert, UPDATE
AS 
BEGIN
	IF EXISTS (SELECT * FROM inserted
			   WHERE stoc_cantidad > stoc_stock_maximo OR stoc_cantidad < stoc_punto_reposicion)
		BEGIN
			PRINT('el producto no cumple el minimo y maximo')
			ROLLBACK
		END

END

--otra opcion con cursor, pero esta esta medio mal y no la recomienda
create trigger ej17 ON STOCK FOR insert, UPDATE
AS
BEGIN
	IF (SELECT COUNT(*) FROM deleted) = 0
		BEGIN 
			insert STOCK SELECT * FROM inserted WHERE stoc_cantidad > stoc_punto_reposicion AND stoc_cantidad < stoc_stock_maximo
		END
	ELSE
		BEGIN
			DECLARE c1 CURSOR FOR SELECT * FROM inserted WHERE stoc_cantidad > stoc_punto_reposicion AND stoc_cantidad < stoc_stock_maximo
			DECLARE --falta declarar los @ que estan abajo

			FETCH NEXT INTO c1
			WHILE @@FETCH_STATUS = 0
			BEGIN 
				UPDATE STOCK SET stoc_cantidad = @cantidad, stoc_detalle = @detalle,
				WHERE stoc_deposito =  @deposito AND stoc_producto = @producto

			END

END


/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas*/

CREATE TRIGGER ejercicio18 ON Factura FOR insert
AS
BEGIN
	IF EXISTS (SELECT i.fact_cliente,YEAR(i.fact_fecha), MONTH(i.fact_fecha), SUM(i.fact_total) FROM inserted i JOIN Cliente ON (clie_codigo = i.fact_cliente)
	GROUP BY fact_cliente,YEAR(i.fact_fecha), MONTH(i.fact_fecha)
	HAVING SUM(i.fact_total) + 
           (SELECT SUM(fact_total) 
		    FROM Factura 
			WHERE YEAR(fact_fecha) = YEAR(i.fact_fecha)
				  AND MONTH(fact_fecha) = MONTH(i.fact_fecha)
				  AND fact_cliente = i.fact_cliente) > clie_limite_credito)
	BEGIN 
		ROLLBACK
	END


END

--trigger 

--con instead of, solo permite ingresar los que estan bien
CREATE TRIGGER ejercicio18_V2 ON Factura INSTEAD OF insert
AS

BEGIN
	
	INSERT Factura (SELECT * FROM inserted WHERE fact_cliente IN
	(SELECT i.fact_cliente FROM inserted i JOIN Cliente ON (clie_codigo = i.fact_cliente)
	GROUP BY fact_cliente,YEAR(i.fact_fecha), MONTH(i.fact_fecha)
	HAVING SUM(i.fact_total) + 
           (SELECT SUM(fact_total) 
		    FROM Factura 
			WHERE YEAR(fact_fecha) = YEAR(i.fact_fecha)
				  AND MONTH(fact_fecha) = MONTH(i.fact_fecha)
				  AND fact_cliente = i.fact_cliente) <= clie_limite_credito)) --devuelve los que estan bien
	BEGIN 
		ROLLBACK
	END


END

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio autom�ticamente �Ning�n jefe puede tener menos de 5 a�os de
antig�edad y tampoco puede tener m�s del 50% del personal a su cargo
(contando directos e indirectos) a excepci�n del gerente general�. Se sabe que en
la actualidad la regla se cumple y existe un �nico gerente general.*/

CREATE TRIGGER dbo.ejercicio19 ON Empleado FOR INSERT,UPDATE
AS
BEGIN
	DECLARE @emplCod numeric (6,0),@emplJefe numeric (6,0)
	DECLARE cursor_inserted CURSOR FOR SELECT empl_codigo,empl_jefe
										FROM inserted
	OPEN cursor_inserted
	FETCH NEXT FROM cursor_inserted
	INTO @emplCod,@emplJefe
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF dbo.calculoDeAntiguedad(@emplCod) < 5
		BEGIN
			PRINT 'El empleado no puede tener menos de 5 a�os de antiguedad'
			ROLLBACK
		END

		ELSE IF dbo.cantidadDeSubordinados(@emplCod) > (
															SELECT COUNT(*)*0.5
															FROM Empleado
															)
				AND @emplJefe <> NULL
		BEGIN
			PRINT 'El empleado no puede tener mas del 50% del personal a su cargo'
			ROLLBACK
		END
	FETCH NEXT FROM cursor_inserted
	INTO @emplCod,@emplJefe
	END
	CLOSE cursor_inserted
	DEALLOCATE cursor_inserted
END
GO


ALTER FUNCTION dbo.calculoDeAntiguedad (@empleado numeric(6,0))
RETURNS int
AS
BEGIN
	DECLARE @todaysDate smalldatetime = GETDATE()
	DECLARE @antiguedad int = 0
	SET @antiguedad = DATEDIFF(year,(SELECT empl_ingreso
										FROM Empleado
										WHERE @empleado = empl_codigo
										),@todaysDate
								)
	RETURN @antiguedad
END
GO

CREATE FUNCTION dbo.cantidadDeSubordinados (@Jefe numeric(6,0))
RETURNS int

AS
BEGIN
	DECLARE @CantEmplACargo int = 0
	DECLARE @JefeAux numeric(6,0) = @Jefe
	DECLARE @CodEmplAux numeric(6,0)
	

	IF NOT EXISTS (SELECT * FROM EMPLEADO WHERE empl_jefe = @Jefe)
	BEGIN
		RETURN @CantEmplACargo
	END

	SET @CantEmplACargo = (
							SELECT COUNT(*)
							FROM Empleado
							WHERE empl_jefe = @Jefe AND empl_codigo > @Jefe)

	DECLARE cursor_empleado CURSOR FOR SELECT E.empl_codigo
										FROM Empleado E
										WHERE empl_jefe = @Jefe
	OPEN cursor_empleado
	FETCH NEXT from cursor_empleado
	INTO @JefeAux
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @CantEmplACargo = @CantEmplACargo + dbo.cantidadDeSubordinados(@JefeAux)
			
	FETCH NEXT from cursor_empleado
	INTO @JefeAux
	END
	CLOSE cursor_empleado
	DEALLOCATE cursor_empleado

	RETURN @CantEmplACargo
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El c�lculo de la comisi�n est� dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, m�s un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.*/

--objeto: trigger

CREATE TRIGGER dbo.Ejercicio21 ON Factura FOR INSERT
AS
BEGIN
	DECLARE @fecha smalldatetime
			,@vendedor numeric(6,0)
	DECLARE @comision decimal (12,2)
	DECLARE cursor_fact CURSOR FOR SELECT fact_fecha,fact_vendedor
									FROM inserted
	OPEN cursor_fact
	FETCH NEXT FROM cursor_fact
	INTO @fecha,@vendedor
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @comision = (
							SELECT SUM(item_precio*item_cantidad)*(0.05 +
																			CASE WHEN COUNT(DISTINCT item_producto) > 50 THEN 0.03
																				ELSE 0
																				END
																				)
							FROM Factura
								INNER JOIN Item_Factura
									ON item_tipo = fact_tipo AND item_sucursal = fact_sucursal AND item_numero = fact_numero
							WHERE fact_vendedor = @vendedor
								AND YEAR(fact_fecha) = YEAR(@fecha)
								AND MONTH(fact_fecha) = MONTH(@fecha)
							)
		UPDATE Empleado SET empl_comision = @comision WHERE empl_codigo = @vendedor
		FETCH NEXT FROM cursor_fact
		INTO @fecha,@vendedor
	END
	CLOSE cursor_fact
	DEALLOCATE cursor_fact
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.*/

CREATE TRIGGER ej21 ON FACTURA FOR INSERT

AS

BEGIN
       IF exists(SELECT fact_numero+fact_sucursal+fact_tipo 
				 FROM inserted 
					INNER JOIN Item_Factura
						ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
					INNER JOIN Producto 
						ON prod_codigo = item_producto JOIN Familia ON fami_id = prod_familia
                     GROUP BY fact_numero+fact_sucursal+fact_tipo
                     HAVING COUNT(distinct fami_id) <> 1 )
              BEGIN
              DECLARE @NUMERO char(8),@SUCURSAL char(4),@TIPO char(1)
              DECLARE cursorFacturas CURSOR FOR SELECT fact_numero,fact_sucursal,fact_tipo FROM inserted
              OPEN cursorFacturas
              FETCH NEXT FROM cursorFacturas INTO @NUMERO,@SUCURSAL,@TIPO
              WHILE @@FETCH_STATUS = 0
              BEGIN
                     DELETE FROM Item_Factura WHERE item_numero+item_sucursal+item_tipo = @NUMERO+@SUCURSAL+@TIPO
                     DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @NUMERO+@SUCURSAL+@TIPO
                     FETCH NEXT FROM cursorFacturas INTO @NUMERO,@SUCURSAL,@TIPO
              END
              CLOSE cursorFacturas
              DEALLOCATE cursorFacturas
              RAISERROR ('no puede ingresar productos de mas de una familia en una misma factura.',1,1)
              ROLLBACK
       END
END

/*------------------------------------------------------------------------------------------------------------------------------------------*/
/*22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.*/

CREATE PROC dbo.Ejercicio22
AS
BEGIN
	declare @rubro char(4)
	declare @cantProdRubro int

	declare cursor_rubro CURSOR FOR SELECT R.rubr_id,COUNT(*)
									FROM rubro R
										INNER JOIN Producto P
											ON P.prod_rubro = R.rubr_id
									GROUP BY R.rubr_id
									HAVING COUNT(*) > 20
	OPEN cursor_rubro
	FETCH NEXT FROM cursor_rubro
	INTO @rubro,@cantProdRubro
	WHILE @@FETCH_STATUS = 0
	BEGIN
		declare @cantProdRubroIndividual int = @cantProdRubro
		declare @prodCod char(8)
		declare @rubroLibre char(4)
		declare cursor_productos CURSOR FOR SELECT prod_codigo
											FROM Producto
											WHERE prod_rubro = @rubro
		OPEN cursor_productos
		FETCH NEXT FROM cursor_productos
		INTO @prodCod
		WHILE @@FETCH_STATUS = 0 OR @cantProdRubroIndividual < 21
		BEGIN
			IF EXISTS(
						SELECT TOP 1 rubr_id
						FROM Rubro
							INNER JOIN Producto
								ON prod_rubro = rubr_id
						GROUP BY rubr_id
						HAVING COUNT(*) < 20
						ORDER BY COUNT(*) ASC
						)
			BEGIN
				SET @rubroLibre = (
									SELECT TOP 1 rubr_id
									FROM Rubro
										INNER JOIN Producto
											ON prod_rubro = rubr_id
									GROUP BY rubr_id
									HAVING COUNT(*) < 20
									ORDER BY COUNT(*) ASC
									)

				UPDATE Producto SET prod_rubro = @rubroLibre WHERE prod_codigo = @prodCod
			END
			ELSE
			BEGIN
				IF NOT EXISTS(
						SELECT rubr_id
						FROM Rubro
						WHERE rubr_detalle = 'Rubro reasignado'
						)  
				INSERT INTO Rubro (RUBR_ID,rubr_detalle) VALUES ('xx','Rubro reasignado')
				UPDATE Producto set prod_rubro = (
													SELECT rubr_id
													FROM Rubro
													WHERE rubr_detalle = 'Rubro reasignado'
												)
				WHERE prod_codigo = @prodCod
			END
			SET @cantProdRubroIndividual -= 1
		FETCH NEXT FROM cursor_productos
		INTO @prodCod
		END
		CLOSE cursor_productos
		DEALLOCATE cursor_productos
	FETCH NEXT FROM cursor_rubro
	INTO @rubro,@cantProdRubro
	END
	CLOSE cursor_rubro
	DEALLOCATE cursor_productos
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.*/


CREATE TRIGGER dbo.Ejercicio23 ON item_factura FOR INSERT
AS
BEGIN
	DECLARE @tipo char(1)
	DECLARE @sucursal char(4)
	DECLARE @numero char(8)
	DECLARE @producto char(8)
	DECLARE cursor_ifact CURSOR FOR SELECT item_tipo,item_sucursal,item_numero,item_producto
									FROM inserted

	OPEN cursor_ifact
	FETCH NEXT FROM cursor_ifact
	INTO @tipo,@sucursal,@numero,@producto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(
			SELECT COUNT(*)
			FROM inserted
			WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
				AND item_producto IN (
								SELECT comp_producto
								FROM Composicion
								)
			) >= 2
		BEGIN
		DELETE FROM Item_factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
		DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
		RAISERROR('En una misma factura no pueden venderse mas de dos productos con composicion',1,1)
		ROLLBACK TRANSACTION
		END
	FETCH NEXT FROM cursor_ifact
	INTO @tipo,@sucursal,@numero,@producto
	CLOSE cursor_ifact
	DEALLOCATE cursor_ifact
END
CLOSE

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.*/

CREATE PROC dbo.ejercicio24
AS
BEGIN
	
	declare @depoCodigo char(2)
	declare @depoEncargado numeric(6,0)
	declare @nuevoDepoEncargado numeric(6,0)
	declare @depoZona char(3)
	declare cursor_zona CURSOR FOR SELECT depo_codigo,depo_encargado,depo_zona
									FROM DEPOSITO
	
	OPEN cursor_zona
	FETCH NEXT FROM cursor_zona
	INTO @depoCodigo,@depoEncargado,@depoZona
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@depoZona <> (
							SELECT depa_zona
							FROM Departamento
								INNER JOIN Empleado
									ON empl_departamento = depa_codigo
							WHERE empl_codigo = @depoEncargado
							)
		BEGIN
			SET @nuevoDepoEncargado = (
										SELECT TOP 1 empl_codigo
										FROM Empleado
											INNER JOIN DEPOSITO
												ON depo_encargado = empl_codigo
											INNER JOIN Departamento
												ON depa_codigo = empl_departamento
										WHERE depa_zona = @depoZona
										GROUP BY empl_codigo
										ORDER BY COUNT(*) ASC
										)
			UPDATE DEPOSITO SET depo_encargado = @nuevoDepoEncargado WHERE depo_codigo = @depoCodigo
		END
	FETCH NEXT FROM cursor_zona
	INTO @depoCodigo,@depoEncargado,@depoZona
	END
	CLOSE cursor_zona
	DEALLOCATE cursor_zona
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.*/

--Tipo de objetos: trigger (FOR INSERT, UPDATE) con cursores, sin necesidad de una funcion
--FOR or AFTER:
--specifies that the DML trigger fires only when all operations specified in the triggering SQL statement have launched successfully. All referential cascade actions and constraint checks must also succeed before this trigger fires.

CREATE TRIGGER dbo.ejercicio25 ON Composicion FOR INSERT,UPDATE
AS
BEGIN
	--declaro estos dos varibles para que despues con el cursor pueda ir recorriendo y viendo que se cumpla la cosniga
	DECLARE @producto CHAR(8)
	DECLARE @componente CHAR(8)
	
	--usamos un cursor para recorrer todos los productos con componentes que son muchos

	DECLARE cursor_comp CURSOR FOR (SELECT comp_producto, comp_componente FROM inserted)

	OPEN cursor_comp

	FETCH NEXT FROM cursor_comp
	INTO @producto, @componente

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT * FROM Composicion
				   WHERE comp_producto = @producto AND comp_componente = @componente)
			BEGIN
				RAISERROR ('El producto %s ya compone al producto %s, por lo tanto no es posible insertar',1,1,@componente,@producto)
				ROLLBACK TRANSACTION
			END 
	FETCH NEXT FROM cursor_comp
	INTO @producto, @componente
	END

	CLOSE cursor_comp
	DEALLOCATE cursor_comp
END 
GO


/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/

--Tipo de objetos: trigger
--cosas que se deben cumplir: join fact con item,

CREATE TRIGGER dbo.ejercicio26 ON Item_Factura FOR INSERT
AS
BEGIN
	--declaro la factura con sus tres PK 
	DECLARE @item CHAR(1)
	DECLARE @sucursal CHAR(4)
	DECLARE @numero CHAR(8)   
	DECLARE @producto CHAR(8)

	DECLARE cursor_fact CURSOR FOR (SELECT item_tipo, item_sucursal, item_numero, item_producto FROM inserted)

	OPEN cursor_fact

	FETCH NEXT FROM cursor_fact
	INTO @item, @sucursal, @numero, @producto
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT * FROM Composicion
				   WHERE comp_producto = @producto)
		   BEGIN
				--accion que se lleva a cabo cuando nos pide que no se grabe la factura, la borramos
				DELETE FROM Factura 
				WHERE fact_tipo + fact_sucursal + fact_numero = @item + @sucursal + @numero

				DELETE FROM Item_Factura 
				WHERE item_tipo + item_sucursal + item_numero = @item + @sucursal + @numero

				RAISERROR('EL producto a insertar es componente de otro producto, no se puede insertar en la factura',1,1)
				ROLLBACK TRANSACTION
		   END
	FETCH NEXT FROM cursor_fact
	INTO @item, @sucursal, @numero, @producto
	END

	CLOSE cursor_fact
	DEALLOCATE cursor_fact
END
GO


/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*27. Se requiere reasignar los encargados de stock de los diferentes depósitos. 
Para ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.*/

--tipo de objeto: store procedure
--Posible universo: Depositos
--Nos piden asigar a cada deposito asignar el encargado que le corresponde 
-- este encargado es cualq empeado que no es jefe y que no es vendedor, NO ESTA ASIGNADO A NINGUN CLIENTE 
--en caso de que no se pueda se iran aumentando la cantidad de depositos (PROGRESIVAMENTE) para cada empleado

CREATE PROCEDURE dbo.ejercicio27
AS
BEGIN 
	DECLARE @DepoCod CHAR(2)
	
	
	DECLARE cursor_depo CURSOR FOR (SELECT depo_codigo FROM DEPOSITO)

	OPEN cursor_depo

	FETCH NEXT FROM cursor_depo
	INTO @DepoCod
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--le damos el nuevo encargado a cada deposito filtrando lo que nos pide la consiga
		UPDATE DEPOSITO SET depo_encargado = (SELECT TOP 1 empl_codigo
											  FROM Empleado
												JOIN DEPOSITO on (empl_codigo = depo_encargado)
											  WHERE empl_codigo NOT IN (SELECT empl_jefe
																		FROM Empleado
																		WHERE empl_jefe IS NOT NULL)
													AND empl_codigo NOT IN (SELECT clie_vendedor 
																			FROM Cliente
																			WHERE clie_vendedor IS NOT NULL)
											  GROUP BY empl_codigo
											  ORDER BY COUNT(*) ASC)
											  WHERE depo_codigo = @DepoCod
	FETCH NEXT FROM cursor_depo
	INTO @DepoCod
	END

	CLOSE cursor_depo

	DEALLOCATE cursor_depo
END
GO

--Falta otro cursor para que cargue bien los empleados, porque con unico update que hay no lo hace bien

CREATE PROC EJ27
AS 
BEGIN 
 DECLARE @DEPOSITO char(2), @EMPLEADO numeric(6)
 DECLARE cursorempleados CURSOR FOR (SELECT E.empl_codigo FROM Empleado E WHERE empl_codigo NOT IN (SELECT fact_vendedor FROM Factura) 
   AND empl_codigo NOT IN (SELECT empl_jefe FROM Empleado)) 
 DECLARE cursorDepositos CURSOR FOR SELECT depo_codigo FROM DEPOSITO
 OPEN cursorempleados
 FETCH NEXT FROM cursorempleados INTO @EMPLEADO
 OPEN cursorDepositos 
 FETCH NEXT FROM cursorDepositos INTO @DEPOSITO
 WHILE @@FETCH_STATUS = 0
 BEGIN 
  UPDATE DEPOSITO SET depo_encargado = @EMPLEADO WHERE depo_codigo = @DEPOSITO
  FETCH NEXT FROM cursorempleados INTO @EMPLEADO
  IF @@FETCH_STATUS <> 0
   BEGIN
    CLOSE cursorempleados
    OPEN cursorempleados
   END
  FETCH NEXT FROM cursorDepositos INTO @DEPOSITO
 END
 CLOSE cursorDepositos
 DEALLOCATE cursorDepositos
 CLOSE cursorempleados
 DEALLOCATE cursorempleados
END


/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*28. Se requiere reasignar los vendedores a los clientes. Para ello se solicita que
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendió más facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deberá asignar el vendedor con más
venta de la empresa, o sea, el que en monto haya vendido más.*/


--estamos hablando de reasignar, entonces mi tipo de objeto puede ser un store procedure 

--asignar a cada cliente el vendedor que le corresponda
--entemos como el vendedor que le corresponde como el que le vendio mas facturas a ese cliente
--si un cliente no tiene facturas entonces le asignamos el vendedor con mas ventas de la empresa, es decir el que tiene mayor monto vendido

CREATE PROCEDURE dbo.ejercicio28
AS
BEGIN
	
	DECLARE @clieCodigo CHAR(5)
	DECLARE @clieVendedor NUMERIC(6,0)

	DECLARE cursor_cliente CURSOR FOR (SELECT clie_codigo FROM Cliente)

	OPEN cursor_cliente

	FETCH NEXT FROM cursor_cliente
	INTO @clieCodigo

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT * FROM Factura WHERE fact_cliente = @clieCodigo)
		BEGIN
			SET @clieVendedor = (SELECT TOP 1 fact_vendedor
								 FROM Factura
								 WHERE fact_cliente = @clieCodigo
								 GROUP BY fact_cliente,fact_vendedor
								 ORDER BY COUNT(fact_vendedor) DESC)
			UPDATE Cliente SET clie_vendedor = @clieVendedor WHERE clie_codigo = @clieCodigo
		END
		ELSE
		BEGIN
			SET @clieVendedor = (SELECT TOP 1 fact_vendedor
								 FROM Factura
								 GROUP BY fact_vendedor
								 ORDER BY COUNT(*) DESC)
			UPDATE Cliente SET clie_vendedor = @clieVendedor WHERE clie_codigo = @clieCodigo
		END

	FETCH NEXT FROM cursor_cliente
	INTO @clieCodigo
	END
	
	CLOSE cursor_cliente

	DEALLOCATE cursor_cliente
		
END
GO

/*------------------------------------------------------------------------------------------------------------------------------------------*/


/*29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar m�s de 100 unidades en el mes de ning�n producto, si esto
ocurre no se deber� ingresar la operaci�n y se deber� emitir un mensaje �Se ha
superado el l�mite m�ximo de compra de un producto�. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.*/


--cuando haces for, si o si tiene que ser rollback

--este lo hizo el profesor pero no esta completo
CREATE TRIGGER ejercicio30 ON Item_Factura FOR insert
AS
BEGIN
IF EXISTS (SELECT f.fact_cliente, i.item_producto, SUM(i.item_cantidad) 
	FROM inserted i
		JOIN Factura f on (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal)
	GROUP BY i.item_producto, f.fact_cliente
	HAVING (SUM(i.item_cantidad) + (SELECT SUM(item_cantidad) 
									FROM Item_Factura
										JOIN Factura ON (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal)
									WHERE item_producto = i.item_producto AND fact_cliente = f.fact_cliente) > 100))
	
	BEGIN
	DELETE Item_Factura WHERE item_tipo + item_sucursal + item_numero IN (SELECT  f.fact_tipo + f.fact_sucursal + f.fact_numero 
																		  FROM inserted i JOIN Factura f ON
																		  GROUP BY i.item_producto, f.fact_cliente, YEAR(f.fact_fecha), MONTH(f.fact_fecha)
																		  HAVING (SUM(i.item_cantidad) +  (SELECT SUM(item_cantidad) FROM item_factura JOIN Factura ON (item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal) ) )
																					) 
	ROLLBACK

	END

END

--este es el que esta resuelto en el drive
CREATE TRIGGER Ejercicio30 ON item_factura FOR INSERT
AS
BEGIN
	DECLARE @tipo char(1)
	DECLARE @sucursal char(4)
	DECLARE @numero char(8)
	DECLARE @producto char(8)
	DECLARE @cantProducto decimal(12,2)
	DECLARE @itemsVendidosEnELMes int
	DECLARE @excedente int
	DECLARE cursor_ifact CURSOR FOR SELECT item_tipo,item_sucursal,item_numero,item_cantidad
									FROM inserted
	OPEN cursor_ifact
	FETCH NEXT FROM cursor_ifact
	INTO @tipo,@sucursal,@numero,@cantProducto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @itemsVendidosEnELMes = (
								SELECT sum(item_cantidad)
								FROM Item_Factura
									INNER JOIN Factura
										ON fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
								WHERE item_producto = @producto
									AND fact_fecha = (SELECT MONTH(GETDATE()))
								)
		IF (@itemsVendidosEnELMes + @cantProducto) > 100
		BEGIN
			SET @excedente = (@itemsVendidosEnELMes + @cantProducto)-100
			DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
			DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
			RAISERROR('No se puede comprar mas del producto %s, se superaron las unidades por %i',1,1,@producto,@excedente)
			ROLLBACK TRANSACTION
		END
		FETCH NEXT FROM cursor_ifact
		INTO @tipo,@sucursal,@numero,@cantProducto
	END
	CLOSE cursor_ifact
	DEALLOCATE cursor_ifact
END

/*------------------------------------------------------------------------------------------------------------------------------------------*/

/*31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.*/

--tipo de objeto: funcion y procedure

--por un lado con la funcion obtengo la cantidad de empleados a cargo que tiene un jefe

--luego con el procedure, analizo la informacion que le llegue de la funcion y ahi con un 
--procedure reasigno jefes nuevos cuando superen los limites 

--en el caso de que no exista un jefe para asignarlo se le coloca como jefe al gerente general (el que no tiene jefe)

CREATE FUNCTION dbo.empleadosACargo (@Jefe numeric(6,0))
RETURNS int

AS
BEGIN
	DECLARE @CantEmplACargo int = 0
	DECLARE @JefeAux numeric(6,0) = @Jefe
	DECLARE @CodEmplAux numeric(6,0)
	

	IF NOT EXISTS (SELECT * FROM EMPLEADO WHERE empl_jefe = @Jefe)
	BEGIN
		RETURN @CantEmplACargo
	END

	SET @CantEmplACargo = (SELECT COUNT(*)
						   FROM Empleado
						   WHERE empl_jefe = @Jefe AND empl_codigo > @Jefe)

	DECLARE cursor_empleado CURSOR FOR (SELECT E.empl_codigo
										FROM Empleado E
										WHERE empl_jefe = @Jefe)
	
	OPEN cursor_empleado
	
	FETCH NEXT from cursor_empleado
	INTO @JefeAux
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @CantEmplACargo = @CantEmplACargo + dbo.ejercicio11(@JefeAux)
			
	FETCH NEXT from cursor_empleado
	INTO @JefeAux
	END
	CLOSE cursor_empleado
	DEALLOCATE cursor_empleado

	RETURN @CantEmplACargo
END
GO


CREATE PROC dbo.ejercicio31
AS
BEGIN
	DECLARE @jefe numeric(6,0)
	DECLARE @nuevoJefe numeric(6,0)
	DECLARE cursor_jefe CURSOR FOR SELECT empl_codigo
								   FROM Empleado
								   WHERE empl_codigo IN (SELECT empl_jefe
														 FROM Empleado
														 WHERE empl_jefe IS NOT NULL)
	
	OPEN cursor_jefe
	
	FETCH NEXT FROM cursor_jefe
	INTO @jefe
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		 IF dbo.empleadosACargo(@jefe) > 20
		 BEGIN
			SET @nuevoJefe = (
									SELECT empl_codigo
									FROM Empleado
									WHERE dbo.empleadosACargo(empl_codigo) < 20 AND dbo.empleadosACargo(empl_codigo) >= 1
									)
			IF @nuevoJefe IS NOT NULL
			BEGIN
				UPDATE Empleado SET empl_jefe = @nuevoJefe WHERE empl_codigo = @jefe
			END
			ELSE
			BEGIN
				UPDATE Empleado SET empl_jefe = (
													SELECT empl_codigo
													FROM Empleado
													WHERE empl_jefe IS NULL
												)
					WHERE empl_codigo = @jefe
			END
		END
		FETCH NEXT FROM cursor_jefe
		INTO @jefe
	END
	CLOSE cursor_jefe
	DEALLOCATE cursor_jefe
END
GO
