IF DBO.OBJECT_ID('VW_BI_Veiculos') IS NOT NULL
	DROP VIEW VW_BI_Veiculos
GO

CREATE VIEW VW_BI_Veiculos WITH ENCRYPTION
AS

	SELECT TBveiculo.DFid_veiculo,
	       TBveiculo.DFplaca,
		   TBcarroceria.DFnum_paletes,
		   TBcarga.DFcod_carga,
		   TBcarga.DFdata_criacao,
		   TBcarga.DFpeso,
		   TBcarga.DFvolume,
		   TBcarga.DFvalor,
		   TBcarga.DFstatus
	FROM TBveiculo WITH(NOLOCK)
	JOIN TBcarroceria WITH(NOLOCK) ON TBveiculo.DFid_carroceria = TBcarroceria.DFid_carroceria
	JOIN TBcarga WITH(NOLOCK) ON TBcarga.DFid_veiculo = TBveiculo.DFid_veiculo

GO

-- GRANT SELECT ON [dbo].VW_BI_Veiculos TO talyx WITH GRANT OPTION 

-- exec DW_DIMENSOES
-- select * from DBDW_Director_Base.dbo.dimCliente
