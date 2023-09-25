 
--  ---------------------------------------------------------SECTION 2 Data Analysis------------------------------------------------------------------------------------ 
 
 
 -- Retrieve properties that have a price greater than 1 million and are located in "Estados Unidos" (l1)
 SELECT pd.*
FROM property_details pd
JOIN property_price_details ppd ON pd.id = ppd.id
WHERE ppd.price > 1000000 -- 1 million
  AND pd.l1 = 'Estados Unidos';
  
 -- Categorize properties based on their surface area as 'Small' if it's less than 50 square meters, 'Medium' if it's between 50 and 100 square meters, and 'Large' if it's greater than 100 square meters:
 SELECT pd.*,
  CASE
    WHEN pd.surface_total < 50 THEN 'Small'
    WHEN pd.surface_total >= 50 AND pd.surface_total <= 100 THEN 'Medium'
    ELSE 'Large'
  END AS surface_category
FROM property_details pd;

-- List all properties (id) in the "Belgrano" neighborhood (l3) that have the same number of bedrooms and bathrooms as another property in the dataset
SELECT DISTINCT p1.id
FROM property_details p1
INNER JOIN property_details p2 ON p1.id <> p2.id
WHERE p1.l3 = 'Belgrano'
  AND p1.bedrooms = p2.bedrooms
  AND p1.bathrooms = p2.bathrooms;
  
-- Calculate the average price per square meter (price / surface_total) for each property type (property_type) in the "Belgrano" neighborhood (l3)
SELECT
  ppd.property_type,
  AVG(ppd.price / pd.surface_total) AS avg_price_per_sq_meter
FROM property_details pd
INNER JOIN property_price_details ppd ON pd.id = ppd.id
WHERE pd.l3 = 'Belgrano'
GROUP BY ppd.property_type;

-- Identify properties that have a higher price than the average price of properties with the same number of bedrooms and bathrooms.

  
 SELECT 
    bedrooms, 
    bathrooms, 
    AVG(price) AS average_price
FROM 
    property_details 
INNER JOIN 
    property_price_details ON property_details.id = property_price_details.id
GROUP BY 
    bedrooms, bathrooms;
    
  SELECT 
    property_details.id,
    bedrooms, 
    bathrooms, 
    price
FROM 
    property_details 
INNER JOIN 
    property_price_details ON property_details.id = property_price_details.id
WHERE 
    price > (
        SELECT 
            AVG(price) 
        FROM 
            property_details as pd 
        INNER JOIN 
            property_price_details as ppd ON pd.id = ppd.id
        WHERE 
            pd.bedrooms = property_details.bedrooms AND 
            pd.bathrooms = property_details.bathrooms
    );
  

    
-- Calculate the cumulative price for each property type, ordered by the creation date
SELECT 
    pd.id,
    ppd.property_type,
    pd.created_on,
    ppd.price,
    SUM(ppd.price) OVER (PARTITION BY ppd.property_type ORDER BY pd.created_on) AS cumulative_price
FROM 
    property_details pd
INNER JOIN 
    property_price_details ppd ON pd.id = ppd.id
ORDER BY 
    ppd.property_type, pd.created_on;
    
-- Identify the 10 locations (l3) with the highest total surface area (sum of surface_total) of properties listed for sale (operation_type = 'Venta'):
SELECT
    pd.l3,
    SUM(pd.surface_total) AS total_surface_area
FROM
    property_details pd
INNER JOIN
    property_price_details ppd ON pd.id = ppd.id
WHERE
    ppd.operation_type = 'Venta'
GROUP BY
    pd.l3
ORDER BY
    total_surface_area DESC
LIMIT 10;


-- Find the top 5 most expensive properties (based on price) in the "Palermo" neighborhood (l3) that were listed in August 2020:
SELECT
    pd.id,
    pd.l3,
    ppd.price,
    pd.created_on
FROM
    property_details pd
INNER JOIN
    property_price_details ppd ON pd.id = ppd.id
WHERE
    pd.l3 = 'Palermo'
    AND pd.created_on >= '2020-08-01'
    AND pd.created_on < '2020-09-01'
ORDER BY
    ppd.price DESC
LIMIT 5;

-- Find the top 3 properties with the highest price per square meter (price divided by surface area) within each property type.
WITH RankedProperties AS (
  SELECT
    pd.id,
    ppd.property_type,
    pd.surface_total,
    ppd.price / pd.surface_total AS price_per_sq_meter,
    ROW_NUMBER() OVER (PARTITION BY ppd.property_type ORDER BY ppd.price / pd.surface_total DESC) AS rank_within_type
  FROM
    property_details pd
  INNER JOIN
    property_price_details ppd ON pd.id = ppd.id
)

SELECT
  id,
  property_type,
  surface_total,
  price_per_sq_meter
FROM
  RankedProperties
WHERE
  rank_within_type <= 3;
  
  
  --  Find the top 3 locations (l1, l2, l3) with the highest average price per square meter (price / surface_total) for 
-- properties listed for sale (operation_type = 'Venta') in the year 2020. Exclude locations with fewer than 10 
-- properties listed for sale in 2020 from the results.
WITH LocationAvgPrice AS (
  SELECT
    pd.l1,
    pd.l2,
    pd.l3,
    AVG(ppd.price / pd.surface_total) AS avg_price_per_sq_meter
  FROM
    property_details pd
  INNER JOIN
    property_price_details ppd ON pd.id = ppd.id
  WHERE
    ppd.operation_type = 'Venta'
    AND YEAR(pd.created_on) = 2020
  GROUP BY
    pd.l1, pd.l2, pd.l3
  HAVING
    COUNT(*) >= 10
)

SELECT
  l1,
  l2,
  l3,
  avg_price_per_sq_meter
FROM
  LocationAvgPrice
ORDER BY
  avg_price_per_sq_meter DESC
LIMIT 3;


