
--MI PRIMER PARCIAL 4-7-2023

/*Realizar una consulta SQL que retorne para todas las zonas que tengan 3 o mas depositos:
- Detalle zona
- Cantidad de Depositos x Zona
- Cantidad de productos distintos compuestos en sus depositos
- Producto mas vendido en el año 2012 que tenga stock en al menos uno de sus depositos
- Mejor encargado perteneciente a esa zona (el que mas vendio en la historia)

El resultado debera ser ordenado por monto total vendido del encargado descendiente*/

--el tema de la cantidad de depositos lo puedo poner en el having o where

SELECT z.zona_detalle,

	   (SELECT COUNT(*) 
		FROM DEPOSITO d WHERE d.depo_zona = z.zona_codigo),

	   (SELECT COUNT(DISTINCT comp_producto)
		FROM Composicion
		JOIN STOCK ON (stoc_producto = comp_producto)
		JOIN DEPOSITO ON (stoc_deposito = depo_codigo)
		WHERE depo_zona = z.zona_codigo),

	   (SELECT TOP 1 item_producto
		FROM Item_Factura
		JOIN Factura ON (fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo)
		WHERE YEAR(fact_fecha) = 2012 AND EXISTS(SELECT * 
										   FROM STOCK
										   JOIN DEPOSITO ON (depo_codigo = stoc_deposito)
										   WHERE stoc_producto = item_producto AND stoc_cantidad > 0 AND depo_zona = z.zona_codigo)),

	  (SELECT TOP 1 depo_encargado
		FROM DEPOSITO
		JOIN Factura ON (depo_encargado = fact_vendedor)
		WHERE depo_zona = z.zona_codigo 
		GROUP BY depo_encargado
		ORDER BY SUM(fact_total) DESC)

FROM Zona z
WHERE (SELECT COUNT(*) FROM DEPOSITO WHERE depo_zona = z.zona_codigo) >= 3

--me tira datos diferentes a los de juampi

/*Actualmente el campo fact_vendedor representa al empleado que vendio la factura. 
Implementar el/los objetos necesarios para respetar la integridad referenciales de 
dicho campo suponiendo que no existe una foreign key entre ambos*/

--Los objetos son triggers

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

	
--PARCIAL 6

/* FOTO 6
Mostrar los dos empleados del mes, estos son:
a) El empleado que en el mes actual (en el cual se ejecuta la query) vendió más en dinero(fact_total).
b) El segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) vendió más cantidades (unidades de productos).
Se deberá mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 'MEJOR FACTURACION' y para el segundo
'VENDIÓ MÁS UNIDADES'.
NOTA: Si el empleado que más vendió en facturación y cantidades es el mismo, solo mostrar una fila que diga el empleado y 'MEJOR EN TODO'.
NOTA2: No se debe usar subselect en el from
*/

SELECT	e.empl_apellido +' '+ e.empl_nombre,
	   (CASE 
		WHEN(e.empl_codigo
			 IN (SELECT TOP 1 empl_codigo
				 FROM Empleado
	    		 JOIN Factura ON (empl_codigo = fact_vendedor)
				 WHERE MONTH(fact_fecha) = MONTH(GETDATE())
				 GROUP BY empl_codigo
				 ORDER BY SUM(fact_total) DESC))
		THEN 'Mejor facturacion'
		WHEN(SELECT empl_codigo FROM Empleado) 
			IN (SELECT TOP 1 empl_codigo
				FROM Empleado
				JOIN Factura ON (empl_codigo = fact_vendedor)
				JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
				WHERE MONTH(fact_fecha) = MONTH(GETDATE())
				GROUP BY empl_codigo
				ORDER BY SUM(item_cantidad) DESC)
		THEN 'Vendio mas unidades'
		WHEN (e.empl_codigo
			IN   (SELECT TOP 1 empl_codigo
				 FROM Empleado
	    		 JOIN Factura ON (empl_codigo = fact_vendedor)
				 WHERE MONTH(fact_fecha) = MONTH(GETDATE())
				 GROUP BY empl_codigo
				 ORDER BY SUM(fact_total) DESC)
			AND e.empl_codigo IN (SELECT TOP 1 empl_codigo
					FROM Empleado
					JOIN Factura ON (empl_codigo = fact_vendedor)
					JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
					WHERE MONTH(fact_fecha) = MONTH(GETDATE())
					GROUP BY empl_codigo
					ORDER BY SUM(item_cantidad) DESC))
		THEN 'Mejor en todo'
		END)
