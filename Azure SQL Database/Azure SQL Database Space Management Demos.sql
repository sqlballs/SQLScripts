/*============================================================
// Source via Bradley Ball :: braball@micrsoft.com
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY

==============================================================*/
/*Connect to master
Database data space used in MB
*/
SELECT  * 
FROM sys.resource_stats
WHERE database_name = 'yourdbname'
ORDER BY end_time DESC;


/*Connect to database
Database data space allocated in MB and database data space allocated unused in MB
*/
SELECT SUM(size/128.0) AS DatabaseDataSpaceAllocatedInMB,
SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0) AS DatabaseDataSpaceAllocatedUnusedInMB
FROM sys.database_files
GROUP BY type_desc
HAVING type_desc = 'ROWS';

/*
Review file properties, including file_id and name values to reference in shrink commands
*/
SELECT 
	GETDATE() as [timestamp],
	file_id,
       name,
       CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024. AS space_used_mb,
       CAST(size AS bigint) * 8 / 1024. AS space_allocated_mb,
	  ( CAST(size AS bigint) * 8 / 1024.) - (CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024.) as available_reclaimed,
       CAST(max_size AS bigint) * 8 / 1024. AS max_file_size_mb,
	   (CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024)/1024. AS space_used_gb,
       (CAST(size AS bigint) * 8 / 1024)/1024. AS space_allocated_gb,
       (CAST(max_size AS bigint) * 8 / 1024)/1024. AS max_file_size_gb
FROM sys.database_files
WHERE type_desc IN ('ROWS','LOG');

/*
Understand our indexes
*/
set transaction isolation level read uncommitted

SELECT OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
       OBJECT_NAME(ips.object_id) AS object_name,
       i.name AS index_name,
       i.type_desc AS index_type,
       ips.avg_page_space_used_in_percent,
       ips.avg_fragmentation_in_percent,
       ips.page_count,
       ips.alloc_unit_type_desc,
       ips.ghost_record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), default, default, default, 'SAMPLED') AS ips
INNER JOIN sys.indexes AS i 
ON ips.object_id = i.object_id
   AND
   ips.index_id = i.index_id
ORDER BY page_count DESC;


/*
build a clustered index on a heap
*/
create clustered index clx_indexname on dbo.yourtablename(yourkey)

/*
Review file properties, including file_id and name values to reference in shrink commands
*/
SELECT 
	GETDATE() as [timestamp],
	file_id,
       name,
       CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024. AS space_used_mb,
       CAST(size AS bigint) * 8 / 1024. AS space_allocated_mb,
	  ( CAST(size AS bigint) * 8 / 1024.) - (CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024.) as available_reclaimed,
       CAST(max_size AS bigint) * 8 / 1024. AS max_file_size_mb,
	   (CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8 / 1024)/1024. AS space_used_gb,
       (CAST(size AS bigint) * 8 / 1024)/1024. AS space_allocated_gb,
       (CAST(max_size AS bigint) * 8 / 1024)/1024. AS max_file_size_gb
FROM sys.database_files
WHERE type_desc IN ('ROWS','LOG');


/*
Ask yourself

Should we?
*/
/*
test query
*/
dbcc dropcleanbuffers
set statistics io on

select
	*
from
	dbo.yourtablename
where
	myid between 90000 and 590000

/*
If you have to do this try truncate only
*/
DBCC SHRINKFILE (1, TRUNCATEONLY);

/*
Shrink database data space allocated.
*/
set statistics io off
DBCC SHRINKDATABASE (N'yourdbname');

/*
--copy to another window & run
--monitors the shrink command 
SELECT command,
       percent_complete,
       status,
       wait_resource,
       session_id,
       wait_type,
       blocking_session_id,
       cpu_time,
       reads,
       CAST(((DATEDIFF(s,start_time, GETDATE()))/3600) AS varchar) + ' hour(s), '
                     + CAST((DATEDIFF(s,start_time, GETDATE())%3600)/60 AS varchar) + 'min, '
                     + CAST((DATEDIFF(s,start_time, GETDATE())%60) AS varchar) + ' sec' AS running_time
FROM sys.dm_exec_requests AS r
LEFT JOIN sys.databases AS d
ON r.database_id = d.database_id
WHERE r.command IN ('DbccSpaceReclaim','DbccFilesCompact','DbccLOBCompact','DBCC');
*/

/*
test query
*/
dbcc dropcleanbuffers
set statistics io on

select
	*
from
	dbo.yourtablename
where
	myid between 90000 and 590000

/*
Ask yourself

Should we?
*/

/*
Shrink the database log file (always file_id 2), by removing all unused space at the end of the file, if any.
*/
DBCC SHRINKFILE (2, TRUNCATEONLY);
