/*Assign Server-Level Role (dbcreator)
This allows the DevOps team to create, alter, and drop their own databases, which is common for CI/CD pipelines and development environments.*/

USE master;
GO

-- Add the Entra Group to the dbcreator fixed server role
ALTER SERVER ROLE [dbcreator] ADD MEMBER [HSX-SQLDev];
GO

-- Verify the change
SELECT 
    r.name AS RoleName, 
    m.name AS MemberName 
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
WHERE m.name = 'HSX-SQLDev';
