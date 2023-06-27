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

SELECT YEAR(f.fact_fecha) AS anio,
       z.zona_codigo,
       z.zona_detalle,
       COUNT(d.depa_codigo) AS cant_dep_zona,
       COUNT(e.empl_codigo) AS cant_empl_zona,
       (SELECT TOP 1 empl_codigo 
        FROM Empleado
            JOIN Departamento ON (empl_departamento = depa_codigo) 
            JOIN Zona ON (depa_zona = zona_codigo)
            JOIN Factura ON (empl_codigo = fact_vendedor) 
        WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha) AND zona_codigo = z.zona_codigo
        GROUP BY fact_vendedor
        ORDER BY SUM(fact_total) DESC) AS empl_mas_vendio,
        ISNULL(SUM(f.fact_total), 0) AS monto_total,
        (SELECT SUM(f.fact_total) / (SELECT TOP 1 SUM(fact_total)
                                      FROM Factura
                                      WHERE YEAR(fact_total) = YEAR(f.fact_fecha)) * 100) AS porcentaje
FROM Factura f
    JOIN Empleado e ON (f.fact_vendedor = e.empl_codigo)
    JOIN Departamento d ON (e.empl_departamento = d.depa_codigo)
    JOIN Zona z ON (d.depa_zona = z.zona_codigo)
GROUP BY YEAR(f.fact_fecha), z.zona_codigo, z.zona_detalle
ORDER BY YEAR(f.fact_fecha) ASC, SUM(f.fact_total) DESC


/*--------------------------------------------------------------------------------------------------------------------------------------*/
/*1) realizar una consulta SQL que retorne todos los años en donde en mas de 10 facturas
se vendieron juntos los producto 1 y 3. Tambien informar para ese año, el monto total facturado*/

SELECT YEAR(F.fact_fecha),SUM(F.fact_total) FROM Factura F
	JOIN Item_Factura it ON it.item_numero=F.fact_numero
	JOIN Item_Factura it2 ON it2.item_numero=F.fact_numero
WHERE it.item_producto='00001420' AND  it2.item_producto='00001415'
GROUP BY YEAR(F.fact_fecha)
HAVING COUNT(F.fact_numero) > 10

/*--------------------------------------------------------------------------------------------------------------------------------------*/
--PARCIAL 12-11-2019

/*1) Universo: Estadistica de ventas especiales.
Condicion: La factura es especial si tiene mas de 1 producto con composicion vendido.
Elementos a mostrar: Year, cant_fact, total_facturado_especial, porc_especiales, max_factura, monto_total_vendido
porc_especiales, monto_total_vendido
Order: cant_fact DESC, monto_total_vendido DESC
*/

SELECT YEAR(f.fact_fecha) AS anio,
	   COUNT(f.fact_tipo + f.fact_sucursal + f.fact_numero) AS cant_fact,
	   SUM(f.fact_total) AS total_facturado_especial,
	   (SUM(f.fact_total) * 100 / (SELECT SUM(f2.fact_total)
								   FROM Factura f2
								   WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha))) AS porc_especiales,
	   MAX(f.fact_total) AS max_monto_factura
FROM Factura f
WHERE f.fact_tipo + f.fact_sucursal + f.fact_numero IN (SELECT f3.fact_tipo + f3.fact_sucursal + f3.fact_numero
														FROM Factura f3
															JOIN Item_Factura i ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
															JOIN Producto p ON (i.item_producto = p.prod_codigo)
															JOIN Composicion c ON (p.prod_codigo = c.comp_producto)
														GROUP BY fact_tipo+fact_sucursal+fact_numero
														HAVING COUNT(DISTINCT(comp_producto)) > 1)
GROUP BY YEAR(f.fact_fecha)
ORDER BY 2 DESC, 4 DESC


/*--------------------------------------------------------------------------------------------------------------------------------------*/
--PARCIAL 2020

/*1) Armar una consulta que muestre para todos los productos:

Producto

Detalle del producto

Detalle composición (si no es compuesto un string “SIN COMPOSICION”,, si es compuesto un string “CON COMPOSICION”

Cantidad de Componentes (si no es compuesto, tiene que mostrar 0)

Cantidad de veces que fue comprado por distintos clientes

Nota: No se permiten sub select en el FROM.*/

SELECT p.prod_codigo,
	   p.prod_detalle,
	   (SELECT CASE
		WHEN ((SELECT comp_producto FROM Composicion JOIN Producto p1 on comp_producto = p1.prod_codigo where comp_producto = p.prod_codigo) <> NULL) 
		THEN 'CON COMPOSICIÓN'
		ELSE 'SIN COMPOSICIÓN'
		END) AS comp_detalle,
	   ISNULL((SELECT COUNT(comp_componente)
			   FROM Composicion 
			   WHERE comp_producto = p.prod_codigo),0)  AS cant_componentes,
	   COUNT (DISTINCT f.fact_cliente) AS cant_compras_clientes
FROM Producto p
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY 1 DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--EJERCICIOS DE PARCIALES VARIOS

