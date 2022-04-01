


------------------------------------------------
create or alter procedure upload.[Shipment.Process]
@UserId bigint, 
@Id int,
@ShowError bit = 1
as
begin
	set nocount on;

	set dateformat dmy;
	with TW as (
		select Upload = @Id, [Date] = cast([����] as date), DocNo = [�����],  Distributor=d.Id, DistributorVoid = d.[Void],
			Product = p.Id, Qty = sum([����������]), [Sum] = sum([����� ���������� ��� ���]),
			[Tender] = case when [������] in (N'���', N'��') then 1 else 0 end,
			[TenderM] = case when [������ ���] in (N'���', N'��') then 1 else 0 end,
			CustomerRegion = drd.Region, AgentRegion = dr.Region,
			Region= isnull(drd.Region, dr.Region),
			CustomerCode = isnull([���������� ���������� ��� �� ������], s.[��� �� ������]),
			CustomerName = isnull(s.[���������� ����������], s.[����������]),
			HasCustomerRegion = cast(case when [���������� ���������� ������] is not null then 1 else 0 end as bit)
		from upload.ShipmentRaw s
		inner join bi.Products p on p.Code1C = s.[��� ������������]
		left join bi.Distributors d on d.Code = s.[��� �� ������]
		left join upload.Distributor_Regions dr on s.[���������� ������] = dr.[Name] and dr.Distributor = 0
		left join upload.Distributor_Regions drd on s.[���������� ���������� ������] = drd.[Name] and drd.Distributor = 0
		where Upload = @Id and [�������] is null
		group by cast([����] as date), p.Id, d.Id, [�����], [������], [������ ���], dr.Region, drd.Region, d.[Void],
			[���������� ���������� ��� �� ������], s.[��� �� ������], s.[���������� ����������], s.[����������],
			s.[���������� ���������� ������]
	)
	select * into #temp from TW

	declare @min date;
	declare @max date;
	select @min = min([Date]), @max = max([Date]) from #temp;

	if month(@min) <> month(@max)
	begin
		update upload.Uploads set Mode = N'ShipmentError' where Id=@Id;
		if @ShowError = 1
		begin
			raiserror(N'UI:�������. ���� ������ ������������ �� ��� �����.', 16, -1) with nowait;
			return;
		end
	end

	declare @from date;
	declare @to date;
	set @from = datefromparts(year(@min), month(@min), 1);
	set @to = eomonth(@from);
	
	delete from bi.SalesDirect where [Date]>=@from and [Date]<=@to;
	delete from bi.Shipment where [Date]>=@from and [Date]<=@to;

	declare @msg nvarchar(max);

	if exists(select * from #temp where Distributor is null and Region is null)
	begin
		with T as (
			select [DocNo] from #temp where Distributor is null and Region is null
			group by [DocNo]
		)
		select @msg = N'UI:�������. ��� ��������� � ��������: ' + string_agg(DocNo, N', ') + N' ��������� ��������� �����'
		from T;
		update upload.Uploads set Mode = N'ShipmentError' where Id=@Id;
		if @ShowError = 1
		begin
			raiserror(@msg, 16, -1) with nowait;
		end
		return;
	end

	if exists(select * from #temp where Tender=1 and HasCustomerRegion=1 and CustomerRegion is null)
	begin
		with T as (
			select [DocNo] from #temp where Tender=1 and HasCustomerRegion=1 and CustomerRegion is null
			group by [DocNo]
		)
		select @msg = N'UI:�������. ��� ��������� � ��������: ' + string_agg(DocNo, N', ') + N' ��������� ��������� ����� ����������'
		from T;
		update upload.Uploads set Mode = N'ShipmentError' where Id=@Id;
		if @ShowError = 1
		begin
			raiserror(@msg, 16, -1) with nowait;
		end
		return;
	end

	/* shipment */
	merge bi.Shipment as t
	using (
	select Upload, [Date], DocNo, Distributor, Product,
		Qty=sum(Qty) 
		from #temp where Distributor is not null and DistributorVoid = 0
	group by Upload, [Date], DocNo, Distributor, Product
	) as s
	on t.[Date] = s.[Date] and t.[DocNo] = s.[DocNo] and t.[Distributor] = s.[Distributor] and t.[Product] = s.[Product]
	when matched then update set
		t.Qty = s.Qty,
		t.Upload = s.Upload
	when not matched by target then insert
		(Upload, [Date], DocNo, Distributor, Product, Qty) values
		(s.Upload, s.[Date], s.[DocNo], s.Distributor, s.Product, s.Qty);
	

	/*customers*/

	with T as (
		select Code = isnull([CustomerCode], N''), [Name] = [CustomerName] 
		from #temp where Distributor is null or Tender=1
		group by isnull([CustomerCode], N''), [CustomerName]
	)
	merge bi.[Customers] as t
	using T as s
	on t.[Code] = isnull(s.[Code], N'')
	when matched then update set
		t.[Name] = s.[Name]
	when not matched by target then insert
		([Code], [Name]) values
		(isnull(s.[Code], N''), s.[Name]);

	/* SalesDirect */
	merge bi.SalesDirect as t
	using (
		select Upload, [Date], [Product], Customer = c.Id, 
			Tender, TenderM, Region,
			Qty = sum(case when Tender = 1 then 0 else s.Qty end),
			QtyT = sum(case when Tender = 1 and TenderM = 0 then s.Qty else 0 end),
			QtyM = sum(case when TenderM = 1 then s.Qty else 0 end),
			[Sum] = sum(case when Tender = 1 then 0 else s.[Sum] end),
			SumT = sum(case when Tender = 1 and TenderM = 0 then s.[Sum] else 0 end),
			SumM = sum(case when TenderM = 1 then s.[Sum] else 0 end)
		from #temp s
			inner join bi.Customers c on s.CustomerCode = c.Code
		where Distributor is null
		group by c.Id,s.Product, s.[Date], s.Upload, Tender, TenderM, Region
	) as s on t.Product = s.Product and t.Region = s.Region and 
		t.[Date] = s.[Date] and t.Customer = s.Customer
	when matched then update set
		t.Upload = s.Upload,
		t.Qty = s.Qty,
		t.QtyT = s.QtyT,
		t.QtyM = s.QtyM,
		t.[Sum] = s.[Sum],
		t.[SumT] = s.[SumT],
		t.[SumM] = s.[SumM],
		t.Tender = s.Tender,
		t.TenderM = s.TenderM
	when not matched by target then insert
		(Upload, [Date], Product, Customer, Region, Qty, QtyT, QtyM, [Sum], [SumT], SumM, Tender, TenderM)
	values
		(Upload, [Date], Product, Customer, Region, Qty, QtyT, QtyM, [Sum], [SumT], SumM, Tender, TenderM);
end
go

exec upload.[Shipment.Process] 99, 5504

