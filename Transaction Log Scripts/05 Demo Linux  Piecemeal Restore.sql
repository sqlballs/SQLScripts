/*============================================================
// Source via Bradley Ball :: braball@micrsoft.com
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY

==============================================================*/
/*
Start All Over from the Orginal
*/
USE master
go
RESTORE DATABASE demoInternals_Partition 
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition.bak'
WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10

/*
Take a look at our data to
make sure we have rows in our
sample table
*/
USE demoInternals_Partition
GO
SELECT
	so.name
	,sp.rows
	,*
FROM
	sys.partitions sp
	LEFT JOIN sys.objects so
	ON sp.object_id=so.object_id
WHERE 
	so.type='U' AND index_id=1
	
/*
Do a fresh backup of the Database and Transaction Log
*/
USE master
go
BACKUP DATABASE demoInternals_Partition TO DISK=N'/var/opt/mssql/data/demoInternals_Partition2.bak' WITH INIT
GO
BACKUP LOG demoInternals_Partition TO DISK=N'/var/opt/mssql/data/demoInternals_Partition_log.trn' WITH INIT
GO
BACKUP LOG demoInternals_Partition TO  DISK = N'/var/opt/mssql/data/demoCompression_TailofTheLog.trn' WITH  NO_TRUNCATE , INIT, NORECOVERY 
GO



/*
Restore the Primary File group
& FG1
Then restore the Log backup
As well as the Tail End of the Log
*/
USE master
GO

RESTORE DATABASE demoInternals_Partition FILEGroup='primary'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH PARTIAL, NORECOVERY
GO
RESTORE DATABASE demoInternals_Partition FILEGroup='FG1'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery
GO
RESTORE DATABASE demoInternals_Partition FILEGroup='FG2'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery
GO
RESTORE DATABASE demoInternals_Partition FILEGroup='FG3'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery
GO
RESTORE DATABASE demoInternals_Partition FILEGroup='FG4'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery
GO
RESTORE DATABASE demoInternals_Partition FILEGroup='FG5'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery

RESTORE LOG demoInternals_Partition  FROM DISK=N'/var/opt/mssql/data/demoInternals_Partition_log.trn' WITH norecovery


RESTORE LOG [demoInternals_Partition] FROM  DISK = N'/var/opt/mssql/data/demoCompression_TailofTheLog.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10
GO


/*
Do a select from a recovered File Group 
To Show that we can query some of the data
*/
USE demoInternals_Partition
GO
SELECT
	*
FROM
	dbo.myTable1
WHERE myID BETWEEN 5000 AND 9000


/*
Do a select from an unrecovered File Group 
To Show that we cannot query the data
*/
USE demoInternals_Partition
GO
SELECT
	*
FROM
	dbo.myTable1
WHERE myID BETWEEN 10000 AND 15000
go

select count(*) from dbo.myTable1
go

/*
Restore FG6 and log files 
to bring FG6 back online
*/
USE master
go

RESTORE DATABASE demoInternals_Partition FILEGroup='FG6'
	FROM DISK='/var/opt/mssql/data/demoInternals_Partition2.bak'
WITH norecovery


RESTORE LOG demoInternals_Partition  FROM DISK=N'/var/opt/mssql/data/demoInternals_Partition_log.trn' WITH norecovery


RESTORE LOG [demoInternals_Partition] FROM  DISK = N'/var/opt/mssql/data/demoCompression_TailofTheLog.trn' WITH  FILE = 1,  NOUNLOAD,  STATS = 10
GO


/*
To show that we can now query FG6
*/
USE demoInternals_Partition
GO
SELECT
	*
FROM
	dbo.myTable1
WHERE myID BETWEEN 10000 AND 15000
go

select count(*) from dbo.myTable1
go







