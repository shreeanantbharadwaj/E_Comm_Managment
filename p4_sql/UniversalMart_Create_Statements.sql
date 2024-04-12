CREATE DATABASE UniversalMart
go
USE UniversalMart
go


-- Creating table for CONSUMER
CREATE TABLE CONSUMER (
    Consumer_ID INT PRIMARY KEY,
    Given_Name VARCHAR(255),
    Family_Name VARCHAR(255),
    Email_Address VARCHAR(255),
    Contact_Number VARCHAR(50),
    Postal_Address VARCHAR(255),
    Consumer_Status VARCHAR(50),
    Starting_Date DATE,
    CHECK (Consumer_Status IN ('active', 'inactive')),
    CHECK (Starting_Date > '2020-01-01')
);


-- Creating table for TRANSACTION_INFORMATION
CREATE TABLE TRANSACTION_INFORMATION (
    Transaction_ID INT PRIMARY KEY,
    Amount DECIMAL(10, 2),
    Rebate DECIMAL(10, 2),
    Transaction_method VARCHAR(50),
    Transaction_Status VARCHAR(50),
    CHECK (Transaction_Status IN ('complete', 'pending', 'overdue'))
);

-- Creating table for BILLING
CREATE TABLE BILLING (
    Billing_ID INT PRIMARY KEY,
    Billing_Date DATE,
    Delivery_Address VARCHAR(255),
    Deadline_Date DATE,
    Billing_Status VARCHAR(50),
    Transaction_ID INT,
    Consumer_ID INT,
    FOREIGN KEY (Consumer_ID) REFERENCES CONSUMER(Consumer_ID),
    FOREIGN KEY (Transaction_ID) REFERENCES TRANSACTION_INFORMATION(Transaction_ID)
);



-- Creating table for Delivery
CREATE TABLE Delivery (
    Delivery_ID INT NOT NULL,
    CONSTRAINT Delivery_ID_PK PRIMARY KEY(Delivery_ID),
    Departure_Date DATE,
    Arrival_Date DATE,
    Delivery_Status VARCHAR(255),
    Delivery_Method VARCHAR(255),
    Package_Weight DECIMAL(10, 2),
    Package_Volume DECIMAL(10, 2),
    Logistic_Status VARCHAR(255),
    CONSTRAINT Logistic_Status_CHK CHECK (Logistic_Status IN ('International','Domestic')),
  );

  -- Creating tables for International
CREATE TABLE International_Logistics (
    International_Logistics_ID INT NOT NULL,
    International_Tariff VARCHAR(255),
    International_Warehouse VARCHAR(255),
    Custom_Duty VARCHAR(255),
    CONSTRAINT International_Logistics_ID_PK PRIMARY KEY (International_Logistics_ID),
    CONSTRAINT International_Logistics_ID_FK FOREIGN KEY (International_Logistics_ID) REFERENCES Delivery(Delivery_ID)
);

--Creating table for Domestic Logistic
CREATE TABLE Domestic_Logistics (
    Domestic_Logistics_ID INT NOT NULL,
    CONSTRAINT Domestic_Logistics_ID_PK PRIMARY KEY(Domestic_Logistics_ID),
    CONSTRAINT Domestic_Logistics_ID_FK FOREIGN KEY (Domestic_Logistics_ID) REFERENCES Delivery(Delivery_ID),
    State_Transfer_Charges VARCHAR(255)
);

--Creating table for Vendor
CREATE TABLE Vendor (
    Vendor_ID INT NOT NULL,
    CONSTRAINT Vendor_ID_PK PRIMARY KEY(Vendor_ID),
    Vendor_Name VARCHAR(100) NOT NULL,
    Email_Address VARCHAR(100) NOT NULL,
    Contact_Number VARCHAR(100) NOT NULL,
    Postal_Address VARCHAR(100) NOT NULL
);

--Creating table for classification
CREATE TABLE [Classification]
(
    Classification_ID INT,
    CONSTRAINT Classification_ID_PK PRIMARY KEY(Classification_ID),
    Classification_Name VARCHAR(100) NOT NULL
);

--Creating table for Item
CREATE TABLE ITEM (
    Item_ID INT PRIMARY KEY,
    Item_Name VARCHAR(255),
    Cost DECIMAL(10, 2),
    Details TEXT,
    Classification_ID INT,
	FOREIGN KEY (Classification_ID) REFERENCES [Classification] (Classification_ID)
);


--Creating table for catalog
CREATE TABLE CATALOG (
    Catalog_ID INT PRIMARY KEY,
    Catalog_Category VARCHAR(255)
);

--Creating table for Order
CREATE TABLE [ORDER] (
    Order_ID INT PRIMARY KEY,
    Order_Date DATE,
    Billing_ID INT,
    Consumer_ID INT,
	Delivery_ID INT,
    FOREIGN KEY (Billing_ID) REFERENCES BILLING (Billing_ID),
    FOREIGN KEY (Consumer_ID) REFERENCES CONSUMER (Consumer_ID),
	FOREIGN KEY (Delivery_ID) REFERENCES DELIVERY (Delivery_ID)
	
);

--Creating table for Order Line
CREATE TABLE ORDER_LINE (
    Order_ID INT,
    ITEM_ID INT,
    Order_QTY INT,
    PRIMARY KEY (Order_ID, ITEM_ID),
	FOREIGN KEY (Order_ID) REFERENCES [Order](Order_ID),
	FOREIGN KEY (ITEM_ID) REFERENCES  ITEM(ITEM_ID)
);

--Creating table for Utilized item
CREATE TABLE UTILIZED_ITEM (
    Item_ID INT,
    Vendor_ID INT,
    Utilized_Date DATE,
    PRIMARY KEY (Item_ID, Vendor_ID),
	FOREIGN KEY (Item_ID) REFERENCES  ITEM(Item_ID),
	FOREIGN KEY (Vendor_ID) REFERENCES  Vendor(Vendor_ID)
);

--Creating table for Review
CREATE TABLE Review (
    Review_ID INT NOT NULL,
    Order_ID INT NOT NULL,
    Consumer_ID INT NOT NULL,
    Review_Text TEXT NOT NULL,
    Review_Rating INT NOT NULL CHECK (Review_Rating BETWEEN 1 AND 5),
    Review_Date DATE NOT NULL,
    CONSTRAINT Review_PK PRIMARY KEY(Review_ID),
    CONSTRAINT Review_Order_ID_FK FOREIGN KEY (Order_ID) REFERENCES [ORDER](Order_ID),
    CONSTRAINT Review_Consumer_ID_FK FOREIGN KEY (Consumer_ID) REFERENCES CONSUMER(Consumer_ID)
);


--Creating table for Item Catalog
CREATE TABLE ITEM_CATALOG (
    Item_ID INT,
    Catalog_ID INT,
    Item_Stock_Quantity INT NOT NULL,
    Item_Location NVARCHAR(255) NOT NULL,
    Received_Date DATE NOT NULL,
    CONSTRAINT PK_ITEM_CATALOG PRIMARY KEY (Item_ID, Catalog_ID),
    CONSTRAINT FK_ITEM_CATALOG_ITEM FOREIGN KEY (Item_ID) REFERENCES ITEM(Item_ID),
    CONSTRAINT FK_ITEM_CATALOG_CATALOG FOREIGN KEY (Catalog_ID) REFERENCES [CATALOG](Catalog_ID)
);
