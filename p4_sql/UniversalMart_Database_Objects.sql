USE UniversalMart
GO

--Performing Encryption on Customer Table--

-- Step 1: Create a Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'universalmart';

-- Step 2: Create a Certificate
CREATE CERTIFICATE ConsumerCert
WITH SUBJECT = 'Consumer Data Encryption';

-- Step 3: Create a Symmetric Key
CREATE SYMMETRIC KEY ConsumerKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE ConsumerCert;

-- Step 4: Modify the Table Structure
ALTER TABLE CONSUMER
ADD Email_Address_Encrypted VARBINARY(MAX),
    Contact_Number_Encrypted VARBINARY(MAX);

-- Step 5: Encrypt the Data
OPEN SYMMETRIC KEY ConsumerKey
DECRYPTION BY CERTIFICATE ConsumerCert;

UPDATE CONSUMER
SET Email_Address_Encrypted = EncryptByKey(Key_GUID('ConsumerKey'), CONVERT(VARBINARY, Email_Address)),
    Contact_Number_Encrypted = EncryptByKey(Key_GUID('ConsumerKey'), CONVERT(VARBINARY, Contact_Number));

CLOSE SYMMETRIC KEY ConsumerKey;

-- Step 6: Decrypt the Data
OPEN SYMMETRIC KEY ConsumerKey
DECRYPTION BY CERTIFICATE ConsumerCert;

SELECT Consumer_ID, Given_Name, Family_Name,
       CONVERT(VARCHAR, DecryptByKey(Email_Address_Encrypted)) AS DecryptedEmailAddress,
       CONVERT(VARCHAR, DecryptByKey(Contact_Number_Encrypted)) AS DecryptedContactNumber
FROM CONSUMER;

CLOSE SYMMETRIC KEY ConsumerKey;

Select * From CONSUMER;


--- Vendor ---
ALTER TABLE Vendor
ADD Email_Address_Encrypted VARBINARY(MAX),
    Contact_Number_Encrypted VARBINARY(MAX);


CREATE CERTIFICATE VendorCert
WITH SUBJECT = 'vendor Data Encryption';

CREATE SYMMETRIC KEY VendorKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE VendorCert;

-- Encrypt the Email_Address and Contact_Number columns
OPEN SYMMETRIC KEY VendorKey
DECRYPTION BY CERTIFICATE VendorCert;

UPDATE Vendor
SET Email_Address_Encrypted = EncryptByKey(Key_GUID('VendorKey'), CONVERT(VARBINARY, Email_Address)),
    Contact_Number_Encrypted = EncryptByKey(Key_GUID('VendorKey'), CONVERT(VARBINARY, Contact_Number));

CLOSE SYMMETRIC KEY VendorKey;

-- To decrypt and view the data
OPEN SYMMETRIC KEY VendorKey
DECRYPTION BY CERTIFICATE VendorCert;

SELECT Vendor_ID, Vendor_Name, Postal_Address,
       CONVERT(VARCHAR, DecryptByKey(Email_Address_Encrypted)) AS DecryptedEmailAddress,
       CONVERT(VARCHAR, DecryptByKey(Contact_Number_Encrypted)) AS DecryptedContactNumber
FROM Vendor;

CLOSE SYMMETRIC KEY VendorKey;

Select * from Vendor;


---non clustur Index----

CREATE NONCLUSTERED INDEX IDX_BILLING_TRANSACTION_ID
ON BILLING(Transaction_ID);


CREATE NONCLUSTERED INDEX IDX_REVIEW_CONSUMER_ID
ON REVIEW(Consumer_ID);


CREATE NONCLUSTERED INDEX IDX_ORDER_DELIVERY_ID
ON [ORDER](Delivery_ID);


--1. 1st Stored Procedure - GetConsumerDetails;
USE [UniversalMart] -- replace with your actual database name
GO

CREATE PROCEDURE GetConsumerDetails 
    @Consumer_ID INT, 
    @Given_Name VARCHAR(255) OUTPUT, 
    @Family_Name VARCHAR(255) OUTPUT, 
    @Email_Address VARCHAR(255) OUTPUT, 
    @Contact_Number VARCHAR(50) OUTPUT, 
    @Postal_Address VARCHAR(255) OUTPUT, 
    @Consumer_Status VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        @Given_Name = Given_Name,
        @Family_Name = Family_Name,
        @Email_Address = Email_Address,
        @Contact_Number = Contact_Number,
        @Postal_Address = Postal_Address,
        @Consumer_Status = Consumer_Status
    FROM CONSUMER
    WHERE Consumer_ID = @Consumer_ID;
END;
GO

