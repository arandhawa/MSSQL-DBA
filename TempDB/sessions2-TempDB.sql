SELECT database_transaction_log_bytes_reserved, 
       session_id 
FROM   sys.dm_tran_database_transactions AS tdt 
       INNER JOIN sys.dm_tran_session_transactions AS tst 
               ON tdt.transaction_id = tst.transaction_id 
WHERE  database_id = 2; 