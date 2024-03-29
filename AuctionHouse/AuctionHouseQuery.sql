DROP DATABASE IF EXISTS AuctionHouse;
CREATE DATABASE AuctionHouse;
GO

USE AuctionHouse;
GO

CREATE TABLE [User](
    Id INT IDENTITY(1,1),
    Username VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT PK_User PRIMARY KEY(Id)
);

go

CREATE TABLE [Item](
    Id INT IDENTITY(1,1),
    [Name] VARCHAR(50) NOT NULL,
    BuyOutPrice INT NOT NULL,
    BaseBidPrice INT NOT NULL,
    SellerId INT,
    CONSTRAINT PK_Item PRIMARY KEY(Id),
    CONSTRAINT FK_Item_User FOREIGN KEY(SellerId) REFERENCES [User](Id) ON DELETE SET NULL
);

go

CREATE TABLE [Bid](
    Id INT IDENTITY(1,1),
    BidPrice INT NOT NULL,
    ItemId INT,
    Bidder INT,
    CONSTRAINT PK_Bid PRIMARY KEY(Id),
    CONSTRAINT FK_Bid_User FOREIGN KEY(Bidder) REFERENCES [User](Id) ON DELETE SET NULL,
    CONSTRAINT FK_Bid_Item FOREIGN KEY(ItemId) REFERENCES [Item](Id) ON DELETE SET NULL
);

go

CREATE PROCEDURE CreateUser 
    @Username NVARCHAR(50)
AS
BEGIN
    INSERT INTO [User](Username)
    VALUES (@Username);
END;

go

CREATE PROCEDURE AddItem 
    @Name NVARCHAR(50),
    @BuyOutPrice INT,
    @BaseBidPrice INT,
    @SellerId INT
AS
BEGIN
    INSERT INTO [Item]([Name], BuyOutPrice, BaseBidPrice, SellerId)
    VALUES (@Name, @BuyOutPrice, @BaseBidPrice, @SellerId);
END;

go

CREATE PROCEDURE BidOnItem 
    @BidPrice INT,
    @ItemId INT,
    @BidderId INT
AS
BEGIN
    DECLARE @BaseBidPrice INT;

    SELECT @BaseBidPrice = BaseBidPrice
    FROM [Item]
    WHERE @ItemId = Id;

    IF @BaseBidPrice IS NOT NULL
    BEGIN
        IF @BidPrice > @BaseBidPrice
        BEGIN
            DECLARE @ExistingBidPrice INT;

            SELECT @ExistingBidPrice = BidPrice
            FROM [Bid]
            WHERE ItemId = @ItemId;

            IF @BidPrice > COALESCE(@ExistingBidPrice, 0)
            BEGIN
                INSERT INTO [Bid] (BidPrice, ItemId, Bidder)
                VALUES (@BidPrice, @ItemId, @BidderId);
            END
            ELSE
            BEGIN
                RAISERROR('BidPrice must be higher than the current highest bid price.', 16, 1);
            END;
        END
        ELSE
        BEGIN
            RAISERROR('BidPrice must be higher than BaseBidPrice.', 16, 1);
        END;
    END
    ELSE
    BEGIN
        RAISERROR('Item does not exist.', 16, 1);
    END;
END;

go

CREATE PROCEDURE UserItems 
    @Username NVARCHAR(50)
AS
BEGIN
    SELECT u.Username, i.[Name]
    FROM [User] u
    INNER JOIN [Item] i ON u.Id = i.SellerId
    WHERE u.Username = @Username;
END;

go

CREATE PROCEDURE UserBids 
    @Username NVARCHAR(50)
AS
BEGIN
    SELECT u.Username, b.Id
    FROM [User] u
    INNER JOIN [Bid] b ON u.Id = b.Bidder
    WHERE u.Username = @Username;
END;

go

CREATE PROCEDURE ItemBids 
    @Id INT
AS
BEGIN
    SELECT i.[Name], b.Id
    FROM [Item] i
    INNER JOIN [Bid] b ON i.Id = b.ItemId
    WHERE i.Id = @Id;
END;

go
CREATE TRIGGER trDeleteUser
ON [User]
AFTER DELETE
AS
BEGIN
    DELETE FROM [Bid]
    WHERE Bidder IS NULL;


    DELETE FROM [Item]
    WHERE SellerId IS NULL;

END;

go

CREATE TRIGGER trDeleteItem
ON [Item]
AFTER DELETE
AS
BEGIN
    DELETE FROM [Bid]
    WHERE ItemId IS NULL;
END;

go

CREATE TRIGGER trRemovePreviousBidder
ON [Bid]
AFTER INSERT
AS
BEGIN
    CREATE TABLE #PreviousBidder (
        ItemId INT,
        PreviousBidderId INT
    );

    INSERT INTO #PreviousBidder (ItemId, PreviousBidderId)
    SELECT i.ItemId, b.Bidder
    FROM inserted i
    JOIN Bid b ON i.ItemId = b.ItemId
    WHERE b.Id < (SELECT MAX(Id) FROM inserted WHERE ItemId = i.ItemId);

    DELETE b
    FROM [Bid] b
    INNER JOIN #PreviousBidder pb ON b.ItemId = pb.ItemId
    WHERE b.Bidder = pb.PreviousBidderId;

    DROP TABLE #PreviousBidder;
END;


