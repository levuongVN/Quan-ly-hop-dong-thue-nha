CREATE DATABASE ManagementHouse
USE ManagementHouse
DROP TABLE IF EXISTS PaymentDetail;
DROP TABLE IF EXISTS ContractDetail;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Contract;
DROP TABLE IF EXISTS Property;
DROP TABLE IF EXISTS LandLord;
DROP TABLE IF EXISTS Tenant;
DROP VIEW IF EXISTS ActiveContracts, AvailableProperties, PropertiesBySpecificOwner, ContactInformation, 
    CurrentTenantByProperty, ContractChangeHistory, ContractDepositTerms, PaymentServiceDetails, TotalPayments;
DROP PROCEDURE IF EXISTS InsertTenant, UpdateTenant, DeleteTenant, UpdateContractDetail;
--******Tạo các bảng *******
CREATE TABLE Tenant( -- Bảng Người thuê
    TenantID INT IDENTITY(1,1) PRIMARY KEY, -- Mã người thuê (mã hóa)
    NameTenant NVARCHAR(50), -- Tên người thuê
    IdentifyNumber VARCHAR(12), -- Số CMND/CCCD (mã hóa)
    PhoneNumber VARCHAR(10), -- Số điện thoại (mã hóa)
    Email VARCHAR(250), -- Email
    AddressTenant NVARCHAR(300) -- Địa chỉ người thuê
)

CREATE TABLE LandLord( -- Bảng Chủ nhà
    LandLordID INT IDENTITY(1,1) PRIMARY KEY, -- Mã chủ nhà (mã hóa)
    NameLandLord NVARCHAR(50), -- Tên chủ nhà
    IdentifyNumber VARCHAR(12), -- Số CMND/CCCD (mã hóa)
    PhoneNumber VARCHAR(10), -- Số điện thoại (mã hóa)
    Email VARCHAR(250), -- Email
    AddressLandLord NVARCHAR(300) -- Địa chỉ chủ nhà
)

CREATE TABLE Property( -- Bảng Bất động sản
    PropertyID INT IDENTITY(1,1) PRIMARY KEY, -- Mã bất động sản (mã hóa)
    LandLordID INT NOT NULL,
    AddressProperty NVARCHAR(300), -- Địa chỉ bất động sản
    TypeProperty NVARCHAR(50), -- Loại bất động sản (căn hộ, nhà nguyên căn, v.v.)
    AreaProperty DECIMAL(10,2), -- Diện tích (m²)
    RentCost DECIMAL(10,2), -- Giá thuê (VND)
    StatusProperty NVARCHAR(10), -- Trạng thái (Đã thuê/Chưa thuê)
    FOREIGN KEY (LandLordID) REFERENCES LandLord(LandLordID) 
)

CREATE TABLE Contract( -- Bảng Hợp đồng
    ContractID INT IDENTITY(1,1) PRIMARY KEY, -- Mã hợp đồng (mã hóa)
    TenantID INT NOT NULL, -- Mã người thuê (mã hóa)
    PropertyID INT NOT NULL, -- Mã bất động sản (mã hóa)
    StartDate DATE, -- Ngày bắt đầu hợp đồng
    EndDate DATE, -- Ngày kết thúc hợp đồng
    ContractStatus NVARCHAR(50), -- Trạng thái hợp đồng (Còn hiệu lực/Hết hạn)
    FOREIGN KEY(TenantID) REFERENCES Tenant(TenantID),
    FOREIGN KEY(PropertyID) REFERENCES Property(PropertyID)
)

CREATE TABLE Payment( -- Bảng Thanh toán
    PaymentID INT IDENTITY(1,1) PRIMARY KEY, -- Mã thanh toán (mã hóa)
    TenantID INT NOT NULL, -- Mã người thuê (mã hóa)
    ContractID INT NOT NULL, -- Mã hợp đồng (mã hóa)
    PaymentMethod NVARCHAR(50), -- Phương thức thanh toán (Tiền mặt, Chuyển khoản)
    Note NVARCHAR(300) NULL, -- Ghi chú
    FOREIGN KEY(TenantID) REFERENCES Tenant(TenantID),
    FOREIGN KEY(ContractID) REFERENCES Contract(ContractID)
)

CREATE TABLE ContractDetail(
    ContractDetailID INT PRIMARY KEY, -- Mã chi tiết hợp đồng
    Deposit DECIMAL(10,2) NOT NULL, -- Tiền đặt cọc
    ChangeDate DATE, -- Ngày thay đổi hợp đồng
    ContentChange NVARCHAR(300), -- Nội dung thay đổi hợp đồng
    PeopleChange NVARCHAR(50), -- Người thực hiện thay đổi
    Note NVARCHAR(300), -- Ghi chú
    FOREIGN KEY(ContractDetailID) REFERENCES Contract(ContractID)
);


CREATE TABLE PaymentDetail(
    PaymentDetailID INT PRIMARY KEY, -- Mã chi tiết thanh toán
    TenantID INT, -- Mã người thuê
    PaymentDate DATE NULL, -- Ngày thanh toán
    AmountMoney DECIMAL(10,2) NOT NULL, -- Số tiền thanh toán
    SpendToServices NVARCHAR(150), -- Khoản chi tiêu cho dịch vụ
    PaymentStatus NVARCHAR(50), -- Trạng thái thanh toán
    FOREIGN KEY(TenantID) REFERENCES Tenant(TenantID),
    FOREIGN KEY(PaymentDetailID) REFERENCES Payment(PaymentID)
);


--******Các truy vấn thông tin với view******
-- 1. Truy vấn thông tin hợp đồng
-- Danh sách các hợp đồng đang hoạt động ( Gộp danh sách hợp đồng đang hoạt động và hợp đồng sắp hết hạn vào làm một bằng cách thêm câu lệnh sắp xếp thời gian hết hạn)
GO
CREATE VIEW ActiveContracts AS
SELECT C.ContractID, T.NameTenant, P.AddressProperty, C.StartDate, C.EndDate, C.ContractStatus  
FROM Contract C
JOIN Tenant T ON C.TenantID = T.TenantID  
JOIN Property P ON C.PropertyID = P.PropertyID 
WHERE C.ContractStatus = 'Active';
GO
SELECT * FROM ActiveContracts ORDER BY EndDate ASC;

-- 2. Truy vấn thông tin thanh toán
Go
CREATE VIEW TenantPaymentHistory AS
SELECT 
    T.TenantID, T.NameTenant, PD.PaymentDate, PD.AmountMoney, PD.SpendToServices, PD.PaymentStatus
FROM PaymentDetail PD 
JOIN Payment P ON PD.PaymentDetailID = P.PaymentID
JOIN Tenant T ON PD.TenantID = T.TenantID;
Go
SELECT * FROM TenantPaymentHistory
WHERE TenantID = 1
ORDER BY PaymentDate ASC;


