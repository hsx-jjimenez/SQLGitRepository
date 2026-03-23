/* Grant Explicit Metadata Permissions
This fixes the issue where they can only "Connect" but cannot see the "Security" folder or other databases in the SSMS Object Explorer.
You should see VIEW ANY DEFINITION and VIEW ANY DATABASE to ensure they don't have the "hidden login" issue 
*/

USE master;
GO

-- Grant visibility of all logins and object definitions
GRANT VIEW ANY DEFINITION TO [HSX-SQLDev];

-- Grant visibility of the database list in the tree view
GRANT VIEW ANY DATABASE TO [HSX-SQLDev];
GO

-- Verify the explicit permissions
SELECT 
    permission_name, 
    state_desc 
FROM sys.server_permissions pe
JOIN sys.server_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'HSX-SQLDev';
