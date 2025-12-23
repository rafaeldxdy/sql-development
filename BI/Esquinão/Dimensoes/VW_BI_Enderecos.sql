IF DBO.OBJECT_ID('VW_BI_Enderecos') IS NOT NULL
	DROP VIEW VW_BI_Enderecos
GO

CREATE VIEW VW_BI_Enderecos WITH ENCRYPTION
AS

	SELECT DFid_endereco_armazenagem,
	       DFrua,
		   DFpredio,
		   DFnivel,
		   DFapto
	FROM TBendereco_armazenagem WITH(NOLOCK)

GO

-- GRANT SELECT ON [dbo].VW_BI_Enderecos TO talyx WITH GRANT OPTION 

-- exec DW_DIMENSOES
-- select * from DBDW_Director_Base.dbo.dimCliente