FROM Empleado e
WHERE e.empl_codigo IN (SELECT TOP 1 empl_codigo
						FROM Empleado
						JOIN Factura ON (empl_codigo = fact_vendedor)
						WHERE MONTH(fact_fecha) = MONTH(GETDATE())
						GROUP BY empl_codigo
						ORDER BY SUM(fact_total) DESC)
	 OR e.empl_codigo IN (SELECT TOP 1 empl_codigo
						  FROM Empleado
						  JOIN Factura ON (empl_codigo = fact_vendedor)
						  JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
						  WHERE MONTH(fact_fecha) = MONTH(GETDATE())
						  GROUP BY empl_codigo
						  ORDER BY SUM(item_cantidad) DESC)
GROUP BY e.empl_codigo, e.empl_apellido, e.empl_nombre
ORDER BY e.empl_codigo ASC


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

CREATE PROCEDURE ejercicio2 (@NumFactura CHAR(8), @TipoFactura CHAR(1), @SucursFactura CHAR(8), @CodProducto CHAR(8), @CantProd INT)
AS
BEGIN
	
	DECLARE @PrecioProd DECIMAL(12,2)
	DECLARE @Total DECIMAL(12,2)

	IF EXISTS(SELECT stoc_cantidad 
			  FROM STOCK
			  JOIN DEPOSITO ON (stoc_deposito = depo_codigo) 
			  JOIN Producto ON (stoc_producto = prod_codigo)
			  WHERE prod_codigo = @CodProducto AND stoc_cantidad > @CantProd)
	BEGIN

		SET @PrecioProd = (SELECT prod_precio
					       FROM Producto
			 		       WHERE prod_codigo = @CodProducto)

		SET @Total = (SELECT fact_total 
					  FROM Factura 
					  WHERE fact_tipo + fact_sucursal + fact_numero = @TipoFactura + @SucursFactura + @NumFactura)

		INSERT INTO Item_Factura VALUES (@TipoFactura, @SucursFactura, @NumFactura, @CodProducto, @CantProd,@PrecioProd)
		
		UPDATE STOCK
		SET stoc_cantidad = stoc_cantidad - @CantProd
		WHERE stoc_deposito IN (SELECT TOP 1 stoc_deposito FROM STOCK WHERE stoc_producto = @CodProducto)

		UPDATE Factura
		SET fact_total = @Total,
		fact_total_impuestos = @Total * 0.21
	END
	ELSE
	BEGIN
		PRINT 'No hay stock en el Deposito'
	END

END
GO

--PARCIAL 2

/*1)Escriba una consulta SQL que retorne un ranking de facturacion por año y zona
devolviendo las siguientes columnas:

- AÑO
- COD DE ZONA
- DETALLE DE ZONA
- CANT DE DEPOSITOS DE LA ZONA
- CANT DE EMPLEADOS DE DEPARTAMENTOS DE ESA ZONA
- EMPLEADO QUE MAS VENDIO EN ESE AÑO Y ESA ZONA
- MONTO TOTAL DE VENTA DE ESA ZONA EN ESE AÑO
- PORCENTAJE DE LA VENTA DE ESE AÑO EN ESA ZONA RESPECTO AL TOTAL VENDIDO DE ESE AÑO

Los datos deberan estar ordenados por año y dentro del año por la zona con mas facturacion
de mayor a menor */

SELECT  YEAR(f.fact_fecha),
		z.zona_codigo,
		z.zona_detalle,
		(SELECT COUNT(depo_codigo) 
		 FROM DEPOSITO 
		 WHERE depo_zona = z.zona_codigo) AS depositos_Zona,
		COUNT(e.empl_codigo) AS empleados_depart_zona,
		(SELECT TOP 1 empl_codigo 
		 FROM Empleado
		 JOIN Factura ON (empl_codigo = fact_vendedor)
		 JOIN Departamento ON (empl_departamento = depa_codigo)
		 WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND depa_zona = z.zona_codigo) AS empl_que_mas_vendio,
		SUM(f.fact_total) AS monto_total,
	   (SUM(f.fact_total) * 100) / (SELECT SUM(fact_total) FROM Factura WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)) AS porc_venta
FROM Factura f 
JOIN Empleado e ON (f.fact_vendedor = e.empl_codigo)
JOIN Departamento de ON (e.empl_departamento = de.depa_codigo)
JOIN Zona z ON (de.depa_zona = zona_codigo)
GROUP BY YEAR(f.fact_fecha), z.zona_codigo, z.zona_detalle
ORDER BY YEAR(f.fact_fecha) ASC, SUM(f.fact_total) DESC

