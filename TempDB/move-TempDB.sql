-- Filesystem Info
USE TempDB
GO
EXEC sp_helpfile
GO

-- Move Data and Log

USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'd:\datatempdb.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'e:\datatemplog.ldf')
GO

-- Remove stuck file

USE [tempdb]
GO
DBCC SHRINKFILE (N'tempdev0?', EMPTYFILE)
GO

USE [tempdb]
GO
ALTER DATABASE [tempdb]  REMOVE FILE [tempdev0?]
GO


-- start without TempDB
-- NET START MSSQLSERVER /f
