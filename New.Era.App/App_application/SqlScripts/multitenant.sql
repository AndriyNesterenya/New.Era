﻿/*
version: 10.1.1012
generated: 08.04.2022 22:17:59
*/


/* SqlScripts/multitenant.sql */

/*
startup multitenant
*/

-------------------------------------------------
create or alter procedure appsec.OnCreateTenant 
@TenantId int
as
begin
	set nocount on
	exec ini.[Cat.OnCreateTenant] @TenantId = @TenantId;
	exec ini.[Forms.OnCreateTenant] @TenantId = @TenantId;
end
go

