IF DBO.OBJECT_ID('VW_BI_Status_Ordem_Movimentacao') IS NOT NULL
	DROP VIEW VW_BI_Status_Ordem_Movimentacao
GO

CREATE VIEW VW_BI_Status_Ordem_Movimentacao WITH ENCRYPTION
AS

	SELECT DISTINCT DFstatus, DFstatus_descritivo
	FROM TBordem_movimentacao
	WHERE DFstatus_descritivo IN ('Aguardando', 'Cancelado', 'Feito', 'Parcial')

GO

-- GRANT SELECT ON [dbo].VW_BI_Status_Ordem_Movimentacao TO talyx WITH GRANT OPTION 

-- exec DW_DIMENSOES
-- select * from DBDW_Director_Base.dbo.dimCliente

