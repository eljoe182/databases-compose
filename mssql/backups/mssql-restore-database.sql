CREATE DATABASE [DEMO]

RESTORE DATABASE [DEMO]
FROM
	DISK = N'/var/opt/mssql/backup/DEMO.bak'
WITH
	FILE = 1,
	MOVE N'DEMO' TO N'/var/opt/mssql/data/DEMO.mdf',
	MOVE N'DEMO_log' TO N'/var/opt/mssql/data/DEMO.ldf',
	NOUNLOAD,
	REPLACE,
	STATS = 5
GO
