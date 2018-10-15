SELECT R1.session_id, 
       R1.request_id, 
       R1.task_request_internal_objects_alloc_page_count, 
       R1.task_request_internal_objects_dealloc_page_count, 
       R1.task_request_user_objects_alloc_page_count, 
       R1.task_request_user_objects_dealloc_page_count, 
       R3.session_request_internal_objects_alloc_page_count, 
       R3.session_request_internal_objects_dealloc_page_count, 
       R3.session_request_user_objects_alloc_page_count, 
       R3.session_request_user_objects_dealloc_page_count, 
       R2.sql_handle, 
       RL2.text AS SQLText, 
       R2.statement_start_offset, 
       R2.statement_end_offset, 
       R2.plan_handle 
FROM   (SELECT session_id, 
               request_id, 
               Sum(internal_objects_alloc_page_count)  AS 
               Task_request_internal_objects_alloc_page_count, 
               Sum(internal_objects_dealloc_page_count)AS 
               Task_request_internal_objects_dealloc_page_count, 
               Sum(user_objects_alloc_page_count)      AS 
                      Task_request_user_objects_alloc_page_count, 
               Sum(user_objects_dealloc_page_count)    AS 
               Task_request_user_objects_dealloc_page_count 
        FROM   sys.dm_db_task_space_usage 
        GROUP  BY session_id, 
                  request_id) R1 
       INNER JOIN (SELECT session_id, 
                          Sum(internal_objects_alloc_page_count)  AS 
                          Session_request_internal_objects_alloc_page_count, 
                          Sum(internal_objects_dealloc_page_count)AS 
                          Session_request_internal_objects_dealloc_page_count, 
                          Sum(user_objects_alloc_page_count)      AS 
                          Session_request_user_objects_alloc_page_count, 
                          Sum(user_objects_dealloc_page_count)    AS 
                          Session_request_user_objects_dealloc_page_count 
                   FROM   sys.dm_db_session_space_usage 
                   GROUP  BY session_id) R3 
               ON R1.session_id = R3.session_id 
       LEFT OUTER JOIN sys.dm_exec_requests R2 
                    ON R1.session_id = R2.session_id 
                       AND R1.request_id = R2.request_id 
       OUTER apply sys.Dm_exec_sql_text(R2.sql_handle) AS RL2 
WHERE  task_request_internal_objects_alloc_page_count > 0 
        OR task_request_internal_objects_dealloc_page_count > 0 
        OR task_request_user_objects_alloc_page_count > 0 
        OR task_request_user_objects_dealloc_page_count > 0 
        OR session_request_internal_objects_alloc_page_count > 0 
        OR session_request_internal_objects_dealloc_page_count > 0 
        OR session_request_user_objects_alloc_page_count > 0 
        OR session_request_user_objects_dealloc_page_count > 0 
		