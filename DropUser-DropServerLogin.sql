/* This script will check every database, drop the user HOTSPEX\HSX-SQLDev if it exists, and then finally drop the server-level login.
For any other user, update @OldLogin
*/

DECLARE @OldLogin SYSNAME = 'HOTSPEX\HSX-SQLDev';
DECLARE @DBName SYSNAME;
DECLARE @DynamicSQL NVARCHAR(MAX);

-- 1. Drop the User from all databases first
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
WHERE database_id > 4 AND state_desc = 'ONLINE'; 

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DynamicSQL = '
    USE [' + @DBName + '];
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @OldLgn)
    BEGIN
        -- Check if the user owns any schemas (which would block a DROP)
        IF EXISTS (SELECT 1 FROM sys.schemas WHERE REVERSE(QUOTENAME(name)) = REVERSE(QUOTENAME(@OldLgn)))
        BEGIN
            PRINT ''   - WARNING: User owns a schema in [' + @DBName + ']. Manual intervention required.'';
        END
        ELSE
        BEGIN
            DROP USER [' + @OldLogin + '];
            PRINT ''   - Dropped User from database: [' + @DBName + ']'';
        END
    END';

    EXEC sp_executesql @DynamicSQL, N'@OldLgn SYSNAME', @OldLgn = @OldLogin;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- 2. Finally, drop the Server-Level Login
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @OldLogin)
BEGIN
    BEGIN TRY
        SET @DynamicSQL = 'DROP LOGIN [' + @OldLogin + ']';
        EXEC sp_executesql @DynamicSQL;
        PRINT '>>> SUCCESS: Server login [' + @OldLogin + '] has been dropped.';
    END TRY
    BEGIN CATCH
        PRINT '>>> ERROR: Could not drop login. It might be a session owner or endpoint owner.';
        PRINT ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT '>>> Login [' + @OldLogin + '] was already removed or does not exist.';
END