--3. Truy vấn bất động sản
--Liệt kê danh sách các bất động sản có sẵn
GO
CREATE VIEW AvailableProperties AS
SELECT 
    L.NameLandLord, P.PropertyID, P.AddressProperty, P.TypeProperty, P.AreaProperty, P.RentCost
FROM Property P  
JOIN LandLord L ON P.LandLordID = L.LandLordID   
WHERE StatusProperty = 'Available';
GO
SELECT * FROM AvailableProperties;

--Lấy danh sách bất động sản của một chủ nhà cụ thể 
GO
CREATE VIEW PropertiesBySpecificOwner AS
SELECT L.NameLandLord, P.PropertyID, P.AddressProperty, P.TypeProperty, P.StatusProperty  
FROM Property P  
JOIN LandLord L ON L.LandLordID = P.LandLordID;
GO
SELECT * 
FROM PropertiesBySpecificOwner 
WHERE NameLandLord = 'Pham Van D';


-- 4. Truy vấn thông tin ngừoi thuê và chủ nhà.
-- * Thông tin liên lạc ( Sử dụng UNION ALL để kết hợp 2 truy vấn lấy thông tin chủ nhà và ngừoi thuê)
GO
-- DROP VIEW ContactInformation
CREATE VIEW ContactInformation AS
SELECT 
    'Tenant' AS Type, 
    TenantID AS ID, 
    NameTenant AS Name, 
    PhoneNumber, 
    Email, 
    AddressTenant AS Address
FROM Tenant
UNION ALL

SELECT 
    'LandLord' AS Type, 
    LandLordID AS ID, 
    NameLandLord AS Name, 
    PhoneNumber, 
    Email, 
    AddressLandLord AS Address
FROM LandLord;
GO
SELECT * FROM ContactInformation;

-- Xác định người thuê hiện tại của một bất động sản cụ thể
GO
CREATE VIEW CurrentTenantByProperty AS
SELECT T.TenantID, T.NameTenant, T.PhoneNumber, T.Email, C.ContractID, C.StartDate, C.EndDate 
FROM Contract C
JOIN Tenant T ON C.TenantID = T.TenantID
WHERE C.ContractStatus = 'Active';
GO
SELECT * FROM CurrentTenantByProperty WHERE ContractID = 1;

-- 5. Truy vấn thông tin chi tiết hợp đồng
-- Lịch sử thay đổi hợp đồng
GO
CREATE VIEW ContractChangeHistory AS
SELECT CD.ContractDetailID, C.TenantID, T.NameTenant, CD.ChangeDate, CD.ContentChange, CD.PeopleChange, CD.Note
FROM ContractDetail CD
JOIN Contract C ON CD.ContractDetailID = C.ContractID
JOIN Tenant T ON C.TenantID = T.TenantID;
GO
SELECT * FROM ContractChangeHistory ORDER BY ChangeDate DESC;

-- Tiền đặt cọc và điều khoản đặc biệt
GO
CREATE VIEW ContractDepositTerms AS
SELECT CD.ContractDetailID, C.TenantID, T.NameTenant, CD.Deposit, CD.Note
FROM ContractDetail CD
JOIN Contract C ON CD.ContractDetailID = C.ContractID
JOIN Tenant T ON C.TenantID = T.TenantID;
GO
SELECT * FROM ContractDepositTerms;

-- 6. Truy vấn thông tin chi tiết thanh toán
-- Chi tiết các khoản chi tiêu dịch vụ
GO
CREATE VIEW PaymentServiceDetails AS
SELECT PD.PaymentDetailID, T.NameTenant, PD.PaymentDate, PD.AmountMoney, PD.SpendToServices, PD.PaymentStatus
FROM PaymentDetail PD
JOIN Tenant T ON PD.TenantID = T.TenantID
WHERE PD.SpendToServices IS NOT NULL;
GO
SELECT * FROM PaymentServiceDetails;

-- Tổng số tiền đã thanh toán trong một khoảng thời gian nhất định
GO
CREATE VIEW TotalPayments AS
SELECT T.TenantID, T.NameTenant, SUM(PD.AmountMoney) AS TotalPaid
FROM PaymentDetail PD
JOIN Tenant T ON PD.TenantID = T.TenantID
WHERE PD.PaymentDate BETWEEN '2024-01-01' AND '2024-12-30'
GROUP BY T.TenantID, T.NameTenant;
GO
SELECT * FROM TotalPayments ORDER BY TotalPaid DESC;

--******Thêm sửa xoá dữ liệu với Procedure*******
-- Thêm dữ liệu bằng procedure cho bảng tenant
go
CREATE PROCEDURE InsertTenant
    @NameTenant NVARCHAR(50),
    @IdentifyNumber VARCHAR(12),
    @PhoneNumber VARCHAR(10),
    @Email VARCHAR(250), -- Email
    @AddressTenant NVARCHAR(300) -- Địa chỉ người thuê
AS
BEGIN
    INSERT INTO Tenant (NameTenant, IdentifyNumber, PhoneNumber, Email, AddressTenant)
    VALUES(@NameTenant, @IdentifyNumber,@PhoneNumber,@Email,@AddressTenant)
END;
-- Thêm dữ liệu cho bảng LandLord
GO
CREATE PROCEDURE InsertLandLord
    @NameLandLord NVARCHAR(50),
    @IdentifyNumber VARCHAR(12),
    @PhoneNumber VARCHAR(10),
    @Email VARCHAR(250),
    @AddressLandLord VARCHAR(300)
AS
BEGIN
    INSERT INTO LandLord (NameLandLord, IdentifyNumber, PhoneNumber, Email, AddressLandLord)
    VALUES (@NameLandLord, @IdentifyNumber, @PhoneNumber, @Email, @AddressLandLord);
END;
GO
-- Thêm dữ liệu cho bảng Property
GO
CREATE PROCEDURE InsertProperty
    @LandLordID INT,
    @AddressProperty NVARCHAR(300),
    @TypeProperty NVARCHAR(50),
    @AreaProperty DECIMAL(10,2),
    @RentCost DECIMAL(10,2),
    @StatusProperty NVARCHAR(10)
AS
BEGIN
    INSERT INTO Property (LandLordID, AddressProperty, TypeProperty, AreaProperty, RentCost, StatusProperty)
    VALUES (@LandLordID, @AddressProperty, @TypeProperty, @AreaProperty, @RentCost, @StatusProperty);
END;
GO
-- Thêm dữ liệu cho bảng Contract
GO
CREATE PROCEDURE InsertContract
    @TenantID INT,
    @PropertyID INT,
    @StartDate DATE,
    @EndDate DATE,
    @ContractStatus NVARCHAR(50)
AS
BEGIN
    INSERT INTO Contract (TenantID, PropertyID, StartDate, EndDate, ContractStatus)
    VALUES (@TenantID, @PropertyID, @StartDate, @EndDate, @ContractStatus);
