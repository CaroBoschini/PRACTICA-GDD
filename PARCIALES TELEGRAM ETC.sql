

--PARCIAL 8/11/2022

/*1) Realizar una consulta SQL que permita saber si un cliente compro un producto en todos los meses de 2012
Mostrar para el 2012:
1- El cliente
2- La razon social del cliente
3- El producto comprado
4- El nombre del producto
5- Cantidad de productos distintos comprados por el cliente
6- Cantidad de productos con composicion comprados por cliente

El resultado debera ser ordenado poniendo primero aquellos clientes que compraron mas de 10 productos distintos en el 2012*/


--me falta que filtre esto: saber si un cliente compro un producto todos los meses de 2012

--VERSION CARO
SELECT c.clie_codigo AS cliente,
	   c.clie_razon_social AS razon_social,
	   i.item_producto AS prod_comprado,
	   p.prod_detalle AS nombre_producto,
	   (SELECT COUNT(DISTINCT item_producto) 
	    FROM Item_Factura
			JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo ) AS cant_prod_comprados,
	   (SELECT COUNT(item_producto) 
		FROM Item_Factura
			JOIN Producto ON (item_producto = prod_codigo)
			JOIN Composicion ON (prod_codigo = comp_producto)
			JOIN  Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = c.clie_codigo 
			  AND (item_tipo + item_sucursal + item_numero) = (i.item_tipo + i.item_sucursal + i.item_numero)) AS cant_prod_comp_comprados
FROM Cliente c 
	JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
	JOIN Item_Factura i ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
	JOIN Producto p ON (p.prod_codigo = i.item_producto)
WHERE (select top 1 count(distinct(month(fact_fecha))) from Factura
	   where fact_cliente = c.clie_codigo) > 8
GROUP BY c.clie_codigo, c.clie_razon_social, i.item_producto, p.prod_detalle, i.item_tipo, i.item_sucursal, i.item_numero
ORDER BY (SELECT TOP 10 clie_codigo
		  FROM Cliente
			 JOIN Factura ON (clie_codigo = fact_cliente)
			 JOIN Item_Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		  WHERE YEAR(fact_fecha) = 2012 AND COUNT(DISTINCT i.item_producto) > 10 AND clie_codigo = c.clie_codigo
		  GROUP BY clie_codigo
		  ORDER BY 1 DESC)

--VERSION NICO
select clie_codigo,
       clie_razon_social,
       item_producto,
	   p.prod_detalle,
       (select count(distinct(itf.item_producto)) 
        from Item_Factura itf
        join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero = itf.item_tipo+itf.item_sucursal+itf.item_numero
        where year(f.fact_fecha)=2012 and f.fact_cliente = clie_codigo) 
        as cantidad_productos_distintos,
        (select count(distinct(c.comp_producto)) 
        from Item_Factura itf
        join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero = itf.item_tipo+itf.item_sucursal+itf.item_numero
        join Composicion c on itf.item_producto = c.comp_producto
        where year(f.fact_fecha)=2012 and f.fact_cliente = clie_codigo) 
        as cantidad_productos_con_composicion

from Cliente
join Factura on clie_codigo = fact_cliente
join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
JOIN Producto p ON (p.prod_codigo = item_producto)

where year(fact_fecha) = 2012

group by clie_codigo, clie_razon_social, item_producto, p.prod_detalle
-- EL HAVING TIENE QUE FILTRAR POR EL TEMA DE LOS MESES
having (select count(distinct(month(f2.fact_fecha))) from Factura f2
       join Item_Factura itf2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero = itf2.item_tipo+itf2.item_sucursal+itf2.item_numero
       where itf2.item_producto = item_producto and f2.fact_cliente = clie_codigo) = 12

order by (select TOP 10 count(distinct(itf3.item_producto)) 
          from Factura f3
          join Item_Factura itf3 on f3.fact_tipo+f3.fact_sucursal+f3.fact_numero = itf3.item_tipo+itf3.item_sucursal+itf3.item_numero
          where year(f3.fact_fecha) = YEAR(fact_fecha) AND f3.fact_cliente = clie_codigo 
          group by f3.fact_cliente
          having count(distinct(itf3.item_producto)) > 10
          order by 1 desc)