/*se requiere mostrar los productos que sean componentes y 
que se hayan vendido en forma unitaria o a través del producto al cual compone, 
por ejemplo una hamburguesa se deberá mostrar si se vendió como hamburguesa y si se vendió un combo que está compuesto 
por una hamburguesa. 

Se deberá mostrar:

Código de producto, nombre de producto, cantidad de facturas vendidas solo, 
cantidad de facturas vendidas de los productos que compone, cantidad de productos a los cuales compone que se vendieron

El resultado deberá ser ordenado por el componente que se haya vendido solo en más facturas 

Aclaracion: se debe resolver en una sola consulta sin utilizar subconsultas en ningún lugar del Select 
*/

SELECT p.prod_codigo,
	   p.prod_detalle,
	   COUNT(DISTINCT i1.item_tipo + i1.item_sucursal + i1.item_numero),
	   COUNT(DISTINCT i2.item_tipo + i2.item_sucursal + i2.item_numero),
	   COUNT(DISTINCT i2.item_producto)
FROM Producto p
	JOIN Item_Factura i1 ON (p.prod_codigo = i1.item_producto)
	JOIN Composicion c ON (p.prod_codigo = c.comp_producto)
	JOIN Item_Factura i2 ON (p.prod_codigo = i2.item_producto)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY 3 DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/*
Mostrar considerando todos los depositos, los 10 depositos que tiene mayores unidades y los 10 depositos que menos unidades
tienen. Considerar que pueden tener depositos con stock 0 en todos sus productos.

En ambos casos mostrar: Producto que mayor cantidad tiene en el deposito (en unidades), en caso de tener 0, mostrar el string 
"sin deposito" */

SELECT d.depo_codigo,
	   d.depo_detalle,
	   ISNULL((SELECT TOP 1 prod_codigo
		FROM Producto
			JOIN STOCK ON (prod_codigo = stoc_producto) 
			JOIN DEPOSITO ON (stoc_deposito = depo_codigo)
		WHERE depo_codigo = d.depo_codigo
		GROUP BY prod_codigo
		ORDER BY SUM(stoc_cantidad) DESC ), 'Sin deposito') AS prod_mayor_cantidad
FROM DEPOSITO d 
	JOIN STOCK s ON (d.depo_codigo = s.stoc_deposito)
WHERE d.depo_codigo IN (SELECT TOP 10 stoc_deposito 
						FROM STOCK
						GROUP BY stoc_deposito
						ORDER BY SUM(stoc_cantidad) DESC)
	OR d.depo_codigo IN(SELECT TOP 10 stoc_deposito 
						FROM STOCK
						GROUP BY stoc_deposito
						ORDER BY SUM(stoc_cantidad) ASC)
GROUP BY d.depo_codigo, d.depo_detalle

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* Se solicita una estadistica por año y familia, para ello se debera mostrar:

Año, codigo de familia, detalle de la familia, cantidad de facturas, cantidad de productos con composicion vendidos, monto total vendido

Solo se deberan considerar las familias que tengan al menos un producto con composicion y que se haya vendido conjuntamente (en la misma
factura) con otra familia distinta
*/

SELECT YEAR(f1.fact_fecha),
	   fa1.fami_id,
	   fa1.fami_detalle,
	   COUNT(DISTINCT f1.fact_tipo + f1.fact_sucursal + f1.fact_numero),
	   (SELECT COUNT(prod_codigo)
		FROM Producto
		WHERE prod_codigo IN (SELECT comp_producto FROM Composicion)) AS prod_compuestos_vendidos,
		SUM(i1.item_cantidad * i1.item_precio) AS monto_total
FROM Factura f1 
	JOIN Item_Factura i1 ON (i1.item_tipo + i1.item_sucursal + i1.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero)
	JOIN Producto p1 ON (p1.prod_codigo = i1.item_producto)
	JOIN Familia fa1 ON (p1.prod_familia = fa1.fami_id),
	Factura f2
	JOIN Item_Factura i2 ON (i2.item_tipo + i2.item_sucursal + i2.item_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero)
	JOIN Producto p2 ON (p2.prod_codigo = i2.item_producto)
	JOIN Familia fa2 ON (p2.prod_familia = fa2.fami_id)
WHERE fa1.fami_id IN (SELECT prod_familia FROM Producto
					  WHERE prod_codigo IN (SELECT comp_producto FROM Composicion))
					  AND fa1.fami_id > fa2.fami_id
					  AND (i1.item_tipo + i1.item_sucursal + i1.item_numero) = (i2.item_tipo + i2.item_sucursal + i2.item_numero)
GROUP BY YEAR(f1.fact_fecha), fa1.fami_id, fa1.fami_detalle

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* Con el fin de analizar el posicionamiento de ciertos productos se necesita mostrar solo los 5 rubros de productos mas vendidos
y ademas, por cada uno de estos rubros saber cual es el producto mas exitoso (es decir, con mas ventas) y si el mismo es simple
o compuesto. Por otro lado se pide se indique si hay "stock disponible" o si hay "faltante" para afrontar las ventas del proximo
mes. Considerar que se estima que la venta aumente en un 10% respecto del mes de diciembre del año pasado
*/