DECLARE 
    @Given_Name VARCHAR(255),
    @Family_Name VARCHAR(255),
    @Email_Address VARCHAR(255),
    @Contact_Number VARCHAR(50),
    @Postal_Address VARCHAR(255),
    @Consumer_Status VARCHAR(50);

EXEC GetConsumerDetails 
    @Consumer_ID = 1, 
    @Given_Name = @Given_Name OUTPUT, 
    @Family_Name = @Family_Name OUTPUT, 
    @Email_Address = @Email_Address OUTPUT, 
    @Contact_Number = @Contact_Number OUTPUT, 
    @Postal_Address = @Postal_Address OUTPUT, 
    @Consumer_Status = @Consumer_Status OUTPUT;

SELECT 
    @Given_Name AS 'Given Name', 
    @Family_Name AS 'Family Name', 
    @Email_Address AS 'Email Address', 
    @Contact_Number AS 'Contact Number', 
    @Postal_Address AS 'Postal Address', 
    @Consumer_Status AS 'Consumer Status';


-- 2nd Stored Procedure - UpdateItemCost;
USE [UniversalMart]
GO

CREATE PROCEDURE UpdateItemCost
    @Item_ID INT,
    @New_Cost DECIMAL(10, 2),
    @Updated_Cost DECIMAL(10, 2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Updating the cost of the item
    UPDATE ITEM
    SET Cost = @New_Cost
    WHERE Item_ID = @Item_ID;

    -- Returning the updated cost for confirmation
    SELECT @Updated_Cost = Cost 
    FROM ITEM 
    WHERE Item_ID = @Item_ID;
END;
GO

DECLARE @Updated_Cost DECIMAL(10, 2);

EXEC UpdateItemCost 
    @Item_ID = 145623,            -- Item ID for 'iPhone 13'
    @New_Cost = 140000.00,           -- The new cost to update to
    @Updated_Cost = @Updated_Cost OUTPUT;

SELECT @Updated_Cost AS New_Cost;

-- 3rd Stored Procedure - GetOrderTotalQuantity;
USE [UniversalMart]; 
GO

CREATE PROCEDURE GetOrderTotalQuantity
    @Order_ID INT,
    @Total_Quantity INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @Total_Quantity = SUM(Order_QTY)
    FROM ORDER_LINE
    WHERE Order_ID = @Order_ID;
END;
GO

DECLARE @Total_Quantity INT;

EXEC GetOrderTotalQuantity 
    @Order_ID = 11112, -- Using Order_ID 11112 from the insertion
    @Total_Quantity = @Total_Quantity OUTPUT;

SELECT @Total_Quantity AS Total_Quantity;

-- DML Trigger:
USE UniversalMart;
GO

CREATE TRIGGER TRG_ReduceItemStockOnOrder
ON ORDER_LINE
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ITEM_CATALOG
    SET Item_Stock_Quantity = Item_Stock_Quantity - i.Order_QTY
    FROM ITEM_CATALOG ic
    INNER JOIN inserted i ON ic.Item_ID = i.ITEM_ID;
END;
GO

-- Inserting a new order line
INSERT INTO ORDER_LINE (Order_ID, ITEM_ID, Order_QTY)
VALUES (11112, 123457, 2);

-- Verifying the updated stock quantity for the item
SELECT Item_ID, Item_Stock_Quantity
FROM ITEM_CATALOG
WHERE Item_ID = 123457;

-- View for Active Consumers
CREATE VIEW ActiveConsumers AS
SELECT Consumer_ID, Given_Name, Family_Name, Email_Address
FROM CONSUMER
WHERE Consumer_Status = 'active';
GO

-- View for Transactions with Overdue Status
CREATE VIEW OverdueTransactions AS
SELECT Transaction_ID, Amount, Transaction_Status, Transaction_method
FROM TRANSACTION_INFORMATION
WHERE Transaction_Status = 'overdue';
GO

-- View for Delivery Status Summary
CREATE VIEW DeliveryStatusSummary AS
SELECT Delivery_Status, COUNT(*) AS NumberOfDeliveries
FROM Delivery
GROUP BY Delivery_Status;
GO



--UDF--

CREATE FUNCTION dbo.CalculateDiscountAmount
(
    @Cost DECIMAL(10, 2),
    @DiscountRate DECIMAL(10, 2) -- The discount rate expressed as a percentage; for example, 10 for 10%
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    -- Calculate the discount amount
    DECLARE @DiscountAmount DECIMAL(10, 2) = @Cost * (@DiscountRate / 100.0);
    
    RETURN @DiscountAmount;
END;
GO


SELECT 
    Item_ID,
    Item_Name,
    Cost,
    -- Assuming a hypothetical discount rate of 15% for all items
    dbo.CalculateDiscountAmount(Cost, 15) AS DiscountAmount
FROM 
    ITEM;
