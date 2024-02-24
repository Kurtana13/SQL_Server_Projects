drop database AuctionHouse

create database AuctionHouse

go

use AuctionHouse

create table [User](
Id int identity(1,1),
Username varchar(50) not null unique,
constraint PK_User primary key(Id)
)

go

create table [Item](
Id int identity(1,1),
[Name] varchar(50) not null,
BuyOutPrice int not null,
BaseBidPrice int not null,
SellerId int not null,
constraint PK_Item primary key(Id),
constraint FK_Item_User foreign key(SellerId) references [User](Id)
)

go

create table [Bid](
Id int identity(1,1),
BidPrice int not null,
ItemId int not null,
Bidder int not null,
constraint PK_Bid primary key(Id),
constraint FK_Bid_User foreign key(Bidder) references [User](Id),
constraint FK_Bid_Item foreign Key(ItemId) references [Item](Id)
)

go

create procedure CreateUser @Username nvarchar(50)
as
Insert into [User](Username)
values(@Username)

go

create procedure AddItem @Name nvarchar(50),@BuyOutPrice int,@BaseBidPrice int,@SellerId int
as
Insert into [Item]([Name],BuyOutPrice,BaseBidPrice,SellerId)
values(@Name,@BuyOutPrice,@BaseBidPrice,@SellerId)

go

create procedure BidOnItem
@BidPrice int,
@ItemId int,
@BidderId int
as
Begin
	Declare @BaseBidPrice int;

	Select @BaseBidPrice = BaseBidPrice
	from [Item]
	where @ItemId = Id

	IF @BidPrice > @BaseBidPrice
	Begin
		Insert into [Bid](BidPrice,ItemId,Bidder)
		values(@BidPrice,@ItemId,@BidderId)
	End
	ELSE
	Begin
		RAISERROR('BidPrice must be higher than BaseBidPrice.', 16, 1)
	End
End

go

create procedure UserItems @Username nvarchar(50)
as
select Username,[Name]
from [User] u
inner join [Item] i on
u.Id = i.SellerId
where u.Username = @Username

go

create procedure UserBids @Username nvarchar(50)
as
select Username,b.Id
from [User] u
inner join [Bid] b on
u.Id = b.Bidder
where u.Username = @Username

go


create procedure ItemBids @Id int
as
select [Name], b.Id
from [Item] i
inner join [Bid] b on
i.Id = b.ItemId
where i.Id = @Id

go


create trigger trDeleteUser
on [User]
after delete
as
Begin
	Declare @Id int
	select @Id = Id from deleted

	delete i
	from [Item] i
	inner join [User] u
	on i.SellerId = u.Id
	where i.SellerId = @Id

	delete b
	from [Bid] b
	inner join [User] u
	on b.Bidder = u.Id
	where b.Bidder = @Id
End

go

create trigger trDeleteItem
on [Item]
after delete
as
Begin
	Declare @Id int
	select @Id = Id from deleted

	delete b
	from [Bid] b
	inner join [Item] i
	on b.Bidder = i.Id
	where b.Bidder = @Id
End

go

create trigger trRemovePreviousBidder
on [Bid]
after insert
as
Begin
	create table #PreviousBidder (
        ItemId INT,
        PreviousBidderId INT
    );
	
	insert into #PreviousBidder (ItemId, PreviousBidderId)
    select i.ItemId, b.Bidder
    from inserted i
    join Bid b on i.ItemId = b.ItemId
    where b.Id < (select MAX(Id) from inserted where ItemId = i.ItemId);

	delete b
	from [Bid] b
	inner join #PreviousBidder pb on b.ItemId = pb.ItemId
	where b.Bidder = pb.PreviousBidderId
	
	drop table #PreviousBidder
end