/*2) Se requiere recategorizar los encargados asignados a los depositos. 
Para ello cree el o los objetos de bases de datos necesarios que lo resuelva, 
teniendo en cuenta que un deposito no puede tener como encargado un empleado que 
pertenezca a un departamente que no sea de la misma zona que el deposito, si esto 
ocurrea dicho deposito debera asignarsele el empleado con menos depositos asignados
que pertenezca a un departamento de esa zona.*/

--RECATEGORIZAR LOS ENCARGADOS ASIGNADOS A LOS DEPOSITOS

--puede ser un UPDATE o modifcar estado de los datos, creo que es conveniente un procedure

--Un deposito no puede tener como encargado un empleado que pertenezca a un departamento que no sea de la misma zona del deposito
--osea depa_zona = depo_zona si o si del encargado

--Si eso ocurre se debe asignar como encargado nuevo al empleado con menos depositos asignados que pertenezca a un departamento de esa zona

CREATE PROCEDURE ejercicio 
AS
BEGIN

	IF NOT EXISTS(SELECT depo_codigo 
			  FROM DEPOSITO 
			  JOIN Empleado ON (depo_encargado = empl_codigo) 
			  JOIN Departamento ON (empl_departamento = depa_codigo)
			  WHERE depa_zona = depo_zona)
	BEGIN 
		UPDATE DEPOSITO
		SET depo_encargado = (SELECT TOP 1 empl_codigo
							  FROM Empleado
							  JOIN Departamento ON (empl_departamento = depa_codigo)
							  JOIN DEPOSITO ON (depo_encargado = empl_codigo)
							  WHERE depa_zona = depo_zona
							  GROUP BY empl_codigo
							  ORDER BY COUNT(depo_codigo) ASC)
		WHERE depo_codigo
	END
	ELSE 
	BEGIN
	PRINT 'El encargado de cada deposito tiene misma zona en su departamento'
END

END
GO
--FALTA AGREGAR UN CURSOR QUE MEJOR TODO EL PROCESO

GO

--PARCIAL 1-7-2023

/*Ejercicio 1*/

--clientes que compraron en dos años consecutivos (que tenga una factura del año anterior y del actual)

SELECT c.clie_codigo,
	   c.clie_razon_social,
	   (SELECT COUNT(rubr_id)
	    FROM Rubro 
		JOIN Producto ON (prod_rubro = rubr_id)
		JOIN Item_Factura ON (item_producto = prod_codigo)
		JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
		WHERE fact_cliente = c.clie_codigo) AS rubros_compr_cliente,
		(SELECT COUNT(comp_producto)
		 FROM Composicion
		 JOIN Item_Factura ON (item_producto = comp_producto)
		 JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
		 WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo) AS prod_comp_2012
FROM Cliente c
JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
JOIN Factura f2 ON (c.clie_codigo = f2.fact_cliente)
WHERE YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)+1 OR YEAR(f.fact_fecha) = YEAR(f2.fact_fecha)-1
GROUP BY c.clie_codigo, c.clie_razon_social, YEAR(f.fact_fecha)
ORDER BY  COUNT(f.fact_tipo + f.fact_sucursal + f.fact_numero) ASC

/*Ejercicio 2*/

--actualizada bajo cualquier circunstancia -> trigger

--crear una tabla llamada PRODUCTOS_VENDIDOS

CREATE TABLE PRODUCTOS_VENDIDOS(
	PERIODO SMALLDATETIME NOT NULL PRIMARY KEY,
	PRODUCTO_COD CHAR(8),
	PRECIO_MAX_VENTA DECIMAL(12,2),
	UNIDADES_VEND INT
);

