SELECT 'create login [' + sp.name + '] ' + CASE
        WHEN sp.type IN (
                'U'
                ,'G'
                )
            THEN 'from windows '
        ELSE ''
        END + 'with ' + CASE
        WHEN sp.type = 'S'
            THEN 'password = ' + master.sys.fn_varbintohexstr(sl.password_hash) + ' hashed, ' + 'sid = ' + master.sys.fn_varbintohexstr(sl.sid) + ', check_expiration = ' + CASE
                    WHEN sl.is_expiration_checked > 0
                        THEN 'ON, '
                    ELSE 'OFF, '
                    END + 'check_policy = ' + CASE
                    WHEN sl.is_policy_checked > 0
                        THEN 'ON, '
                    ELSE 'OFF, '
                    END + CASE
                    WHEN sl.credential_id > 0
                        THEN 'credential = ' + c.name + ', '
                    ELSE ''
                    END
        ELSE ''
        END + 'default_database = ' + sp.default_database_name + CASE
        WHEN len(sp.default_language_name) > 0
            THEN ', default_language = ' + sp.default_language_name
        ELSE ''
        END
FROM sys.server_principals sp
LEFT JOIN sys.sql_logins sl ON sp.principal_id = sl.principal_id
LEFT JOIN sys.credentials c ON sl.credential_id = c.credential_id
WHERE sp.type IN (
        'S'
        ,'U'
        ,'G'
        )
    AND sp.name <> 'sa'
    AND sp.name NOT LIKE 'NT Authority%'
    AND sp.name NOT LIKE 'NT Service%'