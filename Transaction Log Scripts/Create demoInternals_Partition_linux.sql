/*============================================================
// Source via Bradley Ball :: braball@micrsoft.com
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY

==============================================================*/
SET NOCOUNT ON;
/*
Create our Database 
That we will use for the
Demo
*/
USE master;
Go
IF EXISTS(SELECT name FROM sys.databases WHERE Name=N'demoInternals_Partition')
	BEGIN
		alter database demoInternals_Partition set single_user with rollback immediate
		DROP Database demoInternals_Partition
	END
	
CREATE DATABASE demoInternals_Partition
GO
ALTER DATABASE demoInternals_Partition MODIFY FILE ( NAME = N'demoInternals_Partition_log', FILEGROWTH = 512KB )
GO
/*
Add Filegroups
*/
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG1
GO
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG2
GO
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG3
GO
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG4
GO
/*
Add Files and 
associate to filegroups
*/
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG1,
	FILENAME='/var/opt/mssql/data/FG1.ndf'
) TO FILEGROUP FG1;
GO
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG2,
	FILENAME='/var/opt/mssql/data/FG2.ndf'
) TO FILEGROUP FG2;
GO
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG3,
	FILENAME='/var/opt/mssql/data/FG3.ndf'
) TO FILEGROUP FG3;
GO
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG4,
	FILENAME='/var/opt/mssql/data/FG4.ndf'
) TO FILEGROUP FG4;
GO

USE demoInternals_Partition
GO
/*
Create Partition Function
*/
CREATE PARTITION FUNCTION compDemoPartFunc(INT)
AS RANGE LEFT FOR VALUES(2000, 4000, 6000)
GO
/*
Create Partition Scheme
*/
CREATE PARTITION SCHEME compDemoPS
AS PARTITION compDemoPartFunc
TO(fg1, fg2,fg3, fg4);


/*
Let's create a Clustered Index
*/
IF EXISTS(SELECT NAME FROM sys.tables WHERE name=N'myTable1')
BEGIN
	DROP TABLE dbo.myTable1
END

CREATE TABLE myTable1( 
	myID INT IDENTITY(1,1),
	productName char(800) DEFAULT 'some product',
	productSKU varCHAR(500) DEFAULT 'Product SKU',
	productDescription varCHAR(max) DEFAULT 'Here is a Generic Production Description',
	Comments TEXT DEFAULT 'here are some genric comments',	
	CONSTRAINT PK_myTable1_myID 
	PRIMARY KEY CLUSTERED(myID) 	
) ON compDemoPS(myID);	

/*
Let's populate our Clustered
Index with some data
*/
DECLARE @i INT
SET @i=0

BEGIN TRAN
WHILE (@i<10000)
	BEGIN
		INSERT INTO myTable1 DEFAULT VALUES;
		SET @i = @i +1

	END
COMMIT TRAN


/*
Add another file group
*/
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG5
GO
/*
Associate with a Physical File
*/
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG5,
	FILENAME='/var/opt/mssql/data/FG5.ndf'
) TO FILEGROUP FG5;
GO

/*
Alter Partition Scheme
*/
Alter PARTITION SCHEME compDemoPS
NEXT USED FG5;

/*
Alter Partition Function
*/
ALTER PARTITION FUNCTION compDemoPartFunc()
SPLIT RANGE(10000)
GO

/*
Let's Add another 4000
rows to watch the
new Partition get
Populated
*/
DECLARE @i INT
SET @i=0

BEGIN TRAN 
WHILE (@i<4000)
	BEGIN
		INSERT INTO myTable1 DEFAULT VALUES;
		SET @i = @i +1

	END
COMMIT TRAN 	


/*
Add another file group
*/
ALTER DATABASE demoInternals_Partition
ADD FILEGROUP FG6
GO
/*
Associate with a Physical File
*/
ALTER DATABASE demoInternals_Partition
ADD FILE
(
	NAME=data_FG6,
	FILENAME='/var/opt/mssql/data/Internalsdata_FG6.ndf'
) TO FILEGROUP FG6;
GO

/*
Alter Partition Scheme
*/
Alter PARTITION SCHEME compDemoPS
NEXT USED FG6;

/*
Alter Partition Function
*/
ALTER PARTITION FUNCTION compDemoPartFunc()
SPLIT RANGE(14000)
GO

/*
Let's Add another 4000
rows to watch the
new Partition get
Populated
*/
DECLARE @i INT
SET @i=0

BEGIN TRAN

WHILE (@i<4000)
	BEGIN
		INSERT INTO myTable1 DEFAULT VALUES;
		SET @i = @i +1

	END
COMMIT TRAN
	
/*
Let's Throw A
Nonclusterd Index in
and see the compression
*/
CREATE INDEX nci_demoInternals_Partition_myTable1 ON dbo.myTable1(productName);
go

/*
let's look at our data
*/
SELECT 
	OBJECT_NAME(sp.object_id) AS tableName,
	si.name AS indexName,
	sp.partition_number,
	sp.rows,
	sp.data_compression_desc 
FROM 
	sys.partitions sp
	JOIN sys.indexes si
	ON si.object_id=sp.object_id AND si.index_id =sp.index_id
WHERE OBJECT_NAME(sp.object_id) ='myTable1'
