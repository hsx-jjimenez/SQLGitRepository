/*******************************************************************************
  ENTRA ID PERMISSION ASSIGNMET
  Target Groups: HSX-SQLAdmins
*******************************************************************************/

USE master;
GO

-- 1. Explicitly add the EXTERNAL_GROUP to the sysadmin role
ALTER SERVER ROLE [sysadmin] ADD MEMBER [HSX-SQLAdmins];
GO

-- 2. Verify specifically using the name and the expected role
SELECT 
    p.name AS LoginName,
    p.type_desc AS LoginType,
    r.name AS RoleName,
    IS_SRVROLEMEMBER('sysadmin', p.name) AS Is_SysAdmin_Verified
FROM sys.server_principals p
LEFT JOIN sys.server_role_members rm ON p.principal_id = rm.member_principal_id
LEFT JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
WHERE p.name = 'HSX-SQLAdmins' 
  AND p.type_desc = 'EXTERNAL_GROUP';
GO