SELECT r.rubr_id,
	   (SELECT TOP 1 prod_codigo
		FROM Producto
			JOIN Item_Factura ON (prod_codigo = item_producto)
		WHERE prod_rubro = r.rubr_id
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad * item_precio) DESC),
	   (CASE WHEN (SELECT TOP 1 prod_codigo
				    FROM Producto
						JOIN Item_Factura ON (prod_codigo = item_producto)
					WHERE prod_rubro = r.rubr_id
					GROUP BY prod_codigo
					ORDER BY SUM(item_cantidad * item_precio) DESC) IN (SELECT comp_producto FROM Composicion)
		THEN 'Producto Compuesto'
		ELSE 'Producto Simple'
		END),
	   (CASE WHEN (SELECT SUM(stoc_cantidad) FROM STOCK
				   WHERE stoc_producto = (SELECT TOP 1 prod_codigo FROM Producto
												JOIN Item_Factura ON item_producto = prod_codigo
										  WHERE prod_rubro = r.rubr_id
										  GROUP BY prod_codigo
								          ORDER BY SUM(item_cantidad*item_precio) DESC))
					 > (SELECT SUM(item_cantidad * item_precio) 
						FROM Item_Factura
							JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
						WHERE MONTH(fact_fecha) = 12 AND YEAR(fact_fecha) = (SELECT (MAX(YEAR(f2.fact_fecha))-1) FROM Factura f2)
							  AND item_producto =  (SELECT TOP 1 prod_codigo
													FROM Producto
														JOIN Item_Factura ON (prod_codigo = item_producto)
													WHERE prod_rubro = r.rubr_id
													GROUP BY prod_codigo
													ORDER BY SUM(item_cantidad * item_precio) DESC) * 1.1)
		THEN 'Stock disponible'
		ELSE 'Stock faltante'
		END)
FROM Rubro r 
WHERE r.rubr_id IN (SELECT TOP 5 prod_rubro
					FROM Producto
						JOIN Item_Factura ON (prod_codigo = item_producto)
					GROUP BY prod_rubro
					ORDER BY SUM(item_cantidad) DESC)

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* Mostrar las 5 zonas donde menor cantidad de ventas se están realizando en el año actual. 
Recordar que un empleado está puesto como fact_vendedor en factura. De aquellas zonas donde 
menores ventas tengamos, se deberá mostrar (cantidad de clientes distintos que operan en esa zona), 
cantidad de clientes que aparte de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). 
El resultado se deberá mostrar por cantidad de productos vendidos en la zona en cuestión de manera descendiente */

SELECT d.depa_zona,
	   COUNT(DISTINCT f.fact_cliente),
	   (SELECT COUNT(DISTINCT fact_cliente)
		FROM Factura 
			JOIN Empleado ON (fact_vendedor = empl_codigo)
			JOIN Departamento ON (empl_departamento = depa_codigo)
		WHERE depa_zona <> d.depa_zona)
FROM Factura f
	JOIN Empleado e ON (f.fact_vendedor = e.empl_codigo)
	JOIN Departamento D ON (e.empl_departamento = d.depa_codigo)
WHERE d.depa_zona IN (SELECT TOP 5 depa_zona
						FROM Factura
							JOIN Empleado ON (depa_codigo = empl_departamento)
							JOIN Departamento ON (empl_departamento = depa_codigo)
						WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(F2.fact_fecha)) FROM Factura F2)
						GROUP BY depa_zona
						ORDER BY COUNT(*))
GROUP BY d.depa_zona
ORDER BY (SELECT SUM(item_cantidad) 
		  FROM Item_Factura 
			JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
			JOIN Empleado ON (fact_vendedor = empl_codigo)
			JOIN Departamento ON (depa_codigo = empl_departamento)
		  WHERE depa_zona = d.depa_zona) DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--falta que me tire tres mas, solo llega a mostrar dos


/*
--Realizar una consulta que considerando solo las facturas en las cuales se vendieron productos con composicion y sin composicion muestre:

--Nombre de producto sin composicion, Nombre de producto con composicion, Cantidad de facturas, Monto facturado

--Aclaracion: no se deben repetir pares de productos en la consulta

--Nota: no subselect en el from
*/

SELECT p1.prod_detalle,
	   p2.prod_detalle,
	   COUNT(DISTINCT f1.fact_tipo + f1.fact_sucursal + f1.fact_numero),
	   SUM(f1.fact_total)
FROM Producto p1 
	JOIN Item_Factura i1 ON (p1.prod_codigo = i1.item_producto)
	JOIN Factura f1 ON (i1.item_producto + i1.item_sucursal + i1.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero),
	Producto p2
	JOIN Item_Factura i2 ON (p2.prod_codigo = i2.item_producto)
	JOIN Factura f2 ON (i2.item_producto + i2.item_sucursal + i2.item_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero)
