﻿/* Operation */
-------------------------------------------------
create or alter procedure doc.[Operation.Plain.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Operations!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where TenantId = @TenantId;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Index]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Menu!TMenu!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo, Category,
		[Children!TOperation!LazyArray] = null
	from doc.FormsMenu
	where TenantId = @TenantId
	order by [Order], Id;

	-- children declaration. same as Children proc
	select [!TOperation!Array] = null, [Id!!Id] = Id, [Name!!Name] = [Name], Memo,
		[Journals!TOpJournal!Array] = null
	from doc.Operations where 1 <> 1;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Children]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id nvarchar(32)
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	throw 60000, @Id, 0;
	select [Children!TOperation!Array] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo
	from doc.Operations o;
	--where TenantId = @TenantId; -- and Menu = @Id
	--order by Id;
end
go
-------------------------------------------------
create or alter procedure doc.[Operation.Load]
@TenantId int = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;


	select [Operation!TOperation!Object] = null, [Id!!Id] = o.Id, [Name!!Name] = o.[Name], o.Memo,
		[Form!TForm!RefId] = o.Form,
		[JournalStore!TOpJournalStore!Array] = null,
		[Trans!TOpTrans!Array] = null
	from doc.Operations o
	where o.TenantId = @TenantId and o.Id=@Id;

	select [!TOpJournalStore!Array] = null, [Id!!Id] = Id, RowKind, IsIn, IsOut, 
		IsStorno = case when ojs.Factor = -1 then 1 else 0 end,
		[!TOperation.JournalStore!ParentId] = ojs.Operation
	from doc.OpJournalStore ojs 
	where ojs.TenantId = @TenantId and ojs.Operation = @Id;

	select [!TOpTrans!Array] = null, [Id!!Id] = Id, RowKind, [RowNo!!RowNumber] = RowNo,
		[Plan!TAccount!RefId] = [Plan], [Dt!TAccount!RefId] = Dt, [Ct!TAccount!RefId] = Ct, 
		DtAccMode, DtSum, DtRow, CtAccMode, CtSum, CtRow,
		[!TOperation.Trans!ParentId] = ot.Operation
	from doc.OpTrans ot 
	where ot.TenantId = @TenantId and ot.Operation = @Id
	order by ot.RowKind

	select [!TAccount!Map] = null, [Id!!Id] = a.Id, a.Code, [Name!!Name] = a.[Name],
		a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash
	from doc.OpTrans ot 
		left join acc.Accounts a on ot.TenantId = a.TenantId and a.Id in (ot.[Plan], ot.Dt, ot.Ct)
	where ot.TenantId = @TenantId and ot.Operation = @Id
	group by a.Id, a.Code, a.[Name], a.IsItem, a.IsAgent, a.IsWarehouse, a.IsBankAccount, a.IsCash;

	select [Forms!TForm!Array] = null, [Id!!Id] = df.Id, [Name!!Name] = df.[Name], 
		[RowKinds!TRowKind!Array] = null
	from doc.Forms df
	where df.TenantId = @TenantId
	order by df.[Order], df.Id;

	select [Menu!TMenu!Array] = null, [Id!!Id] = fm.Id, [Name], fm.[Category], 
		Checked = case when ml.Menu is not null then 1 else 0 end
	from doc.FormsMenu fm
		left join ui.OpMenuLinks ml on fm.TenantId = ml.TenantId and ml.Operation = @Id and fm.Id = ml.Menu
	where fm.TenantId = @TenantId
	order by fm.[Order];

	select [!TRowKind!Array] = null, [Id!!Id] = rk.Id, [Name!!Name] = rk.[Name], [!TForm.RowKinds!ParentId] = rk.Form
	from doc.FormRowKinds rk where rk.TenantId = @TenantId
	order by rk.[Order];