END;
GO
-- Thêm dữ liệu cho bảng Payment
GO
CREATE PROCEDURE InsertPayment
    @TenantID INT,
    @ContractID INT,
    @PaymentMethod NVARCHAR(50),
    @Note NVARCHAR(300) = NULL
AS
BEGIN
    INSERT INTO Payment (TenantID, ContractID, PaymentMethod, Note)
    VALUES (@TenantID, @ContractID, @PaymentMethod, @Note);
END;
GO
-- Thêm dữ liệu cho bảng ContractDetail
GO
CREATE PROCEDURE InsertContractDetail
    @ContractDetailID INT,
    @Deposit DECIMAL(10,2),
    @ChangeDate DATE,
    @ContentChange NVARCHAR(300),
    @PeopleChange NVARCHAR(50),
    @Note NVARCHAR(300)
AS
BEGIN
    INSERT INTO ContractDetail (ContractDetailID, Deposit, ChangeDate, ContentChange, PeopleChange, Note)
    VALUES (@ContractDetailID, @Deposit, @ChangeDate, @ContentChange, @PeopleChange, @Note);
END;
GO
-- Thêm dữ liệu cho bảng PaymentDetail
GO
CREATE PROCEDURE InsertPaymentDetail
    @PaymentDetailID INT,
    @TenantID INT,
    @PaymentDate DATE,
    @AmountMoney DECIMAL(10,2),
    @SpendToServices NVARCHAR(150),
    @PaymentStatus NVARCHAR(50)
AS
BEGIN
    INSERT INTO PaymentDetail (PaymentDetailID, TenantID, PaymentDate, AmountMoney, SpendToServices, PaymentStatus)
    VALUES (@PaymentDetailID, @TenantID, @PaymentDate, @AmountMoney, @SpendToServices, @PaymentStatus);
END;
GO
-- Cập nhật dữ liệu cho bảng Tennant
DROP PROCEDURE UpdateTenant
GO
CREATE PROCEDURE UpdateTenant
    @TenantID INT , -- ID của người thuê
    @NameTenant NVARCHAR(50) = NULL,
    @IdentifyNumber VARCHAR(12) = NULL,
    @PhoneNumber VARCHAR(10) = NULL,
    @Email VARCHAR(250) = NULL,
    @AddressTenant NVARCHAR(300) = NULL
AS
BEGIN
    IF @TenantID IS NOT NULL
    BEGIN
            UPDATE Tenant
        SET NameTenant = ISNULL(@NameTenant, NameTenant),
            IdentifyNumber = ISNULL(@IdentifyNumber, IdentifyNumber),
            PhoneNumber = ISNULL(@PhoneNumber, PhoneNumber),
            Email = ISNULL(@Email, Email),
            AddressTenant = ISNULL(@AddressTenant, AddressTenant) -- nếu dữu liệu đầu vào là NULL thì giữ nguyên
        WHERE TenantID = @TenantID;
        PRINT 'Da cap nhat'
    END
    ELSE
    BEGIN
        PRINT 'Vui long nhap ID'
        RETURN;
    END
END;
EXEC UpdateTenant 
    @TenantID = 1,
    @NameTenant = 'Lê Vượng'
GO

-- Xoá dữ liệu bảng Tenant
CREATE PROCEDURE DeleteTenant
    @TenantID INT -- ID của người thuê cần xóa
AS
BEGIN
    -- Kiểm tra xem người thuê có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM Tenant WHERE TenantID = @TenantID)
    BEGIN
        PRINT 'Không tìm thấy người thuê với ID = ' + CAST(@TenantID AS NVARCHAR(10));
        RETURN;
    END;

    -- Kiểm tra xem người thuê có hợp đồng còn hiệu lực hay không
    IF EXISTS (SELECT 1 FROM Contract WHERE TenantID = @TenantID AND ContractStatus = 'Active')
    BEGIN
        PRINT 'Không thể xóa người thuê vì người này đang có hợp đồng còn hiệu lực!';
        RETURN;
    END;

    -- Tiến hành xóa người thuê nếu không có hợp đồng còn hiệu lực
    DELETE FROM Tenant
    WHERE TenantID = @TenantID;

    PRINT 'Người thuê đã được xóa thành công!';
END;
GO
-- Cập nhật dữ liệu cho bảng LandLord
CREATE PROCEDURE UpdateLandLord
    @LandLordID INT,
    @NameLandLord NVARCHAR(50) = NULL,
    @IdentifyNumber VARCHAR(12) = NULL,
    @PhoneNumber VARCHAR(10) = NULL,
    @Email VARCHAR(250) = NULL,
    @AddressLandLord NVARCHAR(300) = NULL
AS
BEGIN
    IF @LandLordID IS NOT NULL
    BEGIN
        UPDATE LandLord
        SET NameLandLord = ISNULL(@NameLandLord, NameLandLord),
            IdentifyNumber = ISNULL(@IdentifyNumber, IdentifyNumber),
            PhoneNumber = ISNULL(@PhoneNumber, PhoneNumber),
            Email = ISNULL(@Email, Email),
            AddressLandLord = ISNULL(@AddressLandLord, AddressLandLord)
        WHERE LandLordID = @LandLordID;
        PRINT 'Đã cập nhật chủ nhà thành công'
    END
    ELSE
    BEGIN
        PRINT 'Vui lòng nhập ID chủ nhà'
        RETURN;
    END
END;
GO
-- Xoá dữ liệu LandLord
CREATE PROCEDURE DeleteLandLord
    @LandLordID INT -- ID của chủ nhà cần xóa
AS
BEGIN
    -- Kiểm tra xem chủ nhà có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM LandLord WHERE LandLordID = @LandLordID)
    BEGIN
        PRINT 'Không tìm thấy chủ nhà với ID = ' + CAST(@LandLordID AS NVARCHAR(10));
        RETURN;
    END;

    -- Xóa chủ nhà
    DELETE FROM LandLord
    WHERE LandLordID = @LandLordID;

    PRINT 'Chủ nhà đã được xóa thành công!';
END;
GO
-- Cập nhật Property
CREATE PROCEDURE UpdateProperty
    @PropertyID INT,
    @AddressProperty NVARCHAR(300) = NULL,
    @TypeProperty NVARCHAR(50) = NULL,
    @AreaProperty DECIMAL(10,2) = NULL,
    @RentCost DECIMAL(10,2) = NULL,
    @StatusProperty NVARCHAR(10) = NULL
AS
BEGIN
    IF @PropertyID IS NOT NULL
    BEGIN
        UPDATE Property
        SET AddressProperty = ISNULL(@AddressProperty, AddressProperty),
            TypeProperty = ISNULL(@TypeProperty, TypeProperty),
            AreaProperty = ISNULL(@AreaProperty, AreaProperty),
            RentCost = ISNULL(@RentCost, RentCost),
            StatusProperty = ISNULL(@StatusProperty, StatusProperty)
        WHERE PropertyID = @PropertyID;
        PRINT 'Đã cập nhật thông tin bất động sản thành công'
    END
    ELSE
    BEGIN
        PRINT 'Vui lòng nhập ID bất động sản'
        RETURN;
    END
