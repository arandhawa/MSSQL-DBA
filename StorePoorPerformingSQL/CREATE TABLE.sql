CREATE TABLE [DBA].[dbo].[My_Slow_Query_Cache] (
 [Collection Date] [datetime] NOT NULL,
 [Execution Count] [bigint] NULL,
 [Query Text] [nvarchar](max) NULL,
 [DB Name] [sysname] NULL,
 [Total CPU Time] [bigint],
 [Avg CPU Time (ms)] [bigint] NULL,
 [Total Physical Reads] [bigint] NULL,
 [Avg Physical Reads] [bigint] NULL,
 [Total Logical Reads] [bigint] NULL,
 [Avg Logical Reads] [bigint] NULL,
 [Total Logical Writes] [bigint] NULL,
 [Avg Logical Writes] [bigint] NULL,
 [Total Duration] [bigint] NULL,
 [Avg Duration (ms)] [bigint] NULL,
 [Plan] [xml] NULL
) ON [PRIMARY]
GO