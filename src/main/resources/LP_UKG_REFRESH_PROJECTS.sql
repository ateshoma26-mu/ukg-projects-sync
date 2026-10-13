CREATE OR ALTER PROCEDURE UKG_REFRESH_PROJECTS
    @data NVARCHAR(MAX)   -- JSON array: [{ "code": "...", "description": "..." }, ...]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            TRUNCATE TABLE UKG_Project;
            INSERT INTO UKG_Project (code, description)
            SELECT code, description
            FROM OPENJSON(@data)
            WITH ( code NVARCHAR(50) '$.code', description NVARCHAR(44) '$.description' );
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
