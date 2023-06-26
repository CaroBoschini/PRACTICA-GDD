/*1. Mostrar el c�digo, raz�n social de TODOS los clientes cuyo l�mite de cr�dito sea mayor o
igual a $ 1000 ordenado por c�digo de cliente.*/

/*mi universo es la tabla cliente,*/
/*me pide dos columnas*/
SELECT clie_codigo, clie_razon_social
FROM CLIENTE /*define el universo en donde voy a trabajar*/
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo ASC
/*DESC o ASC me lo ordena, tambien se puede poner ORDER BY 1 ASC, que conviene mas*/
/*SOLO SE PUEDE PONER INDICE EN EL ORDER BY*/ 

/*----------------------------------------------------------------------------------------------------------------------*/

/*2. Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
cantidad vendida.*/

SELECT prod_codigo, prod_detalle
FROM ITEM_FACTURA JOIN PRODUCTO ON (item_producto = prod_codigo)
/*une item producto con prod codigo, por cada iten lo iguala y delvuelve lo que da ahi y siempre encuentra una fila*/
JOIN Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
WHERE YEAR(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY SUM(item_cantidad) DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*3.Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del art�culo de menor a mayor.*/

SELECT prod_codigo, prod_detalle, stoc_cantidad
FROM STOCK JOIN PRODUCTO ON (prod_codigo = stoc_producto)
GROUP BY prod_codigo, prod_detalle, stoc_cantidad
ORDER BY prod_detalle ASC

/*----------------------------------------------------------------------------------------------------------------------*/

/*4. Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
promedio por dep�sito sea mayor a 100.*/

SELECT prod_codigo, prod_detalle, count(comp_producto)
FROM Producto LEFT JOIN  Composicion on (comp_producto = prod_codigo)
--se resuelve con una consulta subselect
WHERE prod_codigo in (SELECT stoc_producto FROM STOCK
					  GROUP BY stoc_producto
				      HAVING  AVG(stoc_cantidad) > 100)
GROUP BY prod_codigo, prod_detalle
ORDER BY 3 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*5. Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.*/

--cuando tenemos condiciones disyuntivas, como lo de 2012 y 2011, tenemos que usar HAVING

SELECT prod_codigo, prod_detalle
FROM Producto JOIN Item_Factura ON (prod_codigo = item_producto) JOIN Factura ON
	(fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
WHERE year(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle 
HAVING sum(item_cantidad) > (SELECT sum(item_cantidad) FROM Item_Factura JOIN Factura ON
							(fact_tipo + fact_sucursal + fact_numero =item_tipo + item_sucursal + item_numero)
							 WHERE item_producto = prod_codigo AND year(fact_fecha) = 2011)


/*----------------------------------------------------------------------------------------------------------------------*/

/*6. Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese
rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que
tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.
*/

SELECT rubr_id, rubr_detalle,COUNT(distinct prod_codigo) AS cantidad_stock, SUM(ISNULL(stoc_cantidad,0))
FROM Rubro LEFT JOIN Producto ON (prod_rubro = rubr_id) JOIN STOCK ON (prod_codigo = stoc_producto)
WHERE stoc_cantidad > (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = '00000000' AND stoc_deposito = '00')
GROUP BY rubr_id, rubr_detalle
ORDER BY 1, 2 ASC
/*----------------------------------------------------------------------------------------------------------------------*/

/*7. Generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos art�culos que posean
stock.*/

--Universo: producto, stock
--Elementos del universo: prod_codigo, prod_detalle, prod_precio para el mayor y prod_precio para el menor y por ultimo
--porcentaje de diferencia de precios
--condicion: mostrar solo aquellos articulos que posean stock

SELECT prod_codigo, prod_detalle, MIN(item_precio) AS menor_precio,
								  MAX(item_precio) AS mayor_precio,
								  CONVERT(varchar,((MAX(item_precio)/MIN(item_precio) - 1) * 100)) AS porct_dif
FROM Producto JOIN STOCK ON (prod_codigo = stoc_producto) JOIN Item_Factura ON (prod_codigo = item_producto)
WHERE stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle

/*solo usas el having si tenes que filtrar algo del group by*/

/*----------------------------------------------------------------------------------------------------------------------*/

/*8. Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del
art�culo, stock del dep�sito que m�s stock tiene.*/

--Universo: Producto, Stock, Depositos
--Elementos:prod_codigo, stoc_cantidad (del deposito que mas tiene)
--Condicion: el o los articulos tienen que tener stock en los depositos

SELECT prod_codigo, prod_detalle, MAX(stoc_cantidad)
FROM STOCK JOIN Producto ON (stoc_producto = prod_codigo)
WHERE stoc_cantidad > 0
GROUP BY prod_codigo, prod_detalle
HAVING sum(stoc_cantidad) > 0 and count(*) = (SELECT count(*) from DEPOSITO) - 30

/*----------------------------------------------------------------------------------------------------------------------*/

/*9. Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de dep�sitos que ambos tienen asignados.*/

--Universo: Empleado, Deposito
--Elementos: empl_codigo del jefe, empl_codigo del empleado que lo tiene de jefe, empl_nombre empleado, COUNT(depo_codigo)
--Condicion: mostrar la cantidad de depositos de ambos por separado

SELECT empl_jefe, empl_codigo, empl_nombre, COUNT(depo_codigo) AS cant_dep_empl, 
	   ((SELECT COUNT(depo_encargado)
		FROM DEPOSITO
		WHERE depo_encargado = empl_jefe
		GROUP BY depo_encargado)) AS cant_dep_jefe
FROM Empleado LEFT JOIN DEPOSITO ON (empl_codigo = depo_encargado)
GROUP BY empl_jefe, empl_codigo, empl_nombre

/*----------------------------------------------------------------------------------------------------------------------*/

/*10. Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos
vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que
mayor compra realizo.*/

SELECT p.prod_codigo, p.prod_detalle, 
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
GROUP BY P.prod_codigo,P.prod_detalle

/*----------------------------------------------------------------------------------------------------------------------*/

/* 11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012. */

--UNIVERSO: Familia. Factura, Item_Factura,
--ELEMENTOS: fami_detalle, prod_codigo,fact_total
--CONDICION: 


SELECT f.fami_id, f.fami_detalle, COUNT(DISTINCT p.prod_detalle), SUM(fac.fact_total)
FROM Familia f 
	JOIN Producto p ON (p.prod_familia = f.fami_id)
	JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
	JOIN Factura fac ON (f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero)
GROUP BY f.fami_id, f.fami_detalle
HAVING EXISTS(SELECT TOP 1 fact_numero
			  FROM Factura 
			  JOIN Item_Factura ON (fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND fact_numero = item_numero)
			  JOIN Producto ON (prod_codigo = item_producto)
			  WHERE YEAR(fact_fecha) = 2012 AND prod_familia = f.fami_id
			  GROUP BY fact_numero
			  HAVING SUM (fact_total)  > 100 )
ORDER BY 3 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*12. Mostrar:
-nombre de producto, 
-cantidad de clientes distintos que lo compraron,
-importe promedio pagado por el producto, 
-cantidad de depósitos en los cuales hay stock del producto
-stock actual del producto en todos los depósitos
Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.*/

SELECT p.prod_codigo, p.prod_detalle, (SELECT COUNT(DISTINCT f.fact_cliente )), AVG(i.item_precio),
	   (SELECT COUNT(DISTINCT stoc_deposito) FROM STOCK WHERE p.prod_codigo = stoc_producto AND ISNULL(stoc_cantidad, 0) > 0),
	   (SELECT SUM(stoc_cantidad) FROM STOCK WHERE p.prod_codigo = stoc_producto)
FROM Producto p 
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (f.fact_tipo = i.item_tipo AND f.fact_sucursal = i.item_sucursal AND f.fact_numero = i.item_numero)
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY SUM(i.item_cantidad * i.item_precio) DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*13. Realizar una consulta que retorne para cada producto que posea composición nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
de los productos que lo componen. Solo se deberán mostrar los productos que estén
compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.*/

SELECT p.prod_codigo, p.prod_detalle, p.prod_precio, SUM(com.prod_precio * c.comp_cantidad)
FROM Producto p
	JOIN Composicion c ON (c.comp_producto = p.prod_codigo)
	JOIN Producto comp ON (comp.prod_codigo = c.comp_componente)
GROUP BY p.prod_detalle, p.prod_precio
HAVING SUM(c.comp_cantidad) > 2
ORDER BY SUM(c.comp_cantidad) DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*14. Escriba una consulta que retorne una estadística de ventas por cliente. 
Los campos que debe retornar son:
- Código del cliente
-Cantidad de veces que compro en el último año
-Promedio por compra en el último año
-Cantidad de productos diferentes que compro en el último año
-Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna
*/

SELECT f.fact_cliente,
	   COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero),
	   AVG(f.fact_total),
	   COUNT(DISTINCT i.item_producto),
	   MAX(f.fact_total)
FROM Factura f JOIN Item_Factura i
		ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)		
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY f.fact_cliente
ORDER BY 2 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:

PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1718 PHILIPS MORRIS KS 507
1718 PHILIPS MORRIS KS 1705 PHILIPS MORRIS BOX 10562*/

--retornar los pares de productos que se vendieron juntos en la misma factura y mas de 500 veces
--se debe mostrar prod_codigo, prod_detalle, cantidad de veces que fueron vendidos juntos (SUM de eso)
--resultado ordenado por cantidad de veces que se vendieron, es decir, de mayor a menor
--los pares no deben ser retornados mas de una vez


SELECT p1.prod_codigo, p1.prod_detalle,p2.prod_codigo, p2.prod_detalle, COUNT(*)
FROM Producto p1 
	JOIN Item_Factura i1 ON (p1.prod_codigo = i1.item_producto), 
	Producto p2 JOIN Item_Factura i2 ON (p2.prod_codigo = i2.item_producto)
WHERE i1.item_tipo + i1.item_sucursal + i1.item_numero = i2.item_tipo + i2.item_sucursal + i2.item_numero
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY 5 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.*/


SELECT c.clie_razon_social,
	   COUNT(i.item_producto),
	   (SELECT TOP 1 item_producto 
		FROM Item_Factura JOIN Factura ON (item_tipo + item_numero +  item_sucursal = fact_tipo + fact_numero + fact_sucursal)
		WHERE c.clie_codigo = fact_cliente AND YEAR(fact_fecha) = 2012
		GROUP BY item_producto
		ORDER BY COUNT(item_producto) DESC, item_producto ASC) AS prod_mas_vendido
FROM Cliente c 
	 JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
	 JOIN Item_Factura i ON (item_tipo + item_numero +  item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal)
WHERE f.fact_total > (SELECT TOP 1 AVG(item_precio)
					  FROM Item_Factura JOIN Factura ON (item_tipo + item_numero +  item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal)
					  WHERE YEAR(fact_fecha) = 2012
					  ORDER BY COUNT (*) DESC ) /3
					  AND YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_razon_social, c.clie_codigo
ORDER BY c.clie_codigo DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM
PROD: Código de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.*/

SELECT (YEAR(f.fact_fecha) ++ MONTH(f.fact_fecha)) AS periodo ,
		p.prod_codigo, 
		p.prod_detalle,
		SUM(i.item_cantidad),
		ISNULL((
		SELECT SUM(item_cantidad)
		FROM Item_Factura
			 JOIN Factura
				ON (item_tipo + item_numero +  item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal)
		WHERE YEAR(fact_fecha) = (YEAR(f.fact_fecha)-1) AND MONTH(fact_fecha) = MONTH(f.fact_fecha) AND p.prod_codigo = item_producto
		),0) AS cantidad_vendida,
		COUNT(f.fact_tipo + f.fact_sucursal + f.fact_numero)
FROM Producto p 
	JOIN Item_Factura i ON (i.item_producto = p.prod_codigo)
	JOIN Factura f ON (item_tipo + item_numero +  item_sucursal = f.fact_tipo + f.fact_numero + f.fact_sucursal)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY periodo DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/

SELECT r.rubr_detalle,
	   r.rubr_id,
	   SUM(i.item_cantidad * i.item_precio),
	   ISNULL((SELECT TOP 1 item_producto
		FROM Producto JOIN Item_Factura ON (prod_codigo = item_producto)
		WHERE r.rubr_id = prod_rubro
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC),0) AS prod1_mas_vendido,
	   ISNULL((SELECT TOP 1 item_producto
		FROM Producto JOIN Item_Factura ON (prod_codigo = item_producto)
		WHERE r.rubr_id = prod_rubro AND prod_codigo <> (
									SELECT TOP 1 item_producto
									FROM Producto JOIN Item_Factura ON (item_producto = prod_codigo)
									WHERE r.rubr_id = prod_rubro
									GROUP BY item_producto
									ORDER BY SUM(item_cantidad)DESC)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC),0) AS prod1_mas_vendido,
		ISNULL((SELECT TOP 1 fact_cliente
		FROM Producto 
			JOIN Item_Factura ON item_producto = prod_codigo 
			JOIN Factura ON (item_tipo + item_numero +  item_sucursal = fact_tipo + fact_numero + fact_sucursal)
		WHERE prod_rubro = r.rubr_id AND fact_fecha > DATEADD(DAY,-30,(SELECT MAX(fact_fecha) FROM Factura))--
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		),'-')
FROM Rubro r JOIN Producto p ON (r.rubr_id = p.prod_rubro) JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
GROUP BY r.rubr_detalle,R.rubr_id
ORDER BY COUNT(DISTINCT i.item_producto)	   

/*----------------------------------------------------------------------------------------------------------------------*/

/*19. En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto
- Detalle del producto
- Codigo de la familia del producto
- Detalle de la familia actual del producto
- Codigo de la familia sugerido para el producto
- Detalle de la familia sugerido para el producto

La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.

En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. 

Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida

Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

--Universo: Familia, Producto
--Elementos: p.prod_codigo, p.prod_detalle, f.fami_id (p.prod_familia = f.fami_id), f.fami_detalle (actual del producto), fami_id y fami_detalle sugeridos 
--Condicion: FAMILIA SUGERIDA -> posee la mayoria de los productos cuyo prod_detalle coinciden en los primeros 5 caracteres (sugerir la de menor codigo)
--Resultados: mostrar productos con familia actual diferente de la sugerida

SELECT  p.prod_codigo, 
		p.prod_detalle, 
		f.fami_id, 
		f.fami_detalle,
	   (SELECT TOP 1 prod_familia
		FROM Producto
		WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(p.prod_detalle, 1, 5)
		GROUP BY prod_familia
		ORDER BY COUNT(*),prod_familia) AS fami_cod_sugerida,
	   (SELECT fami_detalle
		FROM Familia
		WHERE fami_id = (SELECT TOP 1 prod_familia
		FROM Producto
		WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(p.prod_detalle, 1, 5)
		GROUP BY prod_familia
		ORDER BY COUNT (*),prod_familia)) AS fami_detalle_sugerida
FROM Producto p JOIN Familia f  ON (p.prod_familia = f.fami_id)
WHERE f.fami_id !=  (SELECT fami_detalle
					FROM Familia
					WHERE fami_id = (SELECT TOP 1 prod_familia
					FROM Producto
					WHERE SUBSTRING(prod_detalle, 1, 5) = SUBSTRING(p.prod_detalle, 1, 5)
					GROUP BY prod_familia
					ORDER BY COUNT (*),prod_familia))
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle ASC

/*No se si esta bien*/

/*----------------------------------------------------------------------------------------------------------------------*/

/*20. Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. 
El puntaje de cada empleado se calculara de la siguiente manera: 
- para los que hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año
-para los que tengan menos de 50 facturas en el año el calculo del puntaje sera el 50% de cantidad de 
facturas realizadas por sus subordinados directos en dicho año.*/

/*
Universo: empleado,
Condicion: 3 mejores empleados de 2012 (puntaje mas alto digamos)
--Elementos: empl_codigo, empl_nombre, empl_apellido, empl_ingreso, () as puntaje2011, () as puntaje2012
*/


SELECT e.empl_codigo, 
	   e.empl_nombre, 
	   e.empl_apellido, 
	   e.empl_ingreso, 
	   CASE 
	   WHEN(SELECT COUNT(fact_vendedor)
			FROM Factura
			WHERE e.empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2011 AND COUNT(fact_vendedor) >= 50)
	   THEN(SELECT COUNT(*)
			FROM Factura
			WHERE fact_total > 100 AND e.empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2011)
	   ELSE(SELECT COUNT(*) * 0.5 
			FROM Factura
			WHERE fact_vendedor IN(SELECT empl_codigo
								   FROM Empleado
								   WHERE empl_jefe = e.empl_codigo)
								AND YEAR(fact_fecha) = 2011)
	   END AS puntaje2011,
	   CASE 
	   WHEN(SELECT COUNT(fact_vendedor)
			FROM Factura
			WHERE e.empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2012 AND COUNT(fact_vendedor) >= 50)
	   THEN(SELECT COUNT(*)
			FROM Factura
			WHERE fact_total > 100 AND e.empl_codigo = fact_vendedor AND YEAR(fact_fecha) = 2012)
	   ELSE(SELECT COUNT(*) * 0.5 
			FROM Factura
			WHERE fact_vendedor IN(SELECT empl_codigo
								   FROM Empleado
								   WHERE empl_jefe = e.empl_codigo)
								AND YEAR(fact_fecha) = 2012)
		END AS puntaje2012
FROM Empleado e
ORDER BY 6 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. 

Se considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. 

Las columnas que se deben mostrar
son:
- Año
- Clientes a los que se les facturo mal en ese año
- Facturas mal realizadas en ese año*/


/*
Universo: Factura, Cliente
Elementos: YEAR(fact_fecha), , COUNT(SELECT fact_total, fact_total_impuestos
									 FROM Factura
									 WHERE (fact_total - fact_total_impuestos) > ())
Condicion: todos los años en los cuales se facturo a un cliente de manera incorrecta

--PODRIAS PONER UN DISTICT EN EL COUNT DE LAS FACTURAS Y JOINER CON ITEMS SIN LA SUBCONSULTA
*/
--forma 1
select YEAR(fact_fecha), count(distinct fact_cliente) as cantidad_clientes, count(*) as cantidad_facturas
from Factura
where fact_tipo+fact_sucursal+fact_numero in   (select fact_tipo+fact_sucursal+fact_numero
												from Factura
												join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero 
												group by fact_tipo+fact_sucursal+fact_numero, fact_total, fact_total_impuestos
												having ((fact_total-fact_total_impuestos) - sum(item_precio * item_cantidad)) > 1 
												or ((fact_total-fact_total_impuestos) - sum(item_precio * item_cantidad)) < -1)
group by YEAR(fact_fecha)

--forma 2
SELECT YEAR(fact_fecha) AS [AÑO]
		,COUNT(DISTINCT F.fact_cliente) AS [Clientes mal facturados]
		,COUNT(DISTINCT F.fact_tipo + F.fact_sucursal + F.fact_numero) AS [FACTURAS MAL REALIZADAS]
FROM FACTURA F
WHERE (F.fact_total-F.fact_total_impuestos) NOT BETWEEN (
												SELECT SUM(item_cantidad * item_precio)-1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
												AND
												(
												SELECT SUM(item_cantidad * item_precio)+1
												FROM Item_Factura
												WHERE item_numero+item_sucursal+item_tipo = F.fact_numero+F.fact_sucursal+F.fact_tipo
												)
GROUP BY YEAR(fact_fecha)


--las dos dan lo mismo. Solo tres valores

/*----------------------------------------------------------------------------------------------------------------------*/

/*22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.
*/

SELECT r.rubr_detalle, 
	   CASE
			WHEN (MONTH(fact_fecha)= 1 OR MONTH(fact_fecha)= 2 OR MONTH(fact_fecha)= 3)
			THEN 1
			WHEN (MONTH(fact_fecha)= 4 OR MONTH(fact_fecha)= 5 OR MONTH(fact_fecha)= 6)
			THEN 2
			WHEN(MONTH(fact_fecha)= 7 OR MONTH(fact_fecha)= 8 OR MONTH(fact_fecha)= 9)
			THEN 3
			ELSE 4
			END AS num_trimestre,
		COUNT(DISTINCT f.fact_tipo + f.fact_numero + f.fact_sucursal) AS cant_fact_trimestre,
		COUNT(DISTINCT i.item_producto ) AS prod_rubr_trimestre
FROM Rubro r 
	JOIN Producto p ON (r.rubr_id = p.prod_rubro)
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)  
--al hacer nuestros joins, hicimos que se reduciera nuestro universo, unicamente trabajando con los productos y facturas de un mismo rubro
WHERE p.prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
GROUP BY r.rubr_detalle, CASE
							WHEN (MONTH(fact_fecha)= 1 OR MONTH(fact_fecha)= 2 OR MONTH(fact_fecha)= 3)
							THEN 1
							WHEN (MONTH(fact_fecha)= 4 OR MONTH(fact_fecha)= 5 OR MONTH(fact_fecha)= 6)
							THEN 2
							WHEN(MONTH(fact_fecha)= 7 OR MONTH(fact_fecha)= 8 OR MONTH(fact_fecha)= 9)
							THEN 3
							ELSE 4
							END
HAVING COUNT(DISTINCT f.fact_tipo+ f.fact_numero+ f.fact_sucursal) > 100
ORDER BY 1,3 DESC


/*----------------------------------------------------------------------------------------------------------------------*/

/*23. Realizar una consulta SQL que para cada año muestre :
 Año
 El producto con composición más vendido para ese año.
 Cantidad de productos que componen directamente al producto más vendido
 La cantidad de facturas en las cuales aparece ese producto.
 El código de cliente que más compro ese producto.
 El porcentaje que representa la venta de ese producto respecto al total de venta
del año.

El resultado deberá ser ordenado por el total vendido por año en forma descendente.*/

SELECT YEAR(F1.fact_fecha)
	,IFACT1.item_producto --la razon porque este no lo desarrolla aca es porque el resto de los item depende de el, entonces no se podria usar si estuviera aca desarrollado
	,(
		SELECT COUNT(*)
		FROM Producto Prod
			INNER JOIN Composicion C
				ON C.comp_producto = Prod.prod_codigo
			INNER JOIN Producto Componente
				ON Componente.prod_codigo = C.comp_componente
		WHERE Prod.prod_codigo = IFACT1.item_producto
	) AS [Productos que componen el mas vendido]
	,(
		SELECT COUNT(DISTINCT F.fact_numero+F.fact_sucursal+F.fact_tipo)
		FROM Factura F
			INNER JOIN Item_Factura IFACT
				ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
			INNER JOIN Producto Prod
				ON Prod.prod_codigo = IFACT.item_producto
			INNER JOIN Composicion C
				ON C.comp_producto = Prod.prod_codigo
		WHERE Prod.prod_codigo = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
	) AS [Cantidad de facturas]
	,(
		SELECT TOP 1 F.fact_cliente
		FROM Factura F
			INNER JOIN Item_Factura IFACT
				ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
		WHERE IFACT.item_producto = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
		GROUP BY F.fact_cliente
		ORDER BY SUM(IFACT.item_cantidad) DESC
	)
	,(
		SELECT ( SUM(IFACT.item_cantidad) /
					(
						SELECT TOP 1 SUM(item_cantidad)
						FROM Item_Factura
							INNER JOIN Factura
								ON fact_numero = item_numero AND fact_tipo = item_tipo AND fact_sucursal = item_sucursal
						WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
					) *100
					
				)
		FROM Factura F
			INNER JOIN Item_Factura IFACT
				ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
		WHERE IFACT.item_producto = IFACT1.item_producto AND YEAR(F.fact_fecha) = YEAR(F1.fact_fecha)
	)
FROM Factura F1
	INNER JOIN Item_Factura IFACT1
		ON F1.fact_tipo = IFACT1.item_tipo AND F1.fact_numero = IFACT1.item_numero AND F1.fact_sucursal = IFACT1.item_sucursal
WHERE IFACT1.item_producto = (
								SELECT TOP 1 P.prod_codigo
								FROM Producto P
									INNER JOIN Composicion C
										ON C.comp_producto = P.prod_codigo
									INNER JOIN Item_Factura IFACT
										ON IFACT.item_producto = P.prod_codigo
									INNER JOIN Factura F
										ON F.fact_tipo = IFACT.item_tipo AND F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal
								WHERE YEAR(F1.fact_fecha) = YEAR(F.fact_fecha)
								ORDER BY (IFACT.item_producto * IFACT.item_cantidad) DESC
							)						
GROUP BY YEAR(F1.fact_fecha),IFACT1.item_producto
ORDER BY SUM(IFACT1.item_cantidad) DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*24. Escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composición
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
 Código de Producto
 Nombre del Producto
 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.*/


--facturas de los dos vendedores con mayores comisiones
--retornar solo los productos con composicion facturados al menos en cinco facturas
--Elementos a retornar: prod_codigo, prod_detalle, 
--ordenar por unidades facturadas descendente


SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) AS und_facturadas
FROM Producto p 
	JOIN Composicion c ON (p.prod_codigo = c.comp_producto) 
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (item_numero + item_sucursal + item_tipo = f.fact_numero + f.fact_sucursal + f.fact_tipo)
WHERE f.fact_vendedor IN (SELECT TOP 2 empl_codigo
						  FROM Empleado
						  ORDER BY empl_comision DESC)