end
go
-------------------------------------------------
drop procedure if exists doc.[Operation.Metadata];
drop procedure if exists doc.[Operation.Update];
drop type if exists doc.[Operation.TableType];
drop type if exists doc.[OpJournalStore.TableType];
drop type if exists doc.[OpTrans.TableType];
drop type if exists doc.[OpMenu.TableType]
go
-------------------------------------------------
create type doc.[Operation.TableType]
as table(
	Id bigint null,
	[Menu] nvarchar(32),
	[Form] nvarchar(16),
	[Name] nvarchar(255),
	[Memo] nvarchar(255)
)
go
-------------------------------------------------
create type doc.[OpMenu.TableType]
as table(
	Id nvarchar(32),
	Checked bit
)
go
-------------------------------------------------
create type doc.[OpJournalStore.TableType]
as table(
	Id bigint,
	RowKind nvarchar(8),
	IsIn bit,
	IsOut bit,
	IsStorno bit
)
go
-------------------------------------------------
create type doc.[OpTrans.TableType]
as table(
	Id bigint,
	RowNo int,
	RowKind nvarchar(8),
	[Plan] bigint,
	[Dt] bigint,
	[Ct] bigint,
	DtAccMode nchar(1),
	DtRow nchar(1),
	DtSum nchar(1),
	CtAccMode nchar(1),
	CtRow nchar(1),
	CtSum nchar(1)
)
go
------------------------------------------------
create or alter procedure doc.[Operation.Metadata]
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;
	declare @Operation doc.[Operation.TableType];
	declare @JournalStore doc.[OpJournalStore.TableType];
	declare @OpTrans doc.[OpTrans.TableType];
	declare @OpMenu doc.[OpMenu.TableType];
	select [Operation!Operation!Metadata] = null, * from @Operation;
	select [JournalStore!Operation.JournalStore!Metadata] = null, * from @JournalStore;
	select [Trans!Operation.Trans!Metadata] = null, * from @OpTrans;
	select [Menu!Menu!Metadata] = null, * from @OpMenu;
end
go
------------------------------------------------
create or alter procedure doc.[Operation.Update]
@TenantId bigint = 1,
@CompanyId bigint = 0,
@UserId bigint,
@Operation doc.[Operation.TableType] readonly,
@JournalStore doc.[OpJournalStore.TableType] readonly,
@Trans doc.[OpTrans.TableType] readonly,
@Menu doc.[OpMenu.TableType] readonly
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	
	declare @rtable table(id bigint);
	declare @Id bigint;

	merge doc.Operations as t
	using @Operation as s
	on t.TenantId = @TenantId and t.Id = s.Id
	when matched then update set
		t.[Name] = s.[Name],
		t.[Memo] = s.[Memo],
		t.[Form] = s.[Form]
	when not matched by target then insert
		(TenantId, [Name], Form, Memo) values
		(@TenantId, s.[Name], s.Form, s.Memo)
	output inserted.Id into @rtable(id);
	select top(1) @Id = id from @rtable;

	merge doc.OpJournalStore as t
	using @JournalStore as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowKind = isnull(s.RowKind, N''),
		t.IsIn = s.IsIn,
		t.IsOut = s.IsOut,
		t.Factor = case when s.IsStorno = 1 then -1 else 1 end
	when not matched by target then insert
		(TenantId, Operation, RowKind, IsIn, IsOut, Factor) values
		(@TenantId, @Id, isnull(RowKind, N''), s.IsIn, s.IsOut, case when s.IsStorno = 1 then -1 else 1 end)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	merge doc.OpTrans as t
	using @Trans as s
	on t.TenantId=@TenantId and t.Operation = @Id and t.Id = s.Id
	when matched then update set 
		t.RowNo = s.RowNo,
		t.RowKind = isnull(s.RowKind, N''),
		t.[Plan] = s.[Plan],
		t.[Dt] = s.[Dt],
		t.[Ct] = s.[Ct],
		t.DtAccMode = s.DtAccMode,
		t.CtAccMode = s.CtAccMode,
		t.DtRow = s.DtRow,
		t.CtRow = s.CtRow,
		t.DtSum = s.DtSum,
		t.CtSum = s.CtSum
	when not matched by target then insert
		(TenantId, Operation, RowNo, RowKind, [Plan], Dt, Ct, DtAccMode, CtAccMode, DtRow, CtRow, 
			DtSum, CtSum) values
		(@TenantId, @Id, RowNo, isnull(RowKind, N''), s.[Plan], s.Dt, s.Ct, s.DtAccMode, s.CtAccMode, s.DtRow, s.CtRow, 
			s.DtSum, s.CtSum)
	when not matched by source and t.TenantId=@TenantId and t.Operation = @Id then delete;

	with OM as (select Id from @Menu where Checked = 1)
	merge ui.OpMenuLinks as t
	using OM as s
	on t.TenantId = @TenantId and t.Operation = @Id and t.Menu = s.Id
	when not matched by target then insert
		(TenantId, Operation, Menu) values
		(@TenantId, @Id, s.Id)
	when not matched by source and t.TenantId = @TenantId and t.Operation = @Id then delete;

	exec doc.[Operation.Load] @TenantId = @TenantId, @CompanyId = @CompanyId, @UserId = @UserId,
		@Id = @Id;
end
go