WHERE f1.fact_tipo + f1.fact_sucursal + f1.fact_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero
	  AND p1.prod_codigo > p2.prod_codigo 
	  AND p1.prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
	  AND p2.prod_codigo IN (SELECT comp_producto FROM Composicion)
GROUP BY p1.prod_detalle, p2.prod_detalle

--NO ME DA RESULTADOS

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
La razon social de los 15 clientes que posean menor limite de credito, el promedio en $ de las compras realizadas por ese cliente
y que se indique un string"Compro productos compuestos" en caso de que alguno de todos los productos comprados tenga composicion.

-Considerar solo aquellos clientes que tengan alguna factura mayor a $350000 (fact_total).

-Se debera ordenar los resultados por el domicilio del cliente
*/

SELECT c.clie_razon_social,
	   AVG(f.fact_total),
	   (CASE WHEN(SELECT item_producto 
				  FROM Item_Factura
					JOIN Producto ON (item_producto = prod_codigo)
					JOIN Composicion ON (prod_codigo = comp_producto)
					JOIN Factura ON (item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero)
					WHERE fact_cliente = c.clie_codigo) IN (SELECT comp_producto FROM Composicion)
		THEN 'Compro productos compuestos'
		ELSE 'No compro productos compuestos'
		END)
FROM Cliente c
	JOIN Factura f ON (f.fact_cliente = c.clie_codigo)
WHERE c.clie_codigo IN (SELECT TOP 15 fact_cliente
						FROM Factura
						GROUP BY fact_cliente
						HAVING EXISTS(SELECT * from Factura WHERE fact_total > 350000 AND fact_cliente = c.clie_codigo)
						ORDER BY c.clie_limite_credito)
GROUP BY clie_codigo, clie_razon_social, clie_domicilio, clie_limite_credito
ORDER BY clie_domicilio

/*--------------------------------------------------------------------------------------------------------------------------------------*/
/*
Se necesita realizar una migración de los códigos de productos a una nueva codificación que va a ser
A + substring(prod_codigo,2,7). Implemente el/los objetos para llevar a cabo la migración.
Restricción a la solución: durante la migración no se podrá 
deshabilitar las contraints ni crear nuevas estructuras.
*/

CREATE PROCEDURE migrar_cod_productos
AS
BEGIN
	INSERT INTO Producto
	SELECT 'A' + SUBSTRING(p.prod_codigo,2,7),
			p.prod_detalle,
			p.prod_precio,
			p.prod_familia,
			p.prod_rubro,
			p.prod_envase
	FROM Producto p

	--cuando insertamos todo esto nuevo tenemos que actualizar lo que estaba antes para que no rompa
	UPDATE Composicion SET comp_producto = 'A' +SUBSTRING(comp_producto,2,7), comp_componente = 'A' + substring(comp_componente,2,7)

	UPDATE STOCK SET stoc_producto = 'A' + substring(stoc_producto,2,7)

	UPDATE Item_Factura SET item_producto = 'A' + substring(item_producto,2,7)
	
	DELETE FROM Producto WHERE SUBSTRING(prod_codigo,1,1) <> 'A'

END
GO 

/*--------------------------------------------------------------------------------------------------------------------------------------*/

--este es un parcial entero que estaba en el doc

/* Foto 1
La empresa esta muy comprometida con el desarrollos sustentable y como consecuencia de ello propone cambiar todos los envases de sus productos por envases 
reciclados. Si bien entiende la importancia de este cambio también es consciente de los costos que esto conlleva, por lo cual se realizará de manera paulatina.
 
Se solicita un listado con los 12 productos más vendidos y los 12 productos menos vendidos del último año. 
Comparar la cantidad vendidad de cada uno de estos productos con la cantidad vendida del año anterior e indicar 
el String 'Mas ventas' o 'Menos ventas', según corresponda. Además indicar el envase.
Nota: No se puede usar select en el from.
*/

SELECT p.prod_codigo,
	   (CASE WHEN SUM(i.item_cantidad) - (SELECT SUM(item_cantidad) 
										  FROM Item_Factura
											JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
										  WHERE YEAR(f.fact_fecha) - 1 = YEAR(fact_fecha) AND item_producto = p.prod_codigo) > 0
		THEN 'Mas ventas'
		ELSE 'Menos ventas'
		END),
		p.prod_envase
FROM Producto p
	JOIN Envases e ON (p.prod_envase = e.enva_codigo)
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)	   
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
	AND p.prod_codigo IN (SELECT TOP 12 item_producto 
						FROM Item_Factura
						GROUP BY item_producto
						ORDER BY SUM(item_cantidad) DESC)
	OR p.prod_codigo IN(SELECT TOP 12 item_producto 
						FROM Item_Factura
						GROUP BY item_producto
						ORDER BY SUM(item_cantidad) ASC)
GROUP BY p.prod_codigo, p.prod_envase, YEAR(f.fact_fecha)
ORDER BY SUM(item_cantidad) DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 4
Realizar una consulta SQL que retorne para todos los productos que se vendieron en 2 años consecutivos:
- Nombre de producto
- Cantidad de unidades vendidas en toda la historia