GROUP BY p.prod_codigo, p.prod_detalle
HAVING COUNT(i.item_producto) > 5
ORDER BY 3 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*25. Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El código de cliente que más compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del año.

El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.*/

SELECT YEAR(F.fact_fecha)
	,FAM.fami_id
	,COUNT(DISTINCT P.prod_rubro)
	,CASE 
		WHEN(
				(
		SELECT TOP 1 prod_codigo
		FROM Producto
			INNER JOIN Item_Factura
				ON item_producto = prod_codigo
			INNER JOIN Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad) DESC
		) IN (
		
				SELECT comp_producto
				FROM Composicion
			)
		)
		THEN (
				SELECT COUNT(*)
				FROM Composicion
				WHERE comp_producto = (
										SELECT TOP 1 prod_codigo
										FROM Producto
											INNER JOIN Item_Factura
												ON item_producto = prod_codigo
											INNER JOIN Factura
												ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
										WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
										GROUP BY prod_codigo
										ORDER BY SUM(item_cantidad) DESC
										)
		)
		ELSE 1
	END
	,COUNT(DISTINCT F.fact_tipo + F.fact_numero + F.fact_sucursal)
	,(
		SELECT TOP 1 fact_cliente
		FROM Factura
			INNER JOIN Item_Factura
				ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
			INNER JOIN Producto	
				ON prod_codigo = item_producto
		WHERE prod_familia = FAM.fami_id AND YEAR(fact_fecha) = YEAR(F.fact_fecha)
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		) AS [CLIENTE QUE MAS COMPRO DE LA FAMILIA]
	,(SUM(IFACT.item_cantidad*IFACT.item_precio) *100) / (
													SELECT SUM(item_cantidad * item_precio)
													FROM Factura
														INNER JOIN Item_Factura
															ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
														INNER JOIN Producto	
															ON prod_codigo = item_producto
													WHERE YEAR(fact_fecha) = YEAR(F.fact_fecha)
													) AS [PORCENTAJE VENDIDO POR FAMILIA VS TOTAL ANUAL]
