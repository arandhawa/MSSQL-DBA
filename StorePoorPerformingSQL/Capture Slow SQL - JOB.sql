USE [msdb]
GO

/****** Object:  Job [Capture Slow SQL]  ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]   ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Capture Slow SQL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Capture Slow SQL]   ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Capture Slow SQL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO [DBA].[dbo].[My_Slow_Query_Cache]
SELECT TOP 20
    GETDATE() AS "Collection Date",
    qs.execution_count AS "Execution Count",
    SUBSTRING(qt.text,qs.statement_start_offset/2 +1, 
                 (CASE WHEN qs.statement_end_offset = -1 
                       THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
                       ELSE qs.statement_end_offset END -
                            qs.statement_start_offset
                 )/2
             ) AS "Query Text", 
     DB_NAME(qt.dbid) AS "DB Name",
     qs.total_worker_time AS "Total CPU Time",
     qs.total_worker_time/qs.execution_count AS "Avg CPU Time (ms)",     
     qs.total_physical_reads AS "Total Physical Reads",
     qs.total_physical_reads/qs.execution_count AS "Avg Physical Reads",
     qs.total_logical_reads AS "Total Logical Reads",
     qs.total_logical_reads/qs.execution_count AS "Avg Logical Reads",
     qs.total_logical_writes AS "Total Logical Writes",
     qs.total_logical_writes/qs.execution_count AS "Avg Logical Writes",
     qs.total_elapsed_time AS "Total Duration",
     qs.total_elapsed_time/qs.execution_count AS "Avg Duration (ms)",
     qp.query_plan AS "Plan"
FROM sys.dm_exec_query_stats AS qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE 
     qs.execution_count > 50 OR
     qs.total_worker_time/qs.execution_count > 100 OR
     qs.total_physical_reads/qs.execution_count > 1000 OR
     qs.total_logical_reads/qs.execution_count > 1000 OR
     qs.total_logical_writes/qs.execution_count > 1000 OR
     qs.total_elapsed_time/qs.execution_count > 1000
ORDER BY 
     qs.execution_count DESC,
     qs.total_elapsed_time/qs.execution_count DESC,
     qs.total_worker_time/qs.execution_count DESC,
     qs.total_physical_reads/qs.execution_count DESC,
     qs.total_logical_reads/qs.execution_count DESC,
     qs.total_logical_writes/qs.execution_count DESC', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120120, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