El resultado debera ser ordenado por precio unitario maximo vendido en la historia
*/

SELECT p.prod_detalle,
	   SUM(i.item_cantidad) AS cantidades_vendidas
FROM Producto p
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
	JOIN Factura f1 ON (i.item_tipo + i.item_sucursal + i.item_numero = f1.fact_tipo + f1.fact_sucursal + f1.fact_numero)
WHERE p.prod_codigo IN (SELECT prod_codigo 
						FROM Producto
							JOIN Item_Factura ON (prod_codigo = item_producto)
							JOIN Factura f2 ON (item_tipo + item_sucursal + item_numero = f2.fact_tipo + f2.fact_sucursal + f2.fact_numero)
						WHERE YEAR(f2.fact_fecha) = YEAR(f1.fact_fecha) 
							  AND prod_codigo IN (SELECT prod_codigo 
												  FROM Producto
													JOIN Item_Factura ON item_producto = prod_codigo
													JOIN Factura f3 ON f3.fact_numero + f3.fact_sucursal + f3.fact_tipo = item_numero + item_sucursal + item_tipo
												  WHERE YEAR(F1.fact_fecha) + 1 = YEAR(F3.fact_fecha)))
GROUP BY p.prod_detalle
ORDER BY MAX(i.item_precio)

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 6
Mostrar los dos empleados del mes, estos son:

a) El empleado que en el mes actual (en el cual se ejecuta la query) vendió más en dinero(fact_total).
b) El segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) vendió más cantidades (unidades de productos).

Se deberá mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 'MEJOR FACTURACION' y para el segundo
'VENDIÓ MÁS UNIDADES'.

NOTA: Si el empleado que más vendió en facturación y cantidades es el mismo, solo mostrar una fila que diga el empleado y 'MEJOR EN TODO'.
NOTA2: No se debe usar subselect en el from
*/

