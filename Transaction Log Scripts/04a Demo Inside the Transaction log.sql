/*============================================================
// Source via Bradley Ball :: braball@micrsoft.com
// MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY

==============================================================*/

/*
DBCC SQLPERF(LOGSPACE)
*/
DBCC SQLPERF(LOGSPACE)

/*DBCC LOGINFO*/
USE demoCOMPRESSION_Partition
GO

DBCC LogInfo
GO
/* sys.dm_db_log_info */

select * from sys.dm_db_log_info(db_id('demoCOMPRESSION_Partition')) 

/*
FN_GET_DBLOG
*/
SELECT
	*
FROM ::fn_dblog(NULL, NULL)

/*
Create a Fresh DB
*/
IF EXISTS(SELECT NAME FROM sys.databases WHERE NAME='TLogDemo')
BEGIN
	DROP DATABASE TLogDemo
END
CREATE DATABASE TLogDemo
GO

USE TLogDemo
GO

IF EXISTS(SELECT NAME FROM sys.tables WHERE name=N'myTable1')
BEGIN
	DROP TABLE dbo.myTable1
END

CREATE TABLE myTable1( 
	myID INT IDENTITY(1,1)
	,productName char(500) DEFAULT 'some product'
	,productDescription CHAR(1000) DEFAULT 'Product Description'
	,CONSTRAINT PK_myID PRIMARY KEY CLUSTERED(myID) 	
) ;	

/*
Look at the Transactions within
The Transaction Log
*/
BEGIN TRAN TLogDemo
DECLARE @i INT, @x CHAR (13)
SET @i=2

WHILE (@i<20)
	BEGIN
		INSERT INTO dbo.myTable1(productName, productDescription)
		VALUES(
				('some product' + CAST((@i +1) AS VARCHAR(5)))
				,('Here is a Generic Product Description' + CAST((@i+1) AS VARCHAR(5)))
				)
			

		SET @i = @i +1

	END


SELECT 
	@x = [Transaction ID] 
FROM 
	::fn_dblog (null, null) 
WHERE 
	[Transaction Name]='TLogDemo' 

SELECT 
	* 
FROM 
	::fn_dblog (null, null) 
WHERE 
	[Transaction ID] = @x; 
GO
						
COMMIT TRAN


