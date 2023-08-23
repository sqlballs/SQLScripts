/*============================================================
// Source via Bradley Ball :: braball@micrsoft.com
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//documentation link: https://learn.microsoft.com/en-us/fabric/data-warehouse/statistics#automatic-statistics-at-query
==============================================================*/
/*
IN SQL I would use a query like this
*/

-- get all statistics
SELECT o.name, i.name AS [Index Name],  
      STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
      s.auto_created, s.no_recompute, s.user_created, st.row_count
FROM sys.objects AS o 
INNER JOIN sys.indexes AS i 
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s  
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
INNER JOIN sys.dm_db_partition_stats AS st  
ON o.[object_id] = st.[object_id]
AND i.[index_id] = st.[index_id]
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC 

--get all Automatically Created Statistics
SELECT OBJECT_NAME(s.object_id) AS object_name,
    COL_NAME(sc.object_id, sc.column_id) AS column_name,
    s.name AS statistics_name
FROM sys.stats AS s
INNER JOIN sys.stats_columns AS sc
    ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id
WHERE s.name like '_WA%'
ORDER BY s.name;


/*
IN Fabric I would use a query like this
*/
--All Stats
select
    object_name(s.object_id) AS [object_name],
    c.name AS [column_name],
    s.name AS [stats_name],
    s.stats_id,
    STATS_DATE(s.object_id, s.stats_id) AS [stats_update_date], 
    s.auto_created,
    s.user_created,
    s.stats_generation_method_desc 
FROM sys.stats AS s 
INNER JOIN sys.objects AS o 
ON o.object_id = s.object_id 
INNER JOIN sys.stats_columns AS sc 
ON s.object_id = sc.object_id 
AND s.stats_id = sc.stats_id 
INNER JOIN sys.columns AS c 
ON sc.object_id = c.object_id 
AND c.column_id = sc.column_id
WHERE o.type = 'U' -- Only check for stats on user-tables
    AND s.auto_created = 1
ORDER BY object_name, column_name;

--all stats for your table
select
    object_name(s.object_id) AS [object_name],
    c.name AS [column_name],
    s.name AS [stats_name],
    s.stats_id,
    STATS_DATE(s.object_id, s.stats_id) AS [stats_update_date], 
    s.auto_created,
    s.user_created,
    s.stats_generation_method_desc 
FROM sys.stats AS s 
INNER JOIN sys.objects AS o 
ON o.object_id = s.object_id 
INNER JOIN sys.stats_columns AS sc 
ON s.object_id = sc.object_id 
AND s.stats_id = sc.stats_id 
INNER JOIN sys.columns AS c 
ON sc.object_id = c.object_id 
AND c.column_id = sc.column_id
WHERE o.type = 'U' -- Only check for stats on user-tables
    AND s.auto_created = 1
    AND o.name = 'DimCustomer'
ORDER BY object_name, column_name;

/*Create Statistics*/
CREATE STATISTICS DimCustomer_CustomerKey_FullScan
ON dbo.DimCustomer ([Customer Key]) WITH FULLSCAN;

/* Update Statistics */
UPDATE STATISTICS dbo.DimCustomer (DimCustomer_CustomerKey_FullScan) WITH FULLSCAN;

/* Show the Statistics */
DBCC SHOW_STATISTICS ('dbo.DimCustomer', 'DimCustomer_CustomerKey_FullScan');

/* Show the Statistics with a histogram*/
DBCC SHOW_STATISTICS ('dbo.DimCustomer', 'DimCustomer_CustomerKey_FullScan') WITH HISTOGRAM;

/*Drop the Statistics */
DROP STATISTICS dbo.DimCustomer.DimCustomer_CustomerKey_FullScan;

/*Auto Create Statistics */
SELECT
 Customer
 ,[Postal Code]
 ,COUNT(*)
 FROM
	dbo.DimCustomer
GROUP BY Customer, [Postal Code]


/*See our new Statistics*/
select
    object_name(s.object_id) AS [object_name],
    c.name AS [column_name],
    s.name AS [stats_name],
    s.stats_id,
    STATS_DATE(s.object_id, s.stats_id) AS [stats_update_date], 
    s.auto_created,
    s.user_created,
    s.stats_generation_method_desc 
FROM sys.stats AS s 
INNER JOIN sys.objects AS o 
ON o.object_id = s.object_id 
INNER JOIN sys.stats_columns AS sc 
ON s.object_id = sc.object_id 
AND s.stats_id = sc.stats_id 
INNER JOIN sys.columns AS c 
ON sc.object_id = c.object_id 
AND c.column_id = sc.column_id
WHERE o.type = 'U' -- Only check for stats on user-tables
    AND s.auto_created = 1
    AND o.name = 'DimCustomer'
ORDER BY object_name, column_name;

/* Show the Statistics */
DBCC SHOW_STATISTICS ('dbo.DimCustomer', '_WA_Sys_00000003_73DA2C14');

/*Clean Up Demo */
DROP STATISTICS dbo.DimCustomer._WA_Sys_00000003_73DA2C14;
DROP STATISTICS dbo.DimCustomer._WA_Sys_00000008_73DA2C14;
