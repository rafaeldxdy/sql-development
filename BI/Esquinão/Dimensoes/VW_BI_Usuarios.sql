IF DBO.OBJECT_ID('VW_BI_Usuarios') IS NOT NULL
	DROP VIEW VW_BI_Usuarios
GO

CREATE VIEW VW_BI_Usuarios WITH ENCRYPTION
AS

	SELECT DFid_usuario, DFnome_usuario
	FROM TBusuario WITH(NOLOCK)

GO

-- GRANT SELECT ON [dbo].VW_BI_Usuarios TO talyx WITH GRANT OPTION 

-- exec DW_DIMENSOES
-- select * from DBDW_Director_Base.dbo.dimCliente