FROM FAMILIA FAM
	INNER JOIN Producto P
		ON P.prod_familia = FAM.fami_id
	INNER JOIN Rubro R
		ON R.rubr_id = P.prod_rubro
	INNER JOIN Item_Factura IFACT
		ON IFACT.item_producto = P.prod_codigo
	INNER JOIN Factura F
		ON  F.fact_numero = IFACT.item_numero AND F.fact_sucursal = IFACT.item_sucursal AND F.fact_tipo = IFACT.item_tipo

WHERE FAM.fami_id = (
						SELECT TOP 1 prod_familia
						FROM Producto
							INNER JOIN Item_Factura
								ON item_producto = prod_codigo
							INNER JOIN Factura
								ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
						GROUP BY prod_familia
						ORDER BY SUM(item_cantidad) DESC
						)

GROUP BY YEAR(F.fact_fecha),FAM.fami_id
ORDER BY SUM(IFACT.item_cantidad * IFACT.item_precio) DESC, 2


/*----------------------------------------------------------------------------------------------------------------------*/
 
/*26. Escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
- Empleado
- Depósitos que tiene a cargo
- Monto total facturado en el año corriente
- Codigo de Cliente al que mas le vendió
- Producto más vendido
- Porcentaje de la venta de ese empleado sobre el total vendido ese año.

Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

SELECT e.empl_codigo,
	   COUNT(DISTINCT d.depo_codigo) AS depost_cargo,
	   (SELECT SUM (fact_total)
		FROM Factura
		WHERE fact_vendedor = e.empl_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha)) AS monto_total_factura,
		(SELECT TOP 1 fact_cliente
		FROM Factura
		WHERE fact_vendedor = e.empl_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY fact_cliente
		ORDER BY SUM(fact_total) DESC) AS cod_cliente_mas_vendio,
		(SELECT TOP 1 item_producto
		FROM Item_Factura
			JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE fact_vendedor = e.empl_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC) AS prod_mas_vendido,
		((SELECT SUM(fact_total)
		FROM Factura
		WHERE fact_vendedor = e.empl_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha))*100) / 
		(SELECT SUM(fact_total)
		 FROM Factura
		 WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)) AS PORC_VENTAS_EMPL
FROM Empleado e
	LEFT OUTER JOIN DEPOSITO d ON (d.depo_encargado = e.empl_codigo)
	LEFT OUTER JOIN Factura f ON (f.fact_vendedor = e.empl_codigo)
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY e.empl_codigo, YEAR(f.fact_fecha)
ORDER BY 3 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
- Año 
- Codigo de envase
- Detalle del envase
- Cantidad de productos que tienen ese envase 
- Cantidad de productos facturados de ese envase
- Producto mas vendido de ese envase
- Monto total de venta de ese envase en ese año
- Porcentaje de la venta de ese envase respecto al total vendido de ese año

Orden:
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor*/

