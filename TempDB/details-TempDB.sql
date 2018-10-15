SELECT NAME         AS filename, 
       size*1.0/128 AS filesizeinmb, 
       CASE max_size 
              WHEN 0 THEN 'Autogrowth is off.' 
              WHEN -1 THEN 'Autogrowth is on.' 
              ELSE 'Log file will grow to a maximum size of 2 TB.' 
       END    autogrowthstatus, 
       growth AS 'GrowthValue', 
       'GrowthIncrement' = 
       CASE 
              WHEN growth = 0 THEN 'Size is fixed and will not grow.' 
              WHEN growth &amp;amp;gt;0 
              AND 
              is_percent_growth = 0 THEN 
              'Growth value is in 8-KB pages.' 
              ELSE 'Growth value is a percentage.' 
            END 
            FROM tempdb.sys.database_files;go