CREATE TRIGGER ejercicio2 ON Factura FOR INSERT, UPDATE
AS
BEGIN
	
	DECLARE @Producto CHAR(8)
	DECLARE @Precio DECIMAL(12,2)
	DECLARE @Periodo SMALLDATETIME
	DECLARE @UnidadesVendidas INT

	DECLARE cursor_prod_vendido CURSOR FOR (SELECT item_producto, item_precio, fact_fecha, item_cantidad 
											FROM inserted 
											JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero))
	OPEN cursor_prod_vendido

	FETCH NEXT cursor_prod_vendido
	INTO @Producto, @Precio, @Periodo,@UnidadesVendidas

	WHILE @@FETCH_STATUS = 0
	BEGIN
	IF NOT EXISTS(SELECT * FROM inserted WHERE PERIODO = @Periodo AND PRODUCTO_COD = @Producto)
	BEGIN
		INSERT INTO PRODUCTOS_VENDIDOS VALUES (@Periodo, @Producto, @Precio, @UnidadesVendidas)
	END
	ELSE
	BEGIN

		UPDATE PRODUCTOS_VENDIDOS
		SET PRECIO_MAX_VENTA = @Precio
		WHERE PERIODO = @Periodo AND PRODUCTO_COD = @Producto AND PRECIO_MAX_VENTA < @Precio
		
		UPDATE PRODUCTOS_VENDIDOS
		SET UNIDADES_VEND += @UnidadesVendidas 
		WHERE PERIODO = @Periodo AND PRODUCTO_COD = @Producto
	END

	FETCH NEXT cursor_prod_vendido
	INTO @Producto, @Precio, @Periodo,@UnidadesVendidas

	END

	CLOSE cursor_prod_vendido

	DEALLOCATE cursor_prod_vendido
END


/*Cuando te dan una tabla y te piden que la mantengas actualizada y consistente, se debe realizar un trigger en el cual se 
declaren como variables los parametros de esa tabla y luego un cursor que este definido para el conjunto de valores que declaramos.
A partir de eso tenemos que evaluar si no existe y lo creamos, y como else lo updeteamos para que quede actualizado


NO OLVIDAR INDICAR SIGUIENTE PASO DEL CURSOR, CERRARLO Y LIBERARLO*/


--PARCIAL 8-11-2022


/*Ejercicio 1*/

--cliente compro un producton todos los meses de 2012


SELECT c.clie_codigo,
	   c.clie_razon_social,
	   p.prod_codigo AS prod_comprado,
	   p.prod_detalle AS prod_nombre,
	   COUNT(DISTINCT p.prod_codigo) AS cant_prod_comprados,
	   (SELECT COUNT(DISTINCT comp_producto)
		FROM Composicion
		JOIN Item_Factura ON (comp_producto = item_producto)
		JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE fact_cliente = c.clie_codigo AND YEAR(fact_fecha) = 2012) AS cant_prod_comp_comprados
FROM Cliente c
JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
JOIN Item_Factura i ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
JOIN Producto p ON (i.item_producto = p.prod_codigo)
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY c.clie_codigo, c.clie_razon_social, p.prod_codigo, p.prod_detalle
HAVING COUNT(DISTINCT MONTH(f.fact_fecha)) = 12 --no hay de doce meses
ORDER BY COUNT(DISTINCT i.item_producto) DESC 


/*Ejercicio 2*/

--implementar una logica de control de precios en las ventas

--lista de rubros
--aquellos productos de los rubros que sean los seleccionados no podran aumentar por mes mas de un 2%

--en caso de no tener referencia del mes anterior no validar dicha regla

CREATE PROCEDURE ejercicio2 
AS
BEGIN

	DECLARE @Rubro CHAR(4)

	DECLARE cursor_rubros CURSOR FOR (SELECT rubr_id FROM Rubro)

	OPEN cursor_rubros

	FETCH NEXT cursor_rubros
	INTO @Rubro

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		IF EXISTS(SELECT prod_codigo 
				  FROM Producto p
				  JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
				  JOIN Factura f ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
				  WHERE p.prod_rubro = @Rubro AND p.prod_codigo = (SELECT prod_codigo
																   FROM Producto 
																   JOIN Item_Factura ON (prod_codigo = item_producto)
																   JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
																   WHERE MONTH(fact_fecha) = MONTH(f.fact_fecha) - 1 AND p.prod_precio > prod_precio))
		--ESTA MAL LA ULTIMA CONDICION DEL WHERE PERO NO SE DE QUE OTRA FORMA HACERLO
		BEGIN
			PRINT 'El producto no puede aumentar por mes mas del 2%'
		END
		ELSE
		BEGIN
			PRINT 'El producto no tiene referencia del mes anterior para validar la regla o no aumento de un mes al otro un 2%'
		END
	END

	CLOSE cursor_rubros

	DEALLOCATE cursor_rubros

END
GO


--PARCIAL 15-11-2022

/*Ejercicio 1*/

--clientes que compraron todos los rubros disponibles del sistema en 2012

SELECT c.clie_codigo,
	   p.prod_codigo AS prod_mas_comprado,
	   p.prod_detalle AS nombr_prod_mas_comprado,
	   (SELECT COUNT(DISTINCT item_producto)
		FROM Item_Factura
		JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo) AS cant_prod_comprados_clie,
	   (SELECT COUNT(DISTINCT comp_producto)
		FROM Composicion 
		JOIN Item_Factura ON (comp_producto = item_producto)
		JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero) 
		WHERE fact_cliente = c.clie_codigo) AS cant_prod_comp_comprados_clie