--Universo Envases, Producto, Item_Factura, Factura

SELECT YEAR(f.fact_fecha),
	   e.enva_codigo,
	   e.enva_detalle,
	   COUNT(DISTINCT i.item_producto) AS cant_prod_del_envase,
	   SUM(i.item_cantidad) AS prod_facturados_envase,
	   (SELECT TOP 1 item_producto
		FROM Item_Factura 
			 JOIN Producto ON (item_producto = prod_codigo)
			 JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE prod_envase = e.enva_codigo  AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY item_producto
		ORDER BY SUM(item_cantidad) DESC) AS prod_mas_vendido,
		SUM(i.item_precio * i.item_cantidad) AS monto_total_año,
		SUM(i.item_precio * i.item_cantidad)*100 / 
		(SELECT SUM(fact_total)
		 FROM Factura
		 WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)) AS porct_vendido_año
FROM Producto p
	JOIN Envases e ON (p.prod_envase = e.enva_codigo)
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_sucursal + f.fact_tipo)
GROUP BY YEAR(f.fact_fecha),e.enva_codigo, e.enva_detalle
ORDER BY 1, 5 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*28. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
- Año.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realizó en ese año
- Cantidad de clientes a los cuales les vendió en ese año.
- Cantidad de productos facturados con composición en ese año
- Cantidad de productos facturados sin composicion en ese año. (PARA INDICAR QUE NO ES UTILIZAMOS EL NOT IT Y PONEMOS EN PARENTESIS TABLA A LA CUAL NO PERTENECE)
- Monto total vendido por ese vendedor en ese año

Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/


