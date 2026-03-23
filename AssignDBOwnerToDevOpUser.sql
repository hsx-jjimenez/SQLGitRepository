/*This script checks if the user exists in each database first. If they don't, it creates them from the External Provider and then grants the db_owner role.
For DevOps, you typically want to see db_owner on their specific application databases so they can manage schemas and data.
*/

DECLARE @sql NVARCHAR(MAX) = '';

-- This script generates a command for every user database
SELECT @sql += '
USE [' + name + '];
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''HSX-SQLDev'')
BEGIN
    CREATE USER [HSX-SQLDev] FROM EXTERNAL PROVIDER;
END

-- Ensure they are db_owner
ALTER ROLE [db_owner] ADD MEMBER [HSX-SQLDev];

-- Clean up old reader role if it exists
IF IS_ROLEMEMBER(''db_datareader'', ''HSX-SQLDev'') = 1
BEGIN
    ALTER ROLE [db_datareader] DROP MEMBER [HSX-SQLDev];
END
'
FROM sys.databases 
WHERE database_id > 4 -- Skip system DBs (master, model, msdb, tempdb)
  AND state = 0;      -- Only online databases

-- Execute the combined commands
EXEC sp_executesql @sql;
GO

/*After running this, you can verify the access across all databases with this audit query:

DECLARE @audit NVARCHAR(MAX) = 'USE [?]; 
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''HSX-SQLDev'')
SELECT DB_NAME() as DB, name, type_desc FROM sys.database_principals WHERE name = ''HSX-SQLDev''';

EXEC sp_MSforeachdb @audit;
*/
