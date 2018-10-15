USE Master; 
GO  
SET NOCOUNT ON 

DECLARE @dbName sysname 
DECLARE @backupPath NVARCHAR(500) 
DECLARE @cmd NVARCHAR(500) 
DECLARE @fileList TABLE (backupFile NVARCHAR(255)) 
DECLARE @backupFile NVARCHAR(500) 

SET @dbName = 'RandhawA' 
SET @backupPath = 'E:\Unzipped\DBPDADC100\Unzipped\' 

SET @cmd = 'DIR /b /o d ' + @backupPath + @dbName + '_backup*.*'
INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd 

SET @cmd = 'DIR /b /o d ' + @backupPath + @dbName + '_20*.*'
INSERT INTO @fileList(backupFile) 
EXEC master.sys.xp_cmdshell @cmd 


DECLARE backupFiles CURSOR FOR  
   SELECT backupFile  
   FROM @fileList 
   WHERE backupFile LIKE '%.trn'  

OPEN backupFiles  

FETCH NEXT FROM backupFiles INTO @backupFile  

WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'RESTORE LOG ' + @dbName + ' FROM DISK = '''  
       + @backupPath + @backupFile + ''' WITH NORECOVERY' 
   PRINT @cmd 
   FETCH NEXT FROM backupFiles INTO @backupFile  
END 

CLOSE backupFiles  
DEALLOCATE backupFiles  