--Universo: Factura, Empleado

SELECT YEAR(f.fact_fecha) AS anio,
	   f.fact_vendedor,
	   e.empl_nombre,
	   e.empl_apellido,
	   COUNT(DISTINCT f.fact_tipo + f.fact_numero + f.fact_sucursal) AS fact_realizadas,
	   COUNT(DISTINCT f.fact_cliente) AS clientes_vendidos,
	   (SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			 JOIN Composicion ON (prod_codigo = comp_producto)
			 JOIN Item_Factura ON (prod_codigo = item_producto)
			 JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = f.fact_vendedor) AS cant_prod_fact_comp,
	   (SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			 JOIN Item_Factura ON (prod_codigo = item_producto)
			 JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = f.fact_vendedor AND prod_codigo NOT IN (SELECT comp_producto FROM Composicion)) AS cant_prod_fact_comp,
		SUM(f.fact_total) AS monto_total
FROM Factura f
	JOIN Empleado e ON (f.fact_vendedor = e.empl_codigo)
GROUP BY YEAR(f.fact_fecha),f.fact_vendedor,e.empl_nombre, e.empl_apellido
ORDER BY 1 DESC, (SELECT COUNT(DISTINCT prod_codigo)
				  FROM Producto
					JOIN Item_Factura ON (item_producto = prod_codigo)
					JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
				  WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = f.fact_vendedor) DESC