SELECT e.empl_apellido + ' ' + e.empl_nombre AS nombre_cliente,
	   (CASE
	   WHEN(e.empl_codigo IN (SELECT TOP 1 empl_codigo 
							  FROM Empleado
								JOIN Factura ON (empl_codigo = fact_vendedor)
							  WHERE MONTH(fact_fecha) = MONTH(GETDATE())
							  GROUP BY empl_codigo
							  ORDER BY SUM(fact_total) DESC)) 
	   THEN  'Mejor Facturacion'
	   WHEN(e.empl_codigo IN (SELECT TOP 1 empl_codigo
							  FROM Empleado
								JOIN Factura ON (empl_codigo = fact_vendedor)
								JOIN Item_Factura ON (fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero)
							  WHERE MONTH(fact_fecha) = MONTH(GETDATE())
							  GROUP BY empl_codigo
							  ORDER BY SUM(item_cantidad) DESC))
	   THEN 'Vendio mas unidades'
	   WHEN(e.empl_codigo IN (SELECT TOP 1 empl_codigo 
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
GROUP BY e.empl_nombre, e.empl_apellido, e.empl_codigo
HAVING e.empl_codigo IN (SELECT TOP 1 empl_codigo 
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
ORDER BY e.empl_codigo ASC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 7
Se pide realizar una consulta SQL que retorne POR CADA AÑO, el cliente que más compro (fact_total), 
la cantidad de artículos distintos comprados, la cantidad de rubros distintos comprados.
Solamente se deberán mostrar aquellos clientes que posean al menos 10 facturas o más por año.
El resultado debe ser ordenado por año.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el 
usuario para este punto.
*/

SELECT YEAR(f.fact_fecha),
	   (SELECT TOP 1 clie_codigo
		FROM Cliente
			JOIN Factura ON (clie_codigo = fact_cliente)
		WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)
		GROUP BY clie_codigo
		ORDER BY SUM(fact_total) DESC),
	   COUNT(DISTINCT i.item_producto),
	   COUNT(DISTINCT p.prod_rubro)
FROM Cliente c
	JOIN Factura f ON (f.fact_cliente = c.clie_codigo)
	JOIN Item_Factura i ON (i.item_tipo + i.item_sucursal + i.item_numero = f.fact_tipo + f.fact_sucursal + f.fact_numero)
	JOIN Producto p ON (i.item_producto = p.prod_codigo)
WHERE c.clie_codigo IN (SELECT clie_codigo 
						FROM Cliente
							JOIN Factura ON fact_cliente=clie_codigo
						GROUP BY clie_codigo
						HAVING COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) >= 10)
GROUP BY YEAR(f.fact_fecha)
ORDER BY YEAR(f.fact_fecha)

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 8 S2L
Se pide realizar una consulta SQL que retorne todos los clientes que tuvieron mas ventas
(cantidad de articulos vendidos) en el 2012 que en el 2011 y ademas mostraar
- codigo del cliente
- razon social
- cantidad de productos compuestos que vendio en 2019 (mepa q es 2011 o 2012)
El resultado debe ser ordenado por limite de credito del cliente de mayor a menor
*/

SELECT c.clie_codigo,
	   c.clie_razon_social,
	   COUNT(DISTINCT co.comp_producto)
FROM Cliente c
	JOIN Factura f ON (c.clie_codigo = f.fact_cliente)
	JOIN Item_Factura i ON (f.fact_tipo + f.fact_sucursal + f.fact_numero = i.item_tipo + i.item_sucursal + i.item_numero)
	JOIN Composicion co ON (i.item_producto = co.comp_producto)
WHERE (SELECT SUM(item_cantidad) 
	   FROM Item_Factura 
		JOIN Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
	   WHERE YEAR(fact_fecha) = 2012 AND fact_cliente= c.clie_codigo) > 
	   (SELECT SUM(item_cantidad) 
		FROM Item_Factura 
		 JOIN Factura ON fact_numero + fact_sucursal + fact_tipo = item_numero + item_sucursal + item_tipo
		WHERE YEAR(fact_fecha) = 2011 AND fact_cliente = c.clie_codigo) AND YEAR(f.fact_fecha) = 2011 --2019 no da nada, cambie por 2011
GROUP BY c.clie_codigo, c.clie_razon_social, c.clie_limite_credito, YEAR(f.fact_fecha)
ORDER BY c.clie_limite_credito DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* FOTO 9

Realizar una consulta SQL que retorne los siguientes campos:
- Nombre del producto
- Rubro del producto
- Año que mas se vendio

Solamente considerar aquellos productos, cuyos rubros superen en ventas mas de $100.000 en el 2011. 
El resultado debe ser ordenado de mayor a menor por cantidad de facturas en las que figura
*/

SELECT p.prod_detalle,
	   p.prod_rubro,
	   (SELECT TOP 1 YEAR(fact_fecha)
		FROM Factura 
			JOIN Item_Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
		WHERE item_producto = p.prod_codigo
		GROUP BY YEAR(fact_fecha)
		ORDER BY SUM(item_cantidad) DESC)
FROM Producto p
	JOIN Item_Factura i ON (p.prod_codigo = i.item_producto)
WHERE p.prod_rubro IN (SELECT prod_rubro 
						FROM Producto 
							JOIN Item_Factura on (prod_codigo = item_producto)
							JOIN Factura ON item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
						GROUP BY prod_rubro , YEAR(fact_fecha)
						HAVING SUM(item_cantidad*item_precio) > 100000 AND YEAR(fact_fecha) = 2011)
GROUP BY p.prod_detalle, p.prod_rubro, p.prod_codigo
ORDER BY COUNT(DISTINCT i.item_tipo + i.item_sucursal + i.item_numero) DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
La razon social de los 15 clientes que posean menor limite de credito, el promedio en $ de las compras realizadas por ese cliente
y que se indique un string"Compro productos compuestos" en caso de que alguno de todos los productos comprados tenga composicion.
-Considerar solo aquellos clientes que tengan alguna factura mayor a $350000 (fact_total).
-Se debera ordenar los resultados por el domicilio del cliente
*/

SELECT clie_razon_social,
AVG(fact_total),
CASE WHEN EXISTS (SELECT * FROM Item_Factura 
				 JOIN Factura ON fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
				 WHERE item_producto IN (SELECT comp_producto FROM Composicion) AND clie_codigo = fact_cliente)
	THEN 'Compro productos compuestos'
	ELSE 'No compro productos compuestos'
END
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
WHERE clie_codigo IN (SELECT TOP 15 fact_cliente FROM Factura
					 GROUP BY fact_cliente
					 HAVING EXISTS(SELECT * from Factura WHERE fact_total > 350000 AND fact_cliente = clie_codigo)
					 ORDER BY clie_limite_credito
					 )
GROUP BY clie_razon_social, clie_domicilio, clie_codigo
ORDER BY clie_domicilio


select clie_razon_social,
			  avg(fact_total), --odio el avg
			  case 
			  when(exists(select * from Item_Factura join Factura on item_tipo + item_sucursal + item_numero = fact_tipo + fact_sucursal + fact_numero
				   where item_producto in (select comp_producto from Composicion ) and clie_codigo = fact_cliente))
			  then('Compro productos compuestos')
			  else('-')
			  end comproComp
from Cliente
join factura on fact_cliente = clie_codigo
where clie_codigo in (select top 15 clie_codigo from Cliente group by clie_codigo, clie_razon_social, clie_domicilio, clie_limite_credito
					  having exists(select * from Factura where fact_cliente = clie_codigo and fact_total > 350) order by clie_limite_credito)
group by clie_codigo, clie_razon_social, clie_domicilio, clie_limite_credito
order by clie_domicilio

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
SELECT fami_detalle, SUM(item_cantidad*item_precio), COUNT(DISTINCT item_producto), 
		(SELECT COUNT(*) FROM Composicion
		JOIN Producto ON prod_codigo = comp_producto WHERE prod_familia = fami_id),
		(SELECT TOP 1 fact_cliente FROM Factura
		JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
		JOIN Producto ON prod_codigo = item_producto
		WHERE prod_familia = fami_id
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		)
FROM Familia
JOIN Producto ON prod_familia = fami_id 
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE fami_id IN (SELECT TOP 10 prod_familia FROM Producto 
					JOIN Item_Factura ON item_producto = prod_codigo
				    JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
					WHERE YEAR(fact_fecha) = 2011
					GROUP BY prod_familia
					ORDER BY ISNULL(SUM(item_cantidad*item_precio),0)
				  )
GROUP BY fami_detalle,fami_id

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*
	Realizar una consulta SQL que retorne, para cada producto que no fue vendido en el 2012, la siguiente info:

	- Detalle del producto
	- Rubro del producto
	- Cantidad de productos que tiene el rubro
	- Precio maximo de venta en toda la historia, si no tiene ventas en la historia, mostrar 0

	El resultado debera mostrar primero aquellos productos que tienen composicion.
*/


SELECT P1.prod_detalle,
P1.prod_rubro,
(SELECT COUNT(*) FROM Producto WHERE prod_rubro = P1.prod_rubro),
ISNULL(MAX(item_precio),0)
FROM Producto P1
JOIN Item_Factura ON P1.prod_codigo = item_producto
WHERE P1.prod_codigo NOT IN (SELECT item_producto FROM Item_Factura
							JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
							WHERE YEAR(fact_fecha) = 2012)
GROUP BY P1.prod_detalle,P1.prod_rubro, P1.prod_codigo
ORDER BY (SELECT comp_producto FROM Composicion
		  WHERE comp_producto = prod_codigo
		  GROUP BY comp_producto) DESC

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/* 
Relizar una consulta SQL que retorne para los 10 clientes que mas compraron en el 2012 y que fueron atendidos por mas de 3 vendedores distintos:
-Apellido y Nombre del cliente
-Cantidad de productos distintos comprados en el 2012
-Cantidad de unidades compradas dentro del primer semestre del 2012
El resultado debera mostrar ordenado la cantidad de ventas descendente del 2012 de cada cliente, en caso de igualdad de ventas, ordenar por codigo de cliente
*/

SELECT clie_razon_social,
(SELECT COUNT(DISTINCT item_producto) FROM Item_Factura
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE F1.fact_cliente = fact_cliente AND YEAR(fact_fecha) = 2012),
(SELECT SUM(item_cantidad) FROM Item_Factura
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE F1.fact_cliente = clie_codigo AND MONTH(fact_fecha) <= 6 AND YEAR(fact_fecha) = 2012)
FROM Cliente
JOIN Factura F1 ON F1.fact_cliente = clie_codigo
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE clie_codigo IN (SELECT TOP 10 fact_cliente FROM Factura
WHERE YEAR(fact_fecha) = 2012
GROUP BY fact_cliente
HAVING COUNT(DISTINCT fact_vendedor) > 3)
GROUP BY clie_razon_social,clie_codigo, fact_cliente
ORDER BY SUM(item_cantidad) DESC, clie_codigo

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*Armar una consulta SQL que muestre aquel/aquellos clientes que en 2 años consecutivos (de existir), 
fueron los mejores compradores, es decir, 
los que en monto total facturado anual fue el máximo. 
De esos clientes mostrar , razon social, domicilio,cantidad de unidades compradas en el último año.
Nota: No se puede usar select en el from.
*/

SELECT clie_razon_social,
clie_domicilio,
(SELECT SUM(item_cantidad) FROM Item_Factura
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(F2.fact_fecha)) FROM Factura F2) AND fact_cliente = clie_codigo
)
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
WHERE clie_codigo IN
(SELECT TOP 1 fact_cliente FROM Factura F2
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) = YEAR(F2.fact_fecha)
GROUP BY fact_cliente
ORDER BY SUM(fact_total) DESC
) AND clie_codigo IN 
(SELECT TOP 1 fact_cliente FROM Factura F2
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE YEAR(fact_fecha) + 1 = YEAR(F2.fact_fecha)
GROUP BY fact_cliente
ORDER BY SUM(fact_total) DESC
)
GROUP BY clie_razon_social, clie_domicilio, clie_codigo



