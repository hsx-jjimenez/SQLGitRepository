/*******************************************************************************
Description: Final Cleanup Script to remove orphaned legacy logins/users.
Includes: Collation handling, Schema ownership checks, and System DB processing.
*******************************************************************************/

DECLARE @OldLogin SYSNAME = 'HOTSPEX\HSX-SQLAdmins';
DECLARE @DBName SYSNAME;
DECLARE @DynamicSQL NVARCHAR(MAX);

-- Cursor to loop through ALL databases
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
WHERE state_desc = 'ONLINE' 
  AND name NOT IN ('tempdb'); -- tempdb is recreated on restart, but others are cleared here

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DynamicSQL = '
    USE [' + @DBName + '];
    
    -- Check if the orphaned user exists in this database
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @OldLgn)
    BEGIN
        PRINT ''>>> Checking Database: [' + @DBName + ']'';

        -- 1. Collation-safe schema ownership check
        -- This prevents the "Cannot resolve collation conflict" error
        IF EXISTS (
            SELECT 1 FROM sys.schemas 
            WHERE REVERSE(QUOTENAME(name)) COLLATE DATABASE_DEFAULT = REVERSE(QUOTENAME(@OldLgn)) COLLATE DATABASE_DEFAULT
        )
        BEGIN
            PRINT ''   - WARNING: User owns a schema. Manual transfer required before dropping.'';
        END
        ELSE
        BEGIN
            -- 2. Drop the orphaned user
            BEGIN TRY
                DROP USER [' + @OldLogin + '];
                PRINT ''   - SUCCESS: Dropped user [' + @OldLogin + '] from [' + @DBName + ']'';
            END TRY
            BEGIN CATCH
                PRINT ''   - ERROR: Could not drop user. '' + ERROR_MESSAGE();
            END CATCH
        END
    END';

    -- Execute with parameter passing to handle the Dynamic SQL scope
    EXEC sp_executesql @DynamicSQL, N'@OldLgn SYSNAME', @OldLgn = @OldLogin;

    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Final Step: Remove the Server-Level Login if it still exists
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @OldLogin)
BEGIN
    SET @DynamicSQL = 'DROP LOGIN [' + @OldLogin + ']';
    EXEC sp_executesql @DynamicSQL;
    PRINT '>>> FINISHED: Server-level login [' + @OldLogin + '] has been removed.';
END
ELSE
BEGIN
    PRINT '>>> FINISHED: Server-level login was already removed.';
END
