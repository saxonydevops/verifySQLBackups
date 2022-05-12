---------------------------------------------------------------
--
-- Author: Bjoern Ohlrich @saxonysqldba
--
-- Script to verify your latest SQL Server Full Backups
--
---------------------------------------------------------------

DECLARE @dbcount INT
DECLARE @bkname VARCHAR(256)
DECLARE @dbname VARCHAR(256)
DECLARE @usesql VARCHAR(256)

SET @dbcount = (SELECT COUNT(*) FROM sys.databases)

DECLARE db_backups CURSOR FOR
	SELECT TOP (@dbcount-1)
	    bs.database_name,
		bm.physical_device_name
	FROM msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bm on bs.media_set_id = bm.media_set_id
	WHERE bs.type = 'D' AND bs.database_name NOT IN ('master', 'msdb', 'model', 'tempdb')
	ORDER BY bs.backup_finish_date DESC

OPEN db_backups
FETCH NEXT FROM db_backups INTO @dbname, @bkname

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @usesql = 'USE ' + @dbname
    EXEC sp_sqlexec @usesql

    PRINT '#############################'
    PRINT 'Checking Database ' + @dbname
    PRINT ' Backup File: ' + @bkname

	RESTORE VERIFYONLY FROM DISK = @bkname

    PRINT ''

	FETCH NEXT FROM db_backups INTO @dbname, @bkname
END

CLOSE db_backups
DEALLOCATE db_backups