SELECT C1.clie_razon_social,C1.clie_domicilio,(SELECT SUM(item_cantidad) FROM Item_Factura 
											   JOIN Factura ON fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
											   WHERE fact_cliente=C1.clie_codigo AND YEAR(fact_fecha) = (SELECT MAX(YEAR(F2.fact_fecha)) FROM Factura F2)) 
FROM Cliente C1
JOIN Factura F1 ON F1.fact_cliente=C1.clie_codigo
WHERE C1.clie_codigo IN
(
	SELECT TOP 1 fact_cliente FROM Factura 
	JOIN Item_Factura ON item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
	WHERE YEAR(F1.fact_fecha)=YEAR(fact_fecha)
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad * item_precio) DESC
) AND C1.clie_codigo IN 
(
	SELECT TOP 1 fact_cliente FROM Factura 
	JOIN Item_Factura ON item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
	WHERE YEAR(F1.fact_fecha) + 1=YEAR(fact_fecha)
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad * item_precio) DESC
)
GROUP BY C1.clie_razon_social,C1.clie_domicilio,C1.clie_codigo


--OTRA
SELECT C1.clie_razon_social,C1.clie_domicilio,(SELECT SUM(item_cantidad*item_precio) FROM Item_Factura 
											   JOIN Factura ON fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
											   WHERE fact_cliente=C1.clie_codigo AND YEAR(fact_fecha) = (SELECT MAX(YEAR(F2.fact_fecha)) FROM Factura F2)) 