FROM Cliente c
JOIN Factura f ON (f.fact_cliente = c.clie_codigo)
JOIN Item_Factura i ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
JOIN Producto p ON (i.item_producto = p.prod_codigo)
WHERE YEAR(f.fact_fecha) = 2012 AND p.prod_codigo IN (SELECT TOP 1 item_producto
													  FROM Item_Factura
													  JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
													  WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo
													  GROUP BY item_producto
													  ORDER BY SUM(item_cantidad) DESC)
GROUP BY c.clie_codigo, p.prod_codigo, p.prod_detalle, p.prod_rubro, c.clie_razon_social
HAVING (SELECT COUNT(DISTINCT prod_rubro)
		FROM Rubro 
		JOIN Producto ON (rubr_id = prod_rubro)
		JOIN Item_Factura ON (prod_codigo = item_producto)
		JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo )
	=	(SELECT COUNT(DISTINCT rubr_id)
		 FROM Rubro
		 JOIN Producto ON (rubr_id = prod_rubro)
		 JOIN Item_Factura ON (prod_codigo = item_producto)
	     JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		 WHERE YEAR(fact_fecha) = 2012)
-- HAVING clientes que compraron todos los rubros disponibles del sistema en 2012
ORDER BY c.clie_razon_social ASC --falto agregar que se ordene segun otro criterio mas

/*Ejercicio 2*/

--al realizar una venta (solo insercion) permita componer los productos descompuestos

--guardar los elementos en algun combo

--cada vez que se guardan los items, se mandan todos los productos de ese item a la vez, y no de manera parcial

CREATE PROCEDURE ejercicio2
AS
BEGIN

	--DECLARAMOS TODAS ESTAS VARIABLES PARA COMPLETAR LOS DATOS DE ITEM
	--prod combo
	DECLARE @Combo CHAR(8)
	--cant de componentes del combo
	DECLARE @CantCombo INT
	
	DECLARE @FactTipo CHAR(1)
	DECLARE @FactSuc CHAR(4)
	DECLARE @FactNro CHAR(8)

	DECLARE cursor_combo CURSOR FOR (SELECT fact_tipo, fact_sucursal, fact_numero FROM Factura)

	OPEN cursor_combo

	FETCH NEXT cursor_combo
	INTO @FacTipo, @FactSuc, @FactNro
	 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--COMO SABEMOS QUE PUEDE HABER MAS DE UN COMBO EN UNA FACTURA, CREAMOS OTRO CURSOR QUE RECORRA PRODS
		DECLARE cursor_prod CURSOR FOR (SELECT comp_producto FROM Item_Factura JOIN Composicion c1 ON (comp_producto = item_producto)
										WHERE item_cantidad >= c1.comp_cantidad AND (item_tipo + item_sucursal + item_numero = @FactTipo + @FactSuc + @FactNro )
										GROUP BY c1.comp_producto
										HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion c2 WHERE c1.comp_producto = c2.comp_producto))
		OPEN cursor_prod

		FETCH NEXT cursor_prod
		INTO @Combo

		WHILE @@FETCH_STATUS = 0
		BEGIN
			--Aca obtenemos la maxima cantidad de combos que se pueden armar
			SELECT @CantCombo = MIN(FLOOR((item_cantidad / c1.comp_cantidad)))
			FROM Item_Factura 
			JOIN Composicion c1 ON (item_producto = c1.comp_producto)
			WHERE item_cantidad >= c1.comp_cantidad AND c1.comp_producto = @Combo
				  AND (item_tipo + item_sucursal + item_numero = @FactTipo + @FactSuc + @FactNro)
			
			--insertar la fila del combo con el precio que corresponde
			INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
			VALUES (@FactTipo,@FactSuc,@FactNro, @Combo, @CantCombo, (@CantCombo * (SELECT prod_precio FROM Producto WHERE prod_codigo = @combo)))
			
			--hacer un update en la tabla de item_factura
			UPDATE Item_Factura
			SET item_cantidad = i1.item_cantidad - (@CantCombo * (SELECT comp_cantidad FROM Composicion
																  WHERE i1.item_producto = comp_componente 
																	    AND comp_producto = @Combo)),
			item_precio = (i1.item_cantidad - (@CantCombo * (SELECT comp_cantidad FROM Composicion
																	 WHERE i1.item_producto = comp_componente 
																	 AND comp_producto=@Combo))) * 	(SELECT prod_precio FROM Producto WHERE prod_codigo = i1.item_producto)	
		
			FROM Item_Factura i1, Composicion c1
			WHERE (i1.item_tipo + i1.item_sucursal + i1.item_numero = @FactTipo + @FactSuc + @FactNro) AND c1.comp_producto = @Combo

			--borramos de item_factura los elementos que ya se unieron en algun combo
			DELETE FROM Item_Factura
			WHERE (item_tipo + item_sucursal + item_numero = @FactTipo + @FactSuc + @FactNro) AND item_cantidad = 0

			FETCH NEXT FROM cursor_prod
			INTO @Combo
		END

		CLOSE cursor_prod

		DEALLOCATE cursor_prod

		FETCH NEXT FROM cursor_combo 
		INTO @FacTipo, @FactSuc, @FactNro
	END

	CLOSE cursor_combo

	DEALLOCATE cursor_combo