END;
GO
-- Xoá property
CREATE PROCEDURE DeleteProperty
    @PropertyID INT -- ID của bất động sản cần xóa
AS
BEGIN
    -- Kiểm tra xem bất động sản có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM Property WHERE PropertyID = @PropertyID)
    BEGIN
        PRINT 'Không tìm thấy bất động sản với ID = ' + CAST(@PropertyID AS NVARCHAR(10));
        RETURN;
    END;

    -- Kiểm tra xem bất động sản có hợp đồng còn hiệu lực hay không
    IF EXISTS (SELECT 1 FROM Contract WHERE PropertyID = @PropertyID AND ContractStatus = 'Active')
    BEGIN
        PRINT 'Không thể xóa bất động sản vì có hợp đồng còn hiệu lực!';
        RETURN;
    END;

    -- Tiến hành xóa bất động sản nếu không có hợp đồng còn hiệu lực
    DELETE FROM Property
    WHERE PropertyID = @PropertyID;

    PRINT 'Bất động sản đã được xóa thành công!';
END;
GO
-- Cập nhật Contract
CREATE PROCEDURE UpdateContract
    @ContractID INT,
    @TenantID INT = NULL,
    @PropertyID INT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @ContractStatus NVARCHAR(50) = NULL
AS
BEGIN
    IF @ContractID IS NOT NULL
    BEGIN
        UPDATE Contract
        SET TenantID = ISNULL(@TenantID, TenantID),
            PropertyID = ISNULL(@PropertyID, PropertyID),
            StartDate = ISNULL(@StartDate, StartDate),
            EndDate = ISNULL(@EndDate, EndDate),
            ContractStatus = ISNULL(@ContractStatus, ContractStatus)
        WHERE ContractID = @ContractID;
        PRINT 'Đã cập nhật hợp đồng thành công'
    END
    ELSE
    BEGIN
        PRINT 'Vui lòng nhập ID hợp đồng'
        RETURN;
    END
END;
GO
-- Xoá Contract
CREATE PROCEDURE DeleteContract
    @ContractID INT -- ID của hợp đồng cần xóa
AS
BEGIN
    -- Kiểm tra xem hợp đồng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM Contract WHERE ContractID = @ContractID)
    BEGIN
        PRINT 'Không tìm thấy hợp đồng với ID = ' + CAST(@ContractID AS NVARCHAR(10));
        RETURN;
    END;

    -- Xóa hợp đồng
    DELETE FROM Contract
    WHERE ContractID = @ContractID;

    PRINT 'Hợp đồng đã được xóa thành công!';
END;
GO
-- Cập nhật Payment 
CREATE PROCEDURE UpdatePayment
    @PaymentID INT,
    @TenantID INT = NULL,
    @ContractID INT = NULL,
    @PaymentMethod NVARCHAR(50) = NULL,
    @Note NVARCHAR(300) = NULL
AS
BEGIN
    IF @PaymentID IS NOT NULL
    BEGIN
        UPDATE Payment
        SET TenantID = ISNULL(@TenantID, TenantID),
            ContractID = ISNULL(@ContractID, ContractID),
            PaymentMethod = ISNULL(@PaymentMethod, PaymentMethod),
            Note = ISNULL(@Note, Note)
        WHERE PaymentID = @PaymentID;
        PRINT 'Đã cập nhật thông tin thanh toán thành công'
    END
    ELSE
    BEGIN
        PRINT 'Vui lòng nhập ID thanh toán'
        RETURN;
    END
END;
GO
-- Xoá Payment
CREATE PROCEDURE DeletePayment
    @PaymentID INT -- ID của thanh toán cần xóa
AS
BEGIN
    -- Kiểm tra xem thanh toán có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM Payment WHERE PaymentID = @PaymentID)
    BEGIN
        PRINT 'Không tìm thấy thanh toán với ID = ' + CAST(@PaymentID AS NVARCHAR(10));
        RETURN;
    END;

    -- Xóa thanh toán
    DELETE FROM Payment
    WHERE PaymentID = @PaymentID;

    PRINT 'Thanh toán đã được xóa thành công!';
END;
GO

--******Các Trigger******
--Trigger kiểm tra và cập nhật trạng thái hợp đồng khi thay đổi ngày hết hạn
CREATE TRIGGER trg_UpdateContractStatus
ON ContractDetail
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nếu ngày kết thúc hợp đồng thay đổi, cập nhật trạng thái hợp đồng
    IF UPDATE(ChangeDate)
    BEGIN
        UPDATE Contract
        SET ContractStatus = 
            CASE 
                WHEN inserted.ChangeDate > GETDATE() THEN 'Còn hiệu lực'
                ELSE 'Hết hạn'
            END
        FROM Contract c
        INNER JOIN inserted ON c.ContractID = inserted.ContractDetailID;

        RAISERROR(N'Trạng thái hợp đồng được cập nhật!', 10, 1);
    END