FROM Cliente C1
JOIN Factura F1 ON F1.fact_cliente=C1.clie_codigo
WHERE C1.clie_codigo IN
(
	SELECT TOP 1 F3.fact_cliente FROM Factura F3
	JOIN Item_Factura I3 ON I3.item_numero+I3.item_tipo+I3.item_sucursal=F3.fact_numero+F3.fact_tipo+F3.fact_sucursal
	WHERE F3.fact_cliente IN (
								SELECT TOP 1 F4.fact_cliente FROM Factura F4
								JOIN Item_Factura I4 ON I4.item_numero+I4.item_tipo+I4.item_sucursal=F4.fact_numero+F4.fact_tipo+F4.fact_sucursal
								WHERE YEAR(F4.fact_fecha) = YEAR(F1.fact_fecha) + 1
								GROUP BY F4.fact_cliente
								ORDER BY SUM(I4.item_cantidad * I4.item_precio) DESC
								)
						AND YEAR(F3.fact_fecha) = YEAR(F1.fact_fecha)
	GROUP BY F3.fact_cliente
	ORDER BY SUM(I3.item_cantidad*I3.item_precio) DESC
)
GROUP BY C1.clie_razon_social,C1.clie_domicilio,C1.clie_codigo

--POSIBLE SOLUCIÓN pero con fac_total

select c1.clie_razon_social, c1.clie_domicilio,
	(
	select sum(isnull(item_cantidad,0))
	from Item_Factura
	join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
	where fact_cliente = c1.clie_codigo

	and year(fact_fecha) =
		(
		select max(isnull(year(fact_fecha),0))
		from Factura
		)
	) as 'un. compradas en ultimo año'
from Cliente c1
join Factura fa on c1.clie_codigo = fact_cliente
where c1.clie_codigo in
	(
	select top 1 fact_cliente
	from Factura f1
	where fact_cliente in
		(
		select top 1 f2.fact_cliente
		from Factura f2
		where year(f2.fact_fecha) = year(f1.fact_fecha) + 1
		group by f2.fact_cliente
		order by sum(isnull(f2.fact_total,0))
		)
	and year(f1.fact_fecha) = year(fa.fact_fecha)
	group by fact_cliente
	order by sum(isnull(fact_total,0))
	)

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*Se necesita saber que productos no han sido vendidos durante el año 2012 pero que sí tuvieron ventas en año anteriores. 
De esos productos mostrar:
1.Código de producto
2.Nombre de Producto
3.Un string que diga si es compuesto o no.

El resultado deberá ser ordenado por cantidad vendida en años anteriores.
*/
select prod_codigo, prod_detalle, 
case
	when prod_codigo in (select distinct comp_producto from composicion)
		then 'El producto es compuesto'
	else 'El producto no tiene composicion'
	end resultado
from producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
where year(fact_fecha) < 2012 and prod_codigo not in (select item_producto from Factura join Item_Factura
		 on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
			where year(fact_fecha)=2012)
group by prod_codigo, prod_detalle
order by sum(item_cantidad) desc

/*--------------------------------------------------------------------------------------------------------------------------------------*/

/*FOTO 10
Realizar una consulta SQL que retorne: Año, cantidad de productos compuestos vendidos en el Año,
cantidad de facturas realizadas en el Año, monto total facturado en el Año,
monto total facturado en el Año anterior.
Solamente considerar aquellos Años donde la cantidad de unidades vendidas de todos los artículos
sea mayor a 1000.
Se debera ordenar el resultado por cantidad vendida en el año
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/

SELECT YEAR(F1.fact_fecha),
(
SELECT COUNT(DISTINCT comp_producto) 
FROM Factura
JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
JOIN Composicion ON comp_producto=item_producto
WHERE comp_producto=item_producto AND YEAR(F1.fact_fecha) = YEAR(fact_fecha)
),
COUNT(DISTINCT F1.fact_numero+F1.fact_sucursal+F1.fact_tipo),
SUM(F1.fact_total),
(
SELECT SUM(fact_total) FROM Factura
WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha) - 1
)
FROM Factura F1
JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=F1.fact_numero+F1.fact_sucursal+F1.fact_tipo
GROUP BY YEAR(F1.fact_fecha)
HAVING SUM(item_cantidad) > 1000
ORDER BY SUM(item_cantidad)
