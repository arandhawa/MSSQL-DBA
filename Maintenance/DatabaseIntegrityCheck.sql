SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DatabaseIntegrityCheck]

@Databases nvarchar(max),
@CheckCommands nvarchar(max) = 'CHECKDB',
@PhysicalOnly nvarchar(max) = 'N',
@NoIndex nvarchar(max) = 'N',
@ExtendedLogicalChecks nvarchar(max) = 'N',
@TabLock nvarchar(max) = 'N',
@FileGroups nvarchar(max) = NULL,
@Objects nvarchar(max) = NULL,
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source: http://ola.hallengren.com                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  SET LOCK_TIMEOUT 3600000

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)

  DECLARE @Version numeric(18,10)

  DECLARE @Cluster nvarchar(max)

  DECLARE @CurrentFileGroupList nvarchar(max)
  DECLARE @CurrentFileGroupItem nvarchar(max)
  DECLARE @CurrentFileGroupPosition int

  DECLARE @CurrentObjectList nvarchar(max)
  DECLARE @CurrentObjectItem nvarchar(max)
  DECLARE @CurrentObjectPosition int

  DECLARE @CurrentID int
  DECLARE @CurrentDatabaseID int
  DECLARE @CurrentDatabaseName nvarchar(max)
  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)
  DECLARE @CurrentLogShippingRole nvarchar(max)

  DECLARE @CurrentFGID int
  DECLARE @CurrentFileGroupID int
  DECLARE @CurrentFileGroupName nvarchar(max)
  DECLARE @CurrentFileGroupExists bit

  DECLARE @CurrentOID int
  DECLARE @CurrentSchemaID int
  DECLARE @CurrentSchemaName nvarchar(max)
  DECLARE @CurrentObjectID int
  DECLARE @CurrentObjectName nvarchar(max)
  DECLARE @CurrentObjectType nvarchar(max)
  DECLARE @CurrentObjectExists bit

  DECLARE @CurrentCommand01 nvarchar(max)
  DECLARE @CurrentCommand02 nvarchar(max)
  DECLARE @CurrentCommand03 nvarchar(max)
  DECLARE @CurrentCommand04 nvarchar(max)
  DECLARE @CurrentCommand05 nvarchar(max)
  DECLARE @CurrentCommand06 nvarchar(max)
  DECLARE @CurrentCommand07 nvarchar(max)
  DECLARE @CurrentCommand08 nvarchar(max)
  DECLARE @CurrentCommand09 nvarchar(max)

  DECLARE @CurrentCommandOutput01 int
  DECLARE @CurrentCommandOutput04 int
  DECLARE @CurrentCommandOutput05 int
  DECLARE @CurrentCommandOutput08 int
  DECLARE @CurrentCommandOutput09 int

  DECLARE @CurrentCommandType01 nvarchar(max)
  DECLARE @CurrentCommandType04 nvarchar(max)
  DECLARE @CurrentCommandType05 nvarchar(max)
  DECLARE @CurrentCommandType08 nvarchar(max)
  DECLARE @CurrentCommandType09 nvarchar(max)

  DECLARE @tmpDatabases TABLE (ID int IDENTITY PRIMARY KEY,
                               DatabaseName nvarchar(max),
                               Completed bit)

  DECLARE @tmpFileGroups TABLE (ID int IDENTITY,
                                FileGroupID int,
                                FileGroupName nvarchar(max),
                                Selected bit,
                                Completed bit,
                                PRIMARY KEY(Selected, Completed, ID))

  DECLARE @tmpObjects TABLE (ID int IDENTITY,
                             SchemaID int,
                             SchemaName nvarchar(max),
                             ObjectID int,
                             ObjectName nvarchar(max),
                             ObjectType nvarchar(max),
                             Selected bit,
                             Completed bit,
                             PRIMARY KEY(Selected, Completed, ID))

  DECLARE @SelectedFileGroups TABLE (DatabaseName nvarchar(max),
                                     FileGroupName nvarchar(max),
                                     Selected bit)

  DECLARE @SelectedObjects TABLE (DatabaseName nvarchar(max),
                                  SchemaName nvarchar(max),
                                  ObjectName nvarchar(max),
                                  Selected bit)

  DECLARE @SelectedCheckCommands TABLE (CheckCommand nvarchar(max))

  DECLARE @Error int
  DECLARE @ReturnCode int

  SET @Error = 0
  SET @ReturnCode = 0

  SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + (SELECT QUOTENAME(schemas.name) FROM sys.schemas schemas INNER JOIN sys.objects objects ON schemas.[schema_id] = objects.[schema_id] WHERE [object_id] = @@PROCID) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @CheckCommands = ' + ISNULL('''' + REPLACE(@CheckCommands,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @PhysicalOnly = ' + ISNULL('''' + REPLACE(@PhysicalOnly,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @NoIndex = ' + ISNULL('''' + REPLACE(@NoIndex,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @ExtendedLogicalChecks = ' + ISNULL('''' + REPLACE(@ExtendedLogicalChecks,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @TabLock = ' + ISNULL('''' + REPLACE(@TabLock,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @FileGroups = ' + ISNULL('''' + REPLACE(@FileGroups,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Objects = ' + ISNULL('''' + REPLACE(@Objects,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL') + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Source: http://ola.hallengren.com' + CHAR(13) + CHAR(10)
  SET @StartMessage = REPLACE(@StartMessage,'%','%%') + ' '
  RAISERROR(@StartMessage,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute is missing. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@LogToTable%')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute needs to be updated. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'TF' AND schemas.[name] = 'dbo' AND objects.[name] = 'DatabaseSelect')
  BEGIN
    SET @ErrorMessage = 'The function DatabaseSelect is missing. Download http://ola.hallengren.com/scripts/DatabaseSelect.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    SET @ErrorMessage = 'The table CommandLog is missing. Download http://ola.hallengren.com/scripts/CommandLog.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ReturnCode = @Error
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  IF @Databases IS NULL OR @Databases = ''
  BEGIN
    SET @ErrorMessage = 'The value for parameter @Databases is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  INSERT INTO @tmpDatabases (DatabaseName, Completed)
  SELECT DatabaseName AS DatabaseName,
         0 AS Completed
  FROM dbo.DatabaseSelect (@Databases)
  ORDER BY DatabaseName ASC

  IF @@ERROR <> 0
  BEGIN
    SET @ErrorMessage = 'Error selecting databases.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  ----------------------------------------------------------------------------------------------------
  --// Select filegroups                                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET @CurrentFileGroupList = @FileGroups

  WHILE CHARINDEX(', ',@CurrentFileGroupList) > 0 SET @CurrentFileGroupList = REPLACE(@CurrentFileGroupList,', ',',')
  WHILE CHARINDEX(' ,',@CurrentFileGroupList) > 0 SET @CurrentFileGroupList = REPLACE(@CurrentFileGroupList,' ,',',')
  WHILE CHARINDEX(',,',@CurrentFileGroupList) > 0 SET @CurrentFileGroupList = REPLACE(@CurrentFileGroupList,',,',',')

  IF RIGHT(@CurrentFileGroupList,1) = ',' SET @CurrentFileGroupList = LEFT(@CurrentFileGroupList,LEN(@CurrentFileGroupList) - 1)
  IF LEFT(@CurrentFileGroupList,1) = ',' SET @CurrentFileGroupList = RIGHT(@CurrentFileGroupList,LEN(@CurrentFileGroupList) - 1)

  SET @CurrentFileGroupList = LTRIM(RTRIM(@CurrentFileGroupList))

  WHILE LEN(@CurrentFileGroupList) > 0
  BEGIN
    SET @CurrentFileGroupPosition = CHARINDEX(',', @CurrentFileGroupList)
    IF @CurrentFileGroupPosition = 0
    BEGIN
      SET @CurrentFileGroupItem = @CurrentFileGroupList
      SET @CurrentFileGroupList = ''
    END
    ELSE
    BEGIN
      SET @CurrentFileGroupItem = LEFT(@CurrentFileGroupList, @CurrentFileGroupPosition - 1)
      SET @CurrentFileGroupList = RIGHT(@CurrentFileGroupList, LEN(@CurrentFileGroupList) - @CurrentFileGroupPosition)
    END;

    WITH FileGroupItem01 (FileGroupItem, Selected) AS (
    SELECT CASE WHEN @CurrentFileGroupItem LIKE '-%' THEN RIGHT(@CurrentFileGroupItem,LEN(@CurrentFileGroupItem) - 1) ELSE @CurrentFileGroupItem END AS FileGroupItem,
           CASE WHEN @CurrentFileGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected),
    FileGroupItem02 (FileGroupItem, Selected) AS (
    SELECT CASE WHEN FileGroupItem = 'ALL_FILEGROUPS' THEN '%.%' ELSE FileGroupItem END AS FileGroupItem,
           Selected
    FROM FileGroupItem01)
    INSERT INTO @SelectedFileGroups (DatabaseName, FileGroupName, Selected)
    SELECT CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,2) ELSE NULL END AS DatabaseName,
           CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,1) ELSE NULL END AS FileGroupName,
           Selected
    FROM FileGroupItem02
  END

  ----------------------------------------------------------------------------------------------------
  --// Select objects                                                                             //--
  ----------------------------------------------------------------------------------------------------

  SET @CurrentObjectList = @Objects

  WHILE CHARINDEX(', ',@CurrentObjectList) > 0 SET @CurrentObjectList = REPLACE(@CurrentObjectList,', ',',')
  WHILE CHARINDEX(' ,',@CurrentObjectList) > 0 SET @CurrentObjectList = REPLACE(@CurrentObjectList,' ,',',')
  WHILE CHARINDEX(',,',@CurrentObjectList) > 0 SET @CurrentObjectList = REPLACE(@CurrentObjectList,',,',',')

  IF RIGHT(@CurrentObjectList,1) = ',' SET @CurrentObjectList = LEFT(@CurrentObjectList,LEN(@CurrentObjectList) - 1)
  IF LEFT(@CurrentObjectList,1) = ',' SET @CurrentObjectList = RIGHT(@CurrentObjectList,LEN(@CurrentObjectList) - 1)

  SET @CurrentObjectList = LTRIM(RTRIM(@CurrentObjectList))

  WHILE LEN(@CurrentObjectList) > 0
  BEGIN
    SET @CurrentObjectPosition = CHARINDEX(',', @CurrentObjectList)
    IF @CurrentObjectPosition = 0
    BEGIN
      SET @CurrentObjectItem = @CurrentObjectList
      SET @CurrentObjectList = ''
    END
    ELSE
    BEGIN
      SET @CurrentObjectItem = LEFT(@CurrentObjectList, @CurrentObjectPosition - 1)
      SET @CurrentObjectList = RIGHT(@CurrentObjectList, LEN(@CurrentObjectList) - @CurrentObjectPosition)
    END;

    WITH ObjectItem01 (ObjectItem, Selected) AS (
    SELECT CASE WHEN @CurrentObjectItem LIKE '-%' THEN RIGHT(@CurrentObjectItem,LEN(@CurrentObjectItem) - 1) ELSE @CurrentObjectItem END AS ObjectItem,
           CASE WHEN @CurrentObjectItem LIKE '-%' THEN 0 ELSE 1 END AS Selected),
    ObjectItem02 (ObjectItem, Selected) AS (
    SELECT CASE WHEN ObjectItem = 'ALL_OBJECTS' THEN '%.%.%' ELSE ObjectItem END AS ObjectItem,
           Selected
    FROM ObjectItem01)
    INSERT INTO @SelectedObjects (DatabaseName, SchemaName, ObjectName, Selected)
    SELECT CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,3) ELSE NULL END AS DatabaseName,
           CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,2) ELSE NULL END AS SchemaName,
           CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,1) ELSE NULL END AS ObjectName,
           Selected
    FROM ObjectItem02
  END;

  ----------------------------------------------------------------------------------------------------
  --// Select check commands                                                                         //--
  ----------------------------------------------------------------------------------------------------

  WITH CheckCommands AS
  (
  SELECT CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN @CheckCommands ELSE SUBSTRING(@CheckCommands, 1, CHARINDEX(',', @CheckCommands) - 1) END AS CheckCommand,
         CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN '' ELSE SUBSTRING(@CheckCommands, CHARINDEX(',', @CheckCommands) + 1, LEN(@CheckCommands)) END AS String,
         CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN 0 ELSE 1 END [Continue]
  WHERE @CheckCommands IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS CheckCommand,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM CheckCommands
  WHERE [Continue] = 1
  )
  INSERT INTO @SelectedCheckCommands (CheckCommand)
  SELECT CheckCommand
  FROM CheckCommands

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand NOT IN('CHECKDB','CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG')) OR EXISTS (SELECT * FROM @SelectedCheckCommands GROUP BY CheckCommand HAVING COUNT(*) > 1) OR NOT EXISTS (SELECT * FROM @SelectedCheckCommands) OR (EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKDB')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG'))) OR (EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKALLOC','CHECKTABLE')))
  BEGIN
    SET @ErrorMessage = 'The value for parameter @CheckCommands is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @PhysicalOnly NOT IN ('Y','N') OR @PhysicalOnly IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for parameter @PhysicalOnly is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @NoIndex NOT IN ('Y','N') OR @NoIndex IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for parameter @NoIndex is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @ExtendedLogicalChecks NOT IN ('Y','N') OR @ExtendedLogicalChecks IS NULL OR (@ExtendedLogicalChecks = 'Y' AND NOT @Version >= 10)
  BEGIN
    SET @ErrorMessage = 'The value for parameter @ExtendedLogicalChecks is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @PhysicalOnly = 'Y' AND @ExtendedLogicalChecks = 'Y'
  BEGIN
    SET @ErrorMessage = 'Extended Logical Checks and Physical Only cannot be used together.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @TabLock NOT IN ('Y','N') OR @TabLock IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for parameter @TabLock is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS(SELECT * FROM @SelectedFileGroups WHERE DatabaseName IS NULL OR FileGroupName IS NULL) OR (@FileGroups IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedFileGroups)) OR (@FileGroups IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP'))
  BEGIN
    SET @ErrorMessage = 'The value for parameter @FileGroups is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS(SELECT * FROM @SelectedObjects WHERE DatabaseName IS NULL OR SchemaName IS NULL OR ObjectName IS NULL) OR (@Objects IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedObjects)) OR (@Objects IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE'))
  BEGIN
    SET @ErrorMessage = 'The value for parameter @Objects is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for parameter @LogToTable is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for parameter @Execute is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ErrorMessage = 'The documentation is available at http://ola.hallengren.com/sql-server-integrity-check.html.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @ReturnCode = @Error
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Check Availability Group cluster name                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @Version >= 11
  BEGIN
    SELECT @Cluster = cluster_name
    FROM sys.dm_hadr_cluster
  END

  ----------------------------------------------------------------------------------------------------
  --// Execute commands                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Completed = 0)
  BEGIN

    SELECT TOP 1 @CurrentID = ID,
                 @CurrentDatabaseName = DatabaseName
    FROM @tmpDatabases
    WHERE Completed = 0
    ORDER BY ID ASC

    SET @CurrentDatabaseID = DB_ID(@CurrentDatabaseName)

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = @CurrentDatabaseID AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END
    ELSE
    BEGIN
      SET @CurrentIsDatabaseAccessible = 0
    END

    IF @Version >= 11 AND @Cluster IS NOT NULL
    BEGIN
      SELECT @CurrentAvailabilityGroup = availability_groups.name,
             @CurrentAvailabilityGroupRole = dm_hadr_availability_replica_states.role_desc
      FROM sys.databases databases
      INNER JOIN sys.availability_databases_cluster availability_databases_cluster ON databases.group_database_id = availability_databases_cluster.group_database_id
      INNER JOIN sys.availability_groups availability_groups ON availability_databases_cluster.group_id = availability_groups.group_id
      INNER JOIN sys.dm_hadr_availability_replica_states dm_hadr_availability_replica_states ON availability_groups.group_id = dm_hadr_availability_replica_states.group_id AND databases.replica_id = dm_hadr_availability_replica_states.replica_id
      WHERE databases.name = @CurrentDatabaseName
    END

    SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
    FROM sys.database_mirroring
    WHERE database_id = @CurrentDatabaseID

    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_primary_databases WHERE primary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'PRIMARY'
    END
    ELSE
    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'SECONDARY'
    END

    -- Set database message
    SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabaseName) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Standby: ' + CASE WHEN DATABASEPROPERTYEX(@CurrentDatabaseName,'IsInStandBy') = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Updateability: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Updateability') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'User access: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Recovery model: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Recovery') AS nvarchar) + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability Group: ' + @CurrentAvailabilityGroup + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability Group role: ' + @CurrentAvailabilityGroupRole + CHAR(13) + CHAR(10)
    IF @CurrentDatabaseMirroringRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Database Mirroring role: ' + @CurrentDatabaseMirroringRole + CHAR(13) + CHAR(10)
    IF @CurrentLogShippingRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Log Shipping role: ' + @CurrentLogShippingRole + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = REPLACE(@DatabaseMessage,'%','%%') + ' '
    RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    AND NOT (DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    BEGIN

      -- Check database
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKDB')
      BEGIN
        SET @CurrentCommandType01 = 'DBCC_CHECKDB'

        SET @CurrentCommand01 = 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabaseName)
        IF @NoIndex = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', NOINDEX'
        SET @CurrentCommand01 = @CurrentCommand01 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @PhysicalOnly = 'N' SET @CurrentCommand01 = @CurrentCommand01 + ', DATA_PURITY'
        IF @PhysicalOnly = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', PHYSICAL_ONLY'
        IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', EXTENDED_LOGICAL_CHECKS'
        IF @TabLock = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', TABLOCK'

        EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @Command = @CurrentCommand01, @CommandType = @CurrentCommandType01, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput01 = @Error
        IF @CurrentCommandOutput01 <> 0 SET @ReturnCode = @CurrentCommandOutput01
      END

      -- Check filegroups
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP')
      BEGIN
        SET @CurrentCommand02 = 'SELECT data_space_id AS FileGroupID, name AS FileGroupName, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.filegroups filegroups ORDER BY CASE WHEN filegroups.name = ''PRIMARY'' THEN 1 ELSE 0 END DESC, filegroups.name ASC'

        INSERT INTO @tmpFileGroups (FileGroupID, FileGroupName, Selected, Completed)
        EXECUTE sp_executesql @statement = @CurrentCommand02
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error
        IF @Error = 1222
        BEGIN
          SET @ErrorMessage = 'The filegroup system table is locked in the database ' + QUOTENAME(@CurrentDatabaseName) + '.' + CHAR(13) + CHAR(10) + ' '
          SET @ErrorMessage = REPLACE(@ErrorMessage,'%','%%')
          RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
        END

        IF @FileGroups IS NULL
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = 1
          FROM @tmpFileGroups tmpFileGroups
        END
        ELSE
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 1

          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 0
        END

        WHILE EXISTS (SELECT * FROM @tmpFileGroups WHERE Selected = 1 AND Completed = 0)
        BEGIN
          SELECT TOP 1 @CurrentFGID = ID,
                       @CurrentFileGroupID = FileGroupID,
                       @CurrentFileGroupName = FileGroupName
          FROM @tmpFileGroups
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY ID ASC

          -- Does the filegroup exist?
          SET @CurrentCommand03 = 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.filegroups filegroups WHERE filegroups.data_space_id = @ParamFileGroupID AND filegroups.[name] = @ParamFileGroupName) BEGIN SET @ParamFileGroupExists = 1 END'

          EXECUTE sp_executesql @statement = @CurrentCommand03, @params = N'@ParamFileGroupID int, @ParamFileGroupName sysname, @ParamFileGroupExists bit OUTPUT', @ParamFileGroupID = @CurrentFileGroupID, @ParamFileGroupName = @CurrentFileGroupName, @ParamFileGroupExists = @CurrentFileGroupExists OUTPUT
          SET @Error = @@ERROR
          IF @Error = 0 AND @CurrentFileGroupExists IS NULL SET @CurrentFileGroupExists = 0
          IF @Error <> 0
          BEGIN
            SET @ReturnCode = @Error
          END

          IF @CurrentFileGroupExists = 1
          BEGIN
            SET @CurrentCommandType04 = 'DBCC_CHECKFILEGROUP'

            SET @CurrentCommand04 = 'USE ' + QUOTENAME(@CurrentDatabaseName) + '; DBCC CHECKFILEGROUP (' + QUOTENAME(@CurrentFileGroupName)
            IF @NoIndex = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', NOINDEX'
            SET @CurrentCommand04 = @CurrentCommand04 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', PHYSICAL_ONLY'
            IF @TabLock = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', TABLOCK'

            EXECUTE @CurrentCommandOutput04 = [dbo].[CommandExecute] @Command = @CurrentCommand04, @CommandType = @CurrentCommandType04, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput04 = @Error
            IF @CurrentCommandOutput04 <> 0 SET @ReturnCode = @CurrentCommandOutput04
          END

          UPDATE @tmpFileGroups
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentFGID

          SET @CurrentFGID = NULL
          SET @CurrentFileGroupID = NULL
          SET @CurrentFileGroupName = NULL
          SET @CurrentFileGroupExists = NULL

          SET @CurrentCommand03 = NULL
          SET @CurrentCommand04 = NULL

          SET @CurrentCommandOutput04 = NULL

          SET @CurrentCommandType04 = NULL
        END
      END

      -- Check disk space allocation structures
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKALLOC')
      BEGIN
        SET @CurrentCommandType05 = 'DBCC_CHECKALLOC'

        SET @CurrentCommand05 = 'DBCC CHECKALLOC (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand05 = @CurrentCommand05 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @TabLock = 'Y' SET @CurrentCommand05 = @CurrentCommand05 + ', TABLOCK'

        EXECUTE @CurrentCommandOutput05 = [dbo].[CommandExecute] @Command = @CurrentCommand05, @CommandType = @CurrentCommandType05, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput05 = @Error
        IF @CurrentCommandOutput05 <> 0 SET @ReturnCode = @CurrentCommandOutput05
      END

      -- Check objects
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE')
      BEGIN
        SET @CurrentCommand06 = 'SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.objects objects INNER JOIN ' + QUOTENAME(@CurrentDatabaseName) + '.sys.schemas schemas ON objects.schema_id = schemas.schema_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes WHERE indexes.object_id = objects.object_id) ORDER BY schemas.name ASC, objects.name ASC'

        INSERT INTO @tmpObjects (SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, Selected, Completed)
        EXECUTE sp_executesql @statement = @CurrentCommand06
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error
        IF @Error = 1222
        BEGIN
          SET @ErrorMessage = 'The object system tables are locked in the database ' + QUOTENAME(@CurrentDatabaseName) + '.' + CHAR(13) + CHAR(10) + ' '
          SET @ErrorMessage = REPLACE(@ErrorMessage,'%','%%')
          RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
        END

        IF @Objects IS NULL
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = 1
          FROM @tmpObjects tmpObjects
        END
        ELSE
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 1

          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 0
        END

        WHILE EXISTS (SELECT * FROM @tmpObjects WHERE Selected = 1 AND Completed = 0)
        BEGIN
          SELECT TOP 1 @CurrentOID = ID,
                       @CurrentSchemaID = SchemaID,
                       @CurrentSchemaName = SchemaName,
                       @CurrentObjectID = ObjectID,
                       @CurrentObjectName = ObjectName,
                       @CurrentObjectType = ObjectType
          FROM @tmpObjects
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY ID ASC

          -- Does the object exist?
          SET @CurrentCommand07 = 'IF EXISTS(SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.objects objects INNER JOIN ' + QUOTENAME(@CurrentDatabaseName) + '.sys.schemas schemas ON objects.schema_id = schemas.schema_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes WHERE indexes.object_id = objects.object_id) AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType) BEGIN SET @ParamObjectExists = 1 END'

          EXECUTE sp_executesql @statement = @CurrentCommand07, @params = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamObjectExists bit OUTPUT', @ParamSchemaID = @CurrentSchemaID, @ParamSchemaName = @CurrentSchemaName, @ParamObjectID = @CurrentObjectID, @ParamObjectName = @CurrentObjectName, @ParamObjectType = @CurrentObjectType, @ParamObjectExists = @CurrentObjectExists OUTPUT
          SET @Error = @@ERROR
          IF @Error = 0 AND @CurrentObjectExists IS NULL SET @CurrentObjectExists = 0
          IF @Error <> 0
          BEGIN
            SET @ReturnCode = @Error
          END

          IF @CurrentObjectExists = 1
          BEGIN
            SET @CurrentCommandType08 = 'DBCC_CHECKTABLE'

            SET @CurrentCommand08 = 'DBCC CHECKTABLE (''' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ''''
            IF @NoIndex = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', NOINDEX'
            SET @CurrentCommand08 = @CurrentCommand08 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @PhysicalOnly = 'N' SET @CurrentCommand08 = @CurrentCommand08 + ', DATA_PURITY'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', PHYSICAL_ONLY'
            IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', EXTENDED_LOGICAL_CHECKS'
            IF @TabLock = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', TABLOCK'

            EXECUTE @CurrentCommandOutput08 = [dbo].[CommandExecute] @Command = @CurrentCommand08, @CommandType = @CurrentCommandType08, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @SchemaName = @CurrentSchemaName, @ObjectName = @CurrentObjectName, @ObjectType = @CurrentObjectType, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput08 = @Error
            IF @CurrentCommandOutput08 <> 0 SET @ReturnCode = @CurrentCommandOutput08
          END

          UPDATE @tmpObjects
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentOID

          SET @CurrentOID = NULL
          SET @CurrentSchemaID = NULL
          SET @CurrentSchemaName = NULL
          SET @CurrentObjectID = NULL
          SET @CurrentObjectName = NULL
          SET @CurrentObjectType = NULL
          SET @CurrentObjectExists = NULL

          SET @CurrentCommand07 = NULL
          SET @CurrentCommand08 = NULL

          SET @CurrentCommandOutput08 = NULL

          SET @CurrentCommandType08 = NULL
        END
      END

      -- Check catalog
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKCATALOG')
      BEGIN
        SET @CurrentCommandType09 = 'DBCC_CHECKCATALOG'

        SET @CurrentCommand09 = 'DBCC CHECKCATALOG (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand09 = @CurrentCommand09 + ') WITH NO_INFOMSGS'

        EXECUTE @CurrentCommandOutput09 = [dbo].[CommandExecute] @Command = @CurrentCommand09, @CommandType = @CurrentCommandType09, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput09 = @Error
        IF @CurrentCommandOutput09 <> 0 SET @ReturnCode = @CurrentCommandOutput09
      END

    END

    -- Update that the database is completed
    UPDATE @tmpDatabases
    SET Completed = 1
    WHERE ID = @CurrentID

    -- Clear variables
    SET @CurrentID = NULL
    SET @CurrentDatabaseID = NULL
    SET @CurrentDatabaseName = NULL
    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentDatabaseMirroringRole = NULL
    SET @CurrentLogShippingRole = NULL

    SET @CurrentCommand01 = NULL
    SET @CurrentCommand02 = NULL
    SET @CurrentCommand05 = NULL
    SET @CurrentCommand06 = NULL
    SET @CurrentCommand09 = NULL

    SET @CurrentCommandOutput01 = NULL
    SET @CurrentCommandOutput05 = NULL
    SET @CurrentCommandOutput09 = NULL

    SET @CurrentCommandType01 = NULL
    SET @CurrentCommandType05 = NULL
    SET @CurrentCommandType09 = NULL

    DELETE FROM @tmpFileGroups
    DELETE FROM @tmpObjects

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120)
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')
  RAISERROR(@EndMessage,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END
GO