/*2) Implementar una regla de negocio de validacion en linea que permita implementar una logica de control de precios
en las ventas. Se debera poder seleccionar una lista de rubros y aquellos productos de los rubros que sean los
seleccionados no podran aumentar por mes mas de un 2%. En caso que no se tenga referencia del mes anterior no validar
dicha regla.*/

--tipo objeto: trigger para que sea una regla de negocio y se haga automatico el proceso de validacion

--INSTEAD OF UPDATE

--tabla a asociar: Rubro

-- los productos de los rubros que sean seleccionados no podran aumentar por mes mas de un 2%

--cuando no se cumple eso, cuando no se tiene referencia del mes anterior


CREATE TRIGGER control_precios_ventas ON Rubro INSTEAD OF UPDATE
AS
BEGIN
	DECLARE @producto CHAR(8)

	DECLARE cursor_producto CURSOR FOR (SELECT prod_codigo FROM Producto)

	OPEN cursor_producto

	FETCH NEXT FROM cursor_producto
	INTO @producto

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS ((SELECT prod_codigo 
					FROM Producto
						JOIN Item_Factura ON (prod_codigo = item_producto)
						JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
					WHERE prod_codigo = @producto))
		BEGIN
			IF()
		END
		ELSE 
		BEGIN
			
		END
	END
	
	CLOSE cursor_producto

	DEALLOCATE cursor_producto

END
GO

 
/*--------------------------------------------------------------------------------------------------------------------------------------*/

--PARCIAL 15-11-2022


/*1)Realizar una consulta que permita saber los clientes que compraron todos los rubros disponibles del sistema en el 2012
De estos clientes mostrar, siempre para el 2012:
1- El codigo del cliente
2- Codigo del producto que en cantidades mas compro
3- El nombre del producto del punto 2
4- Cantidad de productos distintos comprados por el cliente
5- Cantidad de productos con composicion comprados por el cliente

El resultado debera ser ordenado por razon social del cliente alfabeticamente primero y luego, los clientes que compraron
entre un 20% y 30% del total facturado en el 2012 primero, luego, los restantes*/

--SELECT * FROM Rubro son en total 31 rubros 


/*SELECT (SELECT fact_cliente 
		FROM Factura 
			JOIN Item_Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND item_producto = p.prod_codigo ) AS clie_codigo,
	   p.prod_codigo,
	   p.prod_detalle,
	   COUNT(DISTINCT p.prod_codigo),
	   (SELECT COUNT(prod_codigo)
		FROM Producto 
			JOIN Composicion ON (prod_codigo = comp_producto)
			JOIN Item_Factura ON (prod_codigo = item_producto)
			JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE YEAR(fact_fecha) = 2012 AND prod_codigo = p.prod_codigo
		GROUP BY COUNT(prod_codigo)
		ORDER BY 1 DESC)
FROM Producto p
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
WHERE p.prod_codigo IN(
		SELECT item_producto
		FROM Item_Factura
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC
	) AND YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY 


SELECT c.clie_codigo,
	   (SELECT item_producto, SUM(item_cantidad)
		FROM Item_Factura 
			JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE fact_cliente = c.clie_codigo
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC) AS prod_mas_comprado,
		(SELECT prod_detalle
		FROM Producto
			JOIN Item_Factura ON (prod_codigo = item_producto)
			JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
		WHERE fact_cliente = c.clie_codigo
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC)
		
FROM Cliente c */




/*SELECT p.prod_codigo, p.prod_detalle, 
	   (SELECT TOP 1 f.fact_cliente 
	   	FROM Factura f INNER JOIN Item_Factura fact ON (f.fact_sucursal = fact.item_sucursal AND f.fact_numero = fact.item_numero AND f.fact_tipo = fact.item_tipo)
		WHERE p.prod_codigo = fact.item_producto
		GROUP BY f.fact_cliente
		ORDER BY SUM(fact.item_cantidad) DESC)
FROM Producto p INNER JOIN Item_Factura fact1 ON (fact1.item_producto = p.prod_codigo)
WHERE 
	P.prod_codigo IN(
		SELECT TOP 10 item_producto
		FROM Item_Factura
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC
	)
	OR
	P.prod_codigo IN(
		SELECT TOP 10 item_producto
		FROM Item_Factura
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) ASC
	)
GROUP BY P.prod_codigo,P.prod_detalle*/

/*--------------------------------------------------------------------------------------------------------------------------------------*/