END
GO


--PARCIAL 22-11-2022

--productos que tengan 3 componentes a nivel producto y cuyos componentes tengan 2 rubros distintos

SELECT p.prod_codigo,
	   p.prod_detalle,
	   (SELECT COUNT( comp_componente)
		FROM Composicion
		JOIN Item_Factura ON (comp_producto = item_producto)
		JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND comp_producto = p.prod_codigo) AS prod_comp_vend_2012,
	   SUM(f.fact_total) AS monto_total
FROM Producto p
JOIN Composicion c ON (p.prod_codigo = c.comp_producto)
JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
JOIN Factura f ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
WHERE c.comp_cantidad = 3 AND (SELECT COUNT(DISTINCT prod_rubro)
							   FROM Composicion
							   JOIN Producto ON (comp_producto = prod_codigo)
							   WHERE prod_codigo = c.comp_componente) = 2
GROUP BY p.prod_codigo, p.prod_detalle, c.comp_producto
ORDER BY (SELECT COUNT(*)
		  FROM Factura
		  JOIN Item_Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		  WHERE item_producto = p.prod_codigo AND YEAR(fact_fecha) = 2012) DESC


/*Ejercicio 2*/

--validar que nunca un producto compuesto pueda estar compuesto por componentes de rubros distintos a el
--regla de negocio en linea (osea tiene que estar actualizada)

CREATE TRIGGER ejercicio2 ON Composicion FOR INSERT, UPDATE
AS
BEGIN
	IF NOT EXISTS(SELECT c.comp_producto
				FROM Composicion c
				GROUP BY c.comp_producto
				HAVING COUNT(c.comp_producto) = (SELECT COUNT(DISTINCT prod_rubro)
												FROM Composicion
												JOIN Producto ON (comp_producto = prod_codigo)
												WHERE comp_producto = c.comp_producto)
						AND c.comp_producto IN (SELECT * From inserted))
	BEGIN
		PRINT 'El producta no debe esta compuesto por componentes con diferentes rubros'
		ROLLBACK TRANSACTION
	END
END



--PARCIAL NICO 4-7-2023


/*Realizar una consulta SQL que retorne para los 10 clientes que mas compraron en el 2012 y 
que fueron atendidos por mas de 3 vendedores distintos:
 
- Apellido y nombre del cliente
- Cantidad de Produtos distintos comprados en el 2012
- Cantidad de unidades compradas dentro del primer semestre del 2012

El resultado debera mostrar ordenado la cantidad de compras descendente de 2012  de cada cliente,
en caso de igualdad de vendas, ordendar por codigo de cliente*/

SELECT TOP 10 c.clie_razon_social,
			  (SELECT COUNT(DISTINCT item_producto)
			   FROM Item_Factura 
			   JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
			   WHERE YEAR(fact_fecha) = 2012  AND fact_cliente = c.clie_codigo) AS prod_compr_2012,
			  (SELECT COUNT(item_cantidad)
			   FROM Item_Factura
			   JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
			   WHERE YEAR(fact_fecha) = 2012 AND MONTH(fact_fecha) BETWEEN 01 AND 06 AND fact_cliente = c.clie_codigo) AS unidades_compr_1semtr_2012
FROM Cliente c
JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY c.clie_razon_social,c.clie_codigo, YEAR(f.fact_fecha)
HAVING COUNT(DISTINCT f.fact_vendedor) > 3
ORDER BY COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) DESC, c.clie_codigo


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



