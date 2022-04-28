
GO

/****** Object:  Table [dbo].[tblProductInventory]    Script Date: 28-04-2022 11:31:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tblProductInventory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProductName] [varchar](100) NULL,
	[ProductCode] [varchar](20) NULL,
	[Category] [varchar](100) NULL,
	[ProductSize] [varchar](20) NULL,
	[Price] [numeric](18, 2) NULL,
	[ProductDescription] [varchar](1000) NULL,
	[FeedID] [varchar](100) NULL,
	[UniqueID] [varchar](100) NULL,
	[CreatedOn] [datetime] NULL,
	[ModifiedOn] [datetime] NULL,
	[IsDeleted] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

-------------------------------------------

GO 


GO

/****** Object:  StoredProcedure [dbo].[sp_crud_operation_api]    Script Date: 28-04-2022 11:31:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_crud_operation_api]
	(     
		@paramProductName varchar(100)='' ,
		@paramProductCode varchar(100)='',
		@paramCategory varchar(100)='',
		@paramProductSize varchar(100)='',
		@paramPrice numeric(18,2),
		@paramProductDescription varchar(500)='',
		@paramFeedID varchar(50)='',
		@paramUniqueID varchar(100)='',
		@paramOperationType varchar(50)=''
	)
AS
BEGIN
	SET NOCOUNT ON;

	Declare @TheExceptionErrorCount int = 0;

ExceptionOccured:

	BEGIN TRY
	    If (@paramOperationType = 'POST')
		BEGIN
		INSERT INTO [dbo].[tblProductInventory]
           ([ProductName],[ProductCode],[Category],[ProductSize],[Price],[ProductDescription],[FeedID],[UniqueID],[CreatedOn],[IsDeleted])
		    VALUES  (@paramProductName,@paramProductCode,@paramCategory,@paramProductSize,@paramPrice,@paramProductDescription,@paramFeedID,@paramUniqueID,GETDATE(),0)
		END
		Else IF (@paramOperationType = 'PUT')
		BEGIN
		UPDATE [dbo].[tblProductInventory]
		   SET [ProductName] = @paramProductName
			  ,[ProductCode] = @paramProductCode
			  ,[Category] = @paramCategory
			  ,[ProductSize] = @paramProductSize
			  ,[Price] =@paramPrice
			  ,[ProductDescription] = @paramProductDescription
			  ,[ModifiedOn] = GETDATE() where UniqueID= @paramUniqueID
    
		END
		Else IF (@paramOperationType = 'DELETE')
		BEGIN
			UPDATE [dbo].[tblProductInventory]  SET IsDeleted=1 WHERE [IsDeleted]= 0 and UniqueID=@paramUniqueID
		END
		
		SET NOCOUNT OFF;

	END TRY
  BEGIN CATCH
  
       				   
       if((@TheExceptionErrorCount < 5) and (ERROR_MESSAGE() like '%was deadlocked%'))
		begin
			set @TheExceptionErrorCount = @TheExceptionErrorCount + 1;
			WAITFOR DELAY '00:00:03' ---- 03 Second Delay   
       
			GOTO ExceptionOccured
		end
		else
		begin

			SET NOCOUNT OFF;

			DECLARE @ErrMessage varchar(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;

			SELECT 
				@ErrMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();

		   -- We can insert into Log table here if exception


		end
		
  END CATCH
END
GO



GO

/****** Object:  StoredProcedure [dbo].[sp_get_productsearch_api]    Script Date: 28-04-2022 11:31:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--[dbo].[sp_get_productsearch_api] '',1,1,'ProductName,asc'

CREATE PROCEDURE [dbo].[sp_get_productsearch_api]
	(     
		@paramUniqueID varchar(100)='',
		@paramPage int=0,
		@paramSize int=20,
		@paramSortBy varchar(100)=''
	)
AS
BEGIN
	SET NOCOUNT ON;

	    Declare @strQuery varchar(max)='',@whereClause varchar(1000)=' where 1=1 ',@orderBy varchar(1000)='',@totalCount int = 0

		select @totalCount = Count(1) from dbo.tblProductInventory with(nolock)  WHERE IsDeleted = 0
		
		set @strQuery = N'SELECT TOP '+cast(@paramSize as varchar)+'
			   [FeedID]
			  ,[UniqueID]
			  ,[ProductName]
			  ,[ProductCode]
			  ,[Category]
			  ,[ProductSize]
			  ,[Price]
			  ,[ProductDescription]			  			  
               from (Select ROW_NUMBER() OVER (ORDER BY ID) as Count,  [FeedID]
			  ,[UniqueID]
			  ,[ProductName]
			  ,[ProductCode]
			  ,[Category]
			  ,[ProductSize]
			  ,[Price]
			  ,[ProductDescription] from dbo.tblProductInventory with(nolock)  WHERE IsDeleted = 0 ) t '


		if @paramPage <> 0 and @totalCount >= 10
		Begin
			set @whereClause += N' and t.Count > '+ CAST(@paramPage+10 as varchar) 
		End
		else if @paramPage = 0 
		begin
		   set @whereClause += N' and t.Count > '+ CAST(@paramPage as varchar)
		End
		

		if @paramSortBy <> ''
		Begin
			set @orderBy += '  ORDER BY '+REPLACE(@paramSortBy,',',' ')
		End

	    If (@paramUniqueID <> '')
		BEGIN
		
			set @whereClause += N' and UniqueID= '''+@paramUniqueID+''''		

			set @strQuery =@strQuery+ @whereClause+'' +' FOR JSON PATH,ROOT(''Records'')'
		END
		Else 
		BEGIN
			set @strQuery =@strQuery+ @whereClause + @orderBy +' FOR JSON PATH,ROOT(''Records'')'     
		END
		print (@strQuery)

		exec (@strQuery)
		

		SET NOCOUNT OFF;

END
GO



GO