/*----------------------------------------------------------------------------------------------------------------------*/

/*29. Se solicita que realice una estadística de venta por producto para el año 2011, solo para
los productos que pertenezcan a las familias que tengan más de 20 productos asignados
a ellas, la cual deberá devolver las siguientes columnas:

a. Código de producto
b. Descripción del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto

Solo se deberá mostrar un producto por fila en función a los considerandos establecidos
antes. GROUP BY prod_codigo, prod_detalle

El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor. ORDER BY 3 DESC*/

--Universo: Producto, Factura, Item_Factura

SELECT p.prod_codigo,
	   p.prod_detalle,
	   COUNT(DISTINCT i.item_cantidad) AS cant_vendida,
	   COUNT(DISTINCT f.fact_tipo + f.fact_sucursal + f.fact_numero) AS cant_facturas_del_producto,
	   SUM(i.item_cantidad * i.item_precio) AS monto_total_producto
FROM Producto p
	JOIN Familia fa ON (p.prod_familia = fa.fami_id)
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (i.item_numero + i.item_sucursal + i.item_tipo = f.fact_numero + f.fact_sucursal + f.fact_tipo)
WHERE YEAR(f.fact_fecha) = 2011 
GROUP BY prod_codigo, prod_detalle, fa.fami_id
HAVING (SELECT COUNT(DISTINCT prod_codigo)
		FROM Producto
			JOIN Familia ON (prod_familia = fami_id)
		WHERE fami_id = fa.fami_id
		GROUP BY fami_id) > 20