END;
GO
-- Trigger ngăn chặn cập nhật tiền đặt cọc khi hợp đồng đã hết hạn
CREATE TRIGGER trg_PreventUpdateDepositOnExpiredContract
ON ContractDetail
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu hợp đồng đã hết hạn, không cho phép cập nhật tiền đặt cọc
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Contract c ON i.ContractDetailID = c.ContractID
        WHERE c.ContractStatus = 'Hết hạn'
    )
    BEGIN
        RAISERROR(N'Không thể cập nhật tiền đặt cọc khi hợp đồng đã hết hạn.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
-- Trigger tự động cập nhật trạng thái bất động sản khi có hợp đồng mới
CREATE TRIGGER trg_UpdatePropertyStatus
ON Contract
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Khi có hợp đồng mới, cập nhật trạng thái bất động sản thành 'Đã thuê'
    UPDATE Property
    SET StatusProperty = 'Đã thuê'
    FROM Property p
    JOIN inserted i ON p.PropertyID = i.PropertyID;

    RAISERROR(N'Trạng thái bất động sản được cập nhật thành "Đã thuê".', 10, 1);
END;
GO
-- Trigger ngăn chặn xóa người thuê khi có hợp đồng còn hiệu lực
CREATE TRIGGER trg_PreventDeleteTenant
ON Tenant
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem người thuê có hợp đồng còn hiệu lực không
    IF EXISTS (SELECT 1 FROM Contract WHERE TenantID IN (SELECT TenantID FROM deleted) AND ContractStatus = 'Active')
    BEGIN
        RAISERROR(N'Không thể xóa người thuê vì người này đang có hợp đồng còn hiệu lực.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
-- Trigger tự động tính tổng thanh toán khi có chi tiết thanh toán mới
CREATE TRIGGER trg_CalculateTotalPayment
ON PaymentDetail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tính tổng số tiền thanh toán cho người thuê
    UPDATE Payment
    SET AmountMoney = (SELECT SUM(AmountMoney) FROM PaymentDetail WHERE TenantID = inserted.TenantID)
    FROM Payment p
    JOIN inserted ON p.TenantID = inserted.TenantID;
    
    RAISERROR(N'Tổng số tiền thanh toán đã được cập nhật.', 10, 1);
END;
GO
-- Trigger tự động thêm thông tin vào bảng ContractChangeHistory khi có thay đổi trong hợp đồng
CREATE TRIGGER trg_TrackContractChanges
ON Contract
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lưu lịch sử thay đổi hợp đồng vào bảng ContractChangeHistory
    INSERT INTO ContractChangeHistory (ContractID, ChangeDate, ContentChange, PeopleChange)
    SELECT inserted.ContractID, GETDATE(), 'Cập nhật hợp đồng', 'System'
    FROM inserted;

    RAISERROR(N'Lịch sử thay đổi hợp đồng đã được ghi nhận.', 10, 1);
END;
GO
-- Trigger tự động cập nhật trạng thái thanh toán khi có thay đổi trong bảng Payment
CREATE TRIGGER trg_UpdatePaymentStatus
ON Payment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu trạng thái thanh toán thay đổi, cập nhật trạng thái thanh toán trong PaymentDetail
    IF UPDATE(PaymentMethod)
    BEGIN
        UPDATE PaymentDetail
        SET PaymentStatus = 'Đã thanh toán'
        FROM PaymentDetail pd
        JOIN inserted i ON pd.PaymentID = i.PaymentID;
    END

    RAISERROR(N'Trạng thái thanh toán đã được cập nhật.', 10, 1);
END;
GO
-- Trigger kiểm tra và ngăn chặn thêm người thuê có thông tin trùng lặp
CREATE TRIGGER trg_PreventDuplicateTenant
ON Tenant
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem có người thuê với số điện thoại hoặc email trùng không
    IF EXISTS (SELECT 1 FROM Tenant WHERE PhoneNumber = inserted.PhoneNumber OR Email = inserted.Email)
    BEGIN
        RAISERROR(N'Người thuê đã tồn tại với số điện thoại hoặc email này.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
-- Trigger tự động kiểm tra và cập nhật trạng thái hợp đồng khi ngày kết thúc đến gần
CREATE TRIGGER trg_CheckContractExpiry
ON Contract
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra và cập nhật trạng thái hợp đồng khi ngày kết thúc đến gần (30 ngày)
    UPDATE Contract
    SET ContractStatus = 'Sắp hết hạn'
    FROM inserted
    WHERE DATEDIFF(DAY, GETDATE(), inserted.EndDate) <= 30;

    RAISERROR(N'Các hợp đồng sắp hết hạn đã được cập nhật.', 10, 1);
END;
GO
-- Trigger ngăn chặn xóa hợp đồng khi đã có thanh toán
CREATE TRIGGER trg_PreventDeleteContract
ON Contract
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem hợp đồng có thanh toán đã được thực hiện không
    IF EXISTS (SELECT 1 FROM Payment WHERE ContractID IN (SELECT ContractID FROM deleted))
    BEGIN
        RAISERROR(N'Không thể xóa hợp đồng vì đã có thanh toán.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- *****Phân quyền và bảo vệ cơ sở dữ liệu****
-- Phân quyền
-- Tạo login cho người dùng
CREATE LOGIN TenantLogin WITH PASSWORD = 'TenantPassword123';
CREATE LOGIN LandLordLogin WITH PASSWORD = 'LandLordPassword123';

-- Tạo người dùng trong cơ sở dữ liệu
USE ManagementHouse;

CREATE USER TenantUser FOR LOGIN TenantLogin;
CREATE USER LandLordUser FOR LOGIN LandLordLogin;

-- Cấp quyền SELECT, INSERT, UPDATE cho bảng Tenant
GRANT SELECT, INSERT, UPDATE ON Tenant TO TenantUser;

-- Cấp quyền SELECT cho bảng Property và Contract để người thuê có thể xem bất động sản và hợp đồng của mình
GRANT SELECT ON Property TO TenantUser;
GRANT SELECT ON Contract TO TenantUser;

-- Cấm quyền DELETE để bảo vệ dữ liệu người thuê không bị xóa
DENY DELETE ON Tenant TO TenantUser;

-- Cấp quyền SELECT, INSERT, UPDATE cho bảng Property để chủ nhà có thể quản lý bất động sản
GRANT SELECT, INSERT, UPDATE ON Property TO LandLordUser;

-- Cấp quyền SELECT cho bảng Tenant và Contract để chủ nhà có thể xem thông tin người thuê và hợp đồng
GRANT SELECT ON Tenant TO LandLordUser;
GRANT SELECT ON Contract TO LandLordUser;

-- Cấm quyền DELETE để bảo vệ dữ liệu chủ nhà không bị xóa
DENY DELETE ON Property TO LandLordUser;

-- Cấp quyền SELECT, INSERT, UPDATE, DELETE cho tất cả các bảng
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES TO dbo;

-- Cấp quyền EXECUTE cho tất cả các stored procedures
GRANT EXECUTE ON SCHEMA::dbo TO dbo;


-- Bảo vệ dữ liệu bảng mã hoá 
-- Tạo MASTER KEY
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

-- Tạo CERTIFICATE để bảo mật khóa
CREATE CERTIFICATE DataEncryptionCert WITH SUBJECT = 'Data Encryption';

-- Tạo SYMMETRIC KEY để mã hóa và giải mã dữ liệu
CREATE SYMMETRIC KEY DataSymmetricKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE DataEncryptionCert;

-- Mã hóa cột IdentifyNumber và PhoneNumber trong bảng Tenant
ALTER TABLE Tenant ADD IdentifyNumber_Encrypted VARBINARY(256);
ALTER TABLE Tenant ADD PhoneNumber_Encrypted VARBINARY(MAX);

OPEN SYMMETRIC KEY DataSymmetricKey DECRYPTION BY CERTIFICATE DataEncryptionCert;

-- Mã hóa cột dữ liệu
UPDATE Tenant
SET 
    IdentifyNumber_Encrypted = ENCRYPTBYKEY(KEY_GUID('DataSymmetricKey'), CAST(IdentifyNumber AS NVARCHAR(256))),
    PhoneNumber_Encrypted = ENCRYPTBYKEY(KEY_GUID('DataSymmetricKey'), CAST(PhoneNumber AS NVARCHAR(MAX)));

-- Đảm bảo rằng sau khi mã hóa xong, có thể xóa cột gốc
ALTER TABLE Tenant DROP COLUMN IdentifyNumber;
ALTER TABLE Tenant DROP COLUMN PhoneNumber;

CLOSE SYMMETRIC KEY DataSymmetricKey;

-- Giải mã cột IdentifyNumber_Encrypted khi cần sử dụng
OPEN SYMMETRIC KEY DataSymmetricKey DECRYPTION BY CERTIFICATE DataEncryptionCert;

SELECT 
    TenantID, 
    CAST(DECRYPTBYKEY(IdentifyNumber_Encrypted) AS NVARCHAR(256)) AS IdentifyNumber
FROM Tenant;

CLOSE SYMMETRIC KEY DataSymmetricKey;

-- Cấm truy cập vào các cột nhạy cảm của bảng Tenant
DENY SELECT ON Tenant(IdentifyNumber_Encrypted) TO TenantUser;
DENY SELECT ON Tenant(PhoneNumber_Encrypted) TO TenantUser;

-- Cấp quyền EXECUTE cho các thủ tục cho người dùng có quyền
GRANT EXECUTE ON PROCEDURE::InsertTenant TO Admin;
GRANT EXECUTE ON PROCEDURE::UpdateTenant TO Admin;
GRANT EXECUTE ON PROCEDURE::DeleteTenant TO Admin;
















-- Mã hoá từng cột một:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'md43SGAB@';
CREATE CERTIFICATE Cert_Col WITH SUBJECT = 'Data Encryption';
CREATE SYMMETRIC KEY SymKey with ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE Cert_Col

ALTER TABLE Tenant ADD IdentifyNumber_Encrypted varbinary(256)
ALTER TABLE Tenant
ADD PhoneNumber_Encrypted VARBINARY(MAX),
    Email_Encrypted VARBINARY(MAX),
    AddressTenant_Encrypted VARBINARY(MAX);
OPEN Symmetric KEY SymKey DECRYPTION BY certificate Cert_Col;
-- Cập nhật mã hoá từ cột IdentifyNumber, do quên không cập nhật cả nên phải cập nhật thêm
UPDATE Tenant
SET IdentifyNumber_Encrypted = ENCRYPTBYKEY(KEY_GUID('SymKey'),CONVERT(varbinary(256),IdentifyNumber));

-- bảng landlord
ALTER TABLE LandLord
ADD PhoneNumber_Encrypted VARBINARY(MAX),
    IdentifyNumber_Encrypted VARBINARY(MAX),
    Email_Encrypted VARBINARY(MAX),
    AddressLandLord_Encrypted VARBINARY(MAX);
UPDATE LandLord
SET PhoneNumber_Encrypted = EncryptByKey(Key_GUID('SymKey'), PhoneNumber),
    IdentifyNumber_Encrypted = EncryptByKey(Key_GUID('SymKey'), IdentifyNumber),
    Email_Encrypted = EncryptByKey(Key_GUID('SymKey'), Email),
    AddressLandLord_Encrypted = EncryptByKey(Key_GUID('SymKey'), AddressLandLord);

-- Thêm các cột mã hóa vào bảng Contract
ALTER TABLE ContractDetail
ADD BankAccountNumber_Encrypted VARBINARY(MAX);
UPDATE ContractDetail
SET BankAccountNumber_Encrypted = EncryptByKey(Key_GUID('SymKey'), CAST(Deposit AS nvarchar));
-- Thêm các cột mã hóa vào bảng Payment
ALTER TABLE PaymentDetail
ADD AmountMoney_Encrypted VARBINARY(MAX),
    SpendToServices_Encrypted varbinary(MAX);
UPDATE PaymentDetail
SET 
    AmountMoney_Encrypted = EncryptByKey(Key_GUID('SymKey'), CAST(AmountMoney AS nvarchar)),
    SpendToServices_Encrypted = EncryptByKey(Key_GUID('SymKey'), SpendToServices);
CLOSE SYMMETRIC KEY SymKey;
-- Check
SELECT IdentifyNumber_Encrypted FROM Tenant -- mã hoá số cccd
-- Có thể xoá các cột gốc đã được mã hoá, chỉ giữ các cột mã hoá mà vừa cập nhật

-- Thêm dữ liệu mẫu 15 lần
-- Tenant
EXEC InsertTenant N'Nguyễn Văn A', '123456789', '0912345678', 'a@gmail.com', 'Hà Nội';
EXEC InsertTenant N'Trần Thị B', '234567890', '0912345679', 'b@gmail.com', 'TP.HCM';
EXEC InsertTenant N'Lê Văn C', '345678901', '0912345680', 'c@gmail.com', 'Đà Nẵng';
EXEC InsertTenant N'Phạm Thị D', '456789012', '0912345681', 'd@gmail.com', 'Hải Phòng';
EXEC InsertTenant N'Hoàng Văn E', '567890123', '0912345682', 'e@gmail.com', 'Cần Thơ';
EXEC InsertTenant N'Vũ Thị F', '678901234', '0912345683', 'f@gmail.com', 'Nha Trang';
EXEC InsertTenant N'Đặng Văn G', '789012345', '0912345684', 'g@gmail.com', 'Huế';
EXEC InsertTenant N'Bùi Thị H', '890123456', '0912345685', 'h@gmail.com', 'Vũng Tàu';
EXEC InsertTenant N'Ngô Văn I', '901234567', '0912345686', 'i@gmail.com', 'Quảng Ninh';
EXEC InsertTenant N'Đỗ Thị K', '012345678', '0912345687', 'k@gmail.com', 'Bình Dương';
EXEC InsertTenant N'Nguyễn Thanh Lâm', '112233445', '0912345688', 'lam@gmail.com', 'Bắc Ninh';
EXEC InsertTenant N'Lê Minh Quân', '223344556', '0912345689', 'quan@gmail.com', 'Hải Dương';
EXEC InsertTenant N'Phạm Ngọc Hà', '334455667', '0912345690', 'ha@gmail.com', 'Thanh Hóa';
EXEC InsertTenant N'Trương Hoàng Anh', '445566778', '0912345691', 'hoanganh@gmail.com', 'Nghệ An';
EXEC InsertTenant N'Bùi Văn Tiến', '556677889', '0912345692', 'tienbui@gmail.com', 'Thái Nguyên';


-- LandLord
EXEC InsertLandLord N'Chủ Nhà 1', 'LL001', '0987654321', 'landlord1@gmail.com', N'Hà Nội';
EXEC InsertLandLord N'Chủ Nhà 2', 'LL002', '0987654322', 'landlord2@gmail.com', N'TP.HCM';
EXEC InsertLandLord N'Chủ Nhà 3', 'LL003', '0987654323', 'landlord3@gmail.com', N'Đà Nẵng';
EXEC InsertLandLord N'Chủ Nhà 4', 'LL004', '0987654324', 'landlord4@gmail.com', N'Hải Phòng';
EXEC InsertLandLord N'Chủ Nhà 5', 'LL005', '0987654325', 'landlord5@gmail.com', N'Cần Thơ';
EXEC InsertLandLord N'Chủ Nhà 6', 'LL006', '0987654326', 'landlord6@gmail.com', N'Nha Trang';
EXEC InsertLandLord N'Chủ Nhà 7', 'LL007', '0987654327', 'landlord7@gmail.com', N'Huế';
EXEC InsertLandLord N'Chủ Nhà 8', 'LL008', '0987654328', 'landlord8@gmail.com', N'Vũng Tàu';
EXEC InsertLandLord N'Chủ Nhà 9', 'LL009', '0987654329', 'landlord9@gmail.com', N'Quảng Ninh';
EXEC InsertLandLord N'Chủ Nhà 10', 'LL010', '0987654330', 'landlord10@gmail.com', N'Bình Dương';
EXEC InsertLandLord N'Chủ Nhà 11', 'LL011', '0987654331', 'landlord11@gmail.com', N'Bắc Ninh';
EXEC InsertLandLord N'Chủ Nhà 12', 'LL012', '0987654332', 'landlord12@gmail.com', N'Hải Dương';
EXEC InsertLandLord N'Chủ Nhà 13', 'LL013', '0987654333', 'landlord13@gmail.com', N'Thanh Hóa';
EXEC InsertLandLord N'Chủ Nhà 14', 'LL014', '0987654334', 'landlord14@gmail.com', N'Nghệ An';
EXEC InsertLandLord N'Chủ Nhà 15', 'LL015', '0987654335', 'landlord15@gmail.com', N'Thái Nguyên';
EXEC InsertLandLord N'Pham Van D', 'LL031', '0987654355', 'landlord31@gmail.com', N'Thái Nguyên';


-- Property (LandLordID từ 1 đến 10)
EXEC InsertProperty 1, N'Số 1 Nguyễn Trãi', N'Căn hộ', 50.5, 5000000, 'Available';
EXEC InsertProperty 2, N'Số 2 Lê Lợi', N'Nhà nguyên căn', 80.0, 8000000, 'Available';
EXEC InsertProperty 3, N'Số 3 Trần Hưng Đạo', N'Căn hộ', 60.0, 6000000, 'Available';
EXEC InsertProperty 4, N'Số 4 Quang Trung', N'Biệt thự', 150.0, 15000000, 'Available';
EXEC InsertProperty 5, N'Số 5 Hai Bà Trưng', N'Căn hộ', 55.5, 5500000, 'Available';
EXEC InsertProperty 6, N'Số 6 Lý Thường Kiệt', N'Nhà nguyên căn', 90.0, 9000000, 'Available';
EXEC InsertProperty 7, N'Số 7 Ngô Quyền', N'Căn hộ', 65.0, 6500000, 'Available';
EXEC InsertProperty 8, N'Số 8 Bà Triệu', N'Biệt thự', 200.0, 20000000, 'Available';
EXEC InsertProperty 9, N'Số 9 Tràng Thi', N'Nhà nguyên căn', 70.0, 7000000, 'Available';
EXEC InsertProperty 10, N'Số 10 Đinh Tiên Hoàng', N'Căn hộ', 45.0, 4500000, 'Available';
EXEC InsertProperty 11, N'Số 11 Trần Phú', N'Căn hộ', 55.0, 5500000, 'Available';
EXEC InsertProperty 12, N'Số 12 Lạc Long Quân', N'Nhà nguyên căn', 85.0, 8500000, 'Available';
EXEC InsertProperty 13, N'Số 13 Nguyễn Chí Thanh', N'Biệt thự', 180.0, 18000000, 'Available';
EXEC InsertProperty 14, N'Số 14 Lý Chính Thắng', N'Căn hộ', 48.5, 4800000, 'Available';
EXEC InsertProperty 15, N'Số 15 Hồ Tùng Mậu', N'Nhà nguyên căn', 95.0, 9500000, 'Available';

-- Contract (TenantID và PropertyID từ 1 đến 10)
EXEC InsertContract 1, 1, '2024-01-01', '2025-01-01', 'Active';
EXEC InsertContract 2, 2, '2024-02-01', '2025-02-01', 'Active';
EXEC InsertContract 3, 3, '2024-03-01', '2025-03-01', 'Active';
EXEC InsertContract 4, 4, '2024-04-01', '2025-04-01', 'Active';
EXEC InsertContract 5, 5, '2024-05-01', '2025-05-01', 'Active';
EXEC InsertContract 6, 6, '2024-06-01', '2025-06-01', 'Active';
EXEC InsertContract 7, 7, '2024-07-01', '2025-07-01', 'Active';
EXEC InsertContract 8, 8, '2024-08-01', '2025-08-01', 'Active';
EXEC InsertContract 9, 9, '2024-09-01', '2025-09-01', 'Active';
EXEC InsertContract 10, 10, '2024-10-01', '2025-10-01', 'Active';
EXEC InsertContract 11, 11, '2024-11-01', '2025-11-01', 'Active';
EXEC InsertContract 12, 12, '2024-12-01', '2025-12-01', 'Active';
EXEC InsertContract 13, 13, '2024-06-15', '2025-06-15', 'Active';
EXEC InsertContract 14, 14, '2024-07-20', '2025-07-20', 'Active';
EXEC InsertContract 15, 15, '2024-08-25', '2025-08-25', 'Active';


-- Payment (ContractID từ 1 đến 10)
EXEC InsertPayment 1, 1, N'Chuyển khoản', N'Thanh toán tháng 1';
EXEC InsertPayment 2, 2, N'Tiền mặt', N'Thanh toán tháng 2';
EXEC InsertPayment 3, 3, N'Chuyển khoản', N'Thanh toán tháng 3';
EXEC InsertPayment 4, 4, N'Tiền mặt', N'Thanh toán tháng 4';
EXEC InsertPayment 5, 5, N'Chuyển khoản', N'Thanh toán tháng 5';
EXEC InsertPayment 6, 6, N'Tiền mặt', N'Thanh toán tháng 6';
EXEC InsertPayment 7, 7, N'Chuyển khoản', N'Thanh toán tháng 7';
EXEC InsertPayment 8, 8, N'Tiền mặt', N'Thanh toán tháng 8';
EXEC InsertPayment 9, 9, N'Chuyển khoản', N'Thanh toán tháng 9';
EXEC InsertPayment 10, 10, N'Tiền mặt', N'Thanh toán tháng 10';
EXEC InsertPayment 11, 11, N'Chuyển khoản', N'Thanh toán tháng 11';
EXEC InsertPayment 12, 12, N'Tiền mặt', N'Thanh toán tháng 12';
EXEC InsertPayment 13, 13, N'Chuyển khoản', N'Thanh toán tháng 6';
EXEC InsertPayment 14, 14, N'Tiền mặt', N'Thanh toán tháng 7';
EXEC InsertPayment 15, 15, N'Chuyển khoản', N'Thanh toán tháng 8';


-- ContractDetail (ContractDetailID từ 1 đến 10)
EXEC InsertContractDetail 1, 5000000, '2024-01-01', N'Đặt cọc', N'Nguyễn Văn A', N'Ghi chú 1';
EXEC InsertContractDetail 2, 6000000, '2024-02-01', N'Đặt cọc', N'Trần Thị B', N'Ghi chú 2';
EXEC InsertContractDetail 3, 7000000, '2024-03-01', N'Đặt cọc', N'Lê Văn C', N'Ghi chú 3';
EXEC InsertContractDetail 4, 8000000, '2024-04-01', N'Đặt cọc', N'Phạm Thị D', N'Ghi chú 4';
EXEC InsertContractDetail 5, 9000000, '2024-05-01', N'Đặt cọc', N'Hoàng Văn E', N'Ghi chú 5';
EXEC InsertContractDetail 6, 10000000, '2024-06-01', N'Đặt cọc', N'Vũ Thị F', N'Ghi chú 6';
EXEC InsertContractDetail 7, 11000000, '2024-07-01', N'Đặt cọc', N'Đặng Văn G', N'Ghi chú 7';
EXEC InsertContractDetail 8, 12000000, '2024-08-01', N'Đặt cọc', N'Bùi Thị H', N'Ghi chú 8';
EXEC InsertContractDetail 9, 13000000, '2024-09-01', N'Đặt cọc', N'Ngô Văn I', N'Ghi chú 9';
EXEC InsertContractDetail 10, 14000000, '2024-10-01', N'Đặt cọc', N'Đỗ Thị K', N'Ghi chú 10';
EXEC InsertContractDetail 11, 15000000, '2024-11-01', N'Đặt cọc', N'Nguyễn Thanh Lâm', N'Ghi chú 11';
EXEC InsertContractDetail 12, 16000000, '2024-12-01', N'Đặt cọc', N'Lê Minh Quân', N'Ghi chú 12';
EXEC InsertContractDetail 13, 17000000, '2024-06-15', N'Đặt cọc', N'Phạm Ngọc Hà', N'Ghi chú 13';
EXEC InsertContractDetail 14, 18000000, '2024-07-20', N'Đặt cọc', N'Trương Hoàng Anh', N'Ghi chú 14';
EXEC InsertContractDetail 15, 19000000, '2024-08-25', N'Đặt cọc', N'Bùi Văn Tiến', N'Ghi chú 15';


-- PaymentDetail (PaymentDetailID từ 1 đến 10)
EXEC InsertPaymentDetail 1, 1, '2024-01-05', 5000000, N'Tiền nhà', N'Đã thanh toán';
EXEC InsertPaymentDetail 2, 2, '2024-02-05', 6000000, N'Tiền điện', N'Đã thanh toán';
EXEC InsertPaymentDetail 3, 3, '2024-03-05', 7000000, N'Tiền nước', N'Đã thanh toán';
EXEC InsertPaymentDetail 4, 4, '2024-04-05', 8000000, N'Tiền internet', N'Đã thanh toán';
EXEC InsertPaymentDetail 5, 5, '2024-05-05', 9000000, N'Tiền dịch vụ', N'Đã thanh toán';
EXEC InsertPaymentDetail 6, 6, '2024-06-05', 10000000, N'Tiền nhà', N'Đã thanh toán';
EXEC InsertPaymentDetail 7, 7, '2024-07-05', 11000000, N'Tiền điện', N'Đã thanh toán';
EXEC InsertPaymentDetail 8, 8, '2024-08-05', 12000000, N'Tiền nước', N'Đã thanh toán';
EXEC InsertPaymentDetail 9, 9, '2024-09-05', 13000000, N'Tiền internet', N'Đã thanh toán';
EXEC InsertPaymentDetail 10, 10, '2024-10-05', 14000000, N'Tiền dịch vụ', N'Đã thanh toán';
EXEC InsertPaymentDetail 11, 11, '2024-11-05', 15000000, N'Tiền nhà', N'Đã thanh toán';
EXEC InsertPaymentDetail 12, 12, '2024-12-05', 16000000, N'Tiền điện', N'Đã thanh toán';
EXEC InsertPaymentDetail 13, 13, '2024-06-10', 17000000, N'Tiền nước', N'Đã thanh toán';
EXEC InsertPaymentDetail 14, 14, '2024-07-15', 18000000, N'Tiền internet', N'Đã thanh toán';
EXEC InsertPaymentDetail 15, 15, '2024-08-20', 19000000, N'Tiền dịch vụ', N'Đã thanh toán';

-- In bảng dữ liệu từ bảng Tenant
SELECT * FROM Tenant;
-- In bảng dữ liệu từ bảng LandLord
SELECT * FROM LandLord;
-- In bảng dữ liệu từ bảng Property
SELECT * FROM Property;
-- In bảng dữ liệu từ bảng Contract
SELECT * FROM Contract;
-- In bảng dữ liệu từ bảng Payment
SELECT * FROM Payment;
-- In bảng dữ liệu từ bảng ContractDetail
SELECT * FROM ContractDetail;
-- In bảng dữ liệu từ bảng PaymentDetail
SELECT * FROM PaymentDetail;


SELECT TOP 5 * 
FROM ActiveContracts 
ORDER BY EndDate ASC;

SELECT * 
FROM AvailableProperties 
WHERE RentCost < 10000000 
ORDER BY RentCost ASC;

SELECT * 
FROM ContactInformation 
WHERE Type = 'LandLord' 
ORDER BY Name;

SELECT TOP 3 * 
FROM ContractChangeHistory 
ORDER BY ChangeDate DESC;

SELECT NameTenant, SUM(AmountMoney) AS TotalServiceSpending 
FROM PaymentServiceDetails 
GROUP BY NameTenant 
ORDER BY TotalServiceSpending DESC;

SELECT * 
FROM CurrentTenantByProperty 
WHERE ContractID = 5;

SELECT * FROM ContractDepositTerms;

SELECT * FROM PaymentServiceDetails;

SELECT * FROM TotalPayments ORDER BY TotalPaid DESC;

SELECT * FROM ActiveContracts 
WHERE EndDate BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE())
ORDER BY EndDate ASC;

-- Tạo Login cho Người dùng thường
CREATE LOGIN UserLogin WITH PASSWORD = 'User@123';
-- Tạo User trong Database ManagementHouse
USE ManagementHouse;
CREATE USER RegularUser FOR LOGIN UserLogin;

-- Tạo Role UserRole
CREATE ROLE UserRole;

-- Cấp quyền SELECT trên các View công khai
GRANT SELECT ON ActiveContracts TO UserRole;
GRANT SELECT ON AvailableProperties TO UserRole;
GRANT SELECT ON ContactInformation TO UserRole;
GRANT SELECT ON CurrentTenantByProperty TO UserRole;

-- Cấp quyền EXECUTE trên các Stored Procedure cần thiết
GRANT EXECUTE ON InsertTenant TO UserRole;
GRANT EXECUTE ON UpdateTenant TO UserRole;
GRANT EXECUTE ON GetTenantPaymentHistory TO UserRole;

-- Gán quyền cho user
ALTER ROLE UserRole ADD MEMBER RegularUser

-- Kiểm tra quyền truy cập của user
EXECUTE AS USER = 'RegularUser';
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
REVERT