ORDER BY 3 DESC

/*----------------------------------------------------------------------------------------------------------------------*/

/*30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:

- Nombre del Jefe
- Cantidad de empleados a cargo
- Monto total vendido de los empleados a cargo
- Cantidad de facturas realizadas por los empleados a cargo
- Nombre del empleado con mejor ventas de ese jefe

Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.

Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.*/	


--Universo: Empleado, Factura, Item_Factura


SELECT e.empl_nombre AS jefe_nombre,
	   e.empl_apellido AS jefe_apellido,
	   COUNT(DISTINCT em.empl_codigo) AS cant_empleados,
	   SUM(f.fact_total) AS monto_total_vendido,
	   COUNT(f.fact_vendedor) AS fact_realizadas_empl,
	   (SELECT TOP 1 empl_codigo
		FROM Empleado
			JOIN Factura ON (empl_codigo = fact_vendedor)
		WHERE empl_jefe = e.empl_codigo AND YEAR(fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY empl_codigo
		ORDER BY SUM(fact_total) DESC) AS empl_mejor_venta
FROM Empleado e 
	JOIN Empleado em ON (e.empl_codigo = em.empl_jefe)
	JOIN Factura f ON (em.empl_codigo = f.fact_vendedor)
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY e.empl_nombre, e.empl_apellido, e.empl_codigo, YEAR(f.fact_fecha)
HAVING COUNT(f.fact_tipo + f.fact_numero + f.fact_sucursal) > 10
ORDER BY 4 DESC  

/*----------------------------------------------------------------------------------------------------------------------*/

/*31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
- Año.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realizó en ese año
- Cantidad de clientes a los cuales les vendió en ese año.
- Cantidad de productos facturados con composición en ese año
- Cantidad de productos facturados sin composicion en ese año.
- Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/


--Universo:
SELECT YEAR(f.fact_fecha) AS anio,
	   f.fact_vendedor AS cod_vendedor,
	   e.empl_nombre,
	   e.empl_apellido,
	   COUNT(f.fact_numero + f.fact_tipo + f.fact_sucursal) AS cantidad_fact_anio,
	   COUNT (f.fact_cliente) AS cantidad_clientes_anio,
	   (SELECT COUNT(prod_codigo)
	    FROM Producto 
			JOIN Composicion ON (prod_codigo = comp_producto)
			JOIN Item_Factura ON (prod_codigo = item_producto)
			JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = f.fact_vendedor) AS prod_fact_comp,
		(SELECT COUNT(prod_codigo)
		 FROM Producto
			JOIN Item_Factura ON (prod_codigo = item_producto)
			JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND prod_codigo NOT IN (SELECT comp_producto FROM Composicion) AND fact_vendedor = f.fact_vendedor) AS prod_fact_no_comp,
		SUM(f.fact_total) AS monto_total
FROM Factura f 
	JOIN Empleado e ON (f.fact_vendedor = e.empl_codigo)
GROUP BY YEAR(f.fact_fecha), f.fact_vendedor, e.empl_nombre, e.empl_apellido
ORDER BY 1 DESC, (SELECT COUNT(DISTINCT prod_codigo)
				  FROM Producto
					JOIN Item_Factura ON (item_producto = prod_codigo)
					JOIN Factura ON (item_numero + item_sucursal + item_tipo = fact_numero + fact_sucursal + fact_tipo)
				  WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND fact_vendedor = f.fact_vendedor) DESC

/*----------------------------------------------------------------------------------------------------------------------*/

