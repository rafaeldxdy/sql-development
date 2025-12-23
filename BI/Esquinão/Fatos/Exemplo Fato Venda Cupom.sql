
IF DBO.OBJECT_ID('DW_FATO_VENDA_CUPOM') IS NOT NULL DROP PROCEDURE DW_FATO_VENDA_CUPOM
GO

CREATE PROCEDURE DW_FATO_VENDA_CUPOM WITH ENCRYPTION
AS
BEGIN

/*
    AUTOR......: Luiz Paulo Lewer
    DATA\HORA..: 03/08/2022
    
    Função: Gerar informações de vendas do frente de loja
*/
 
SELECT ml.TBcupom_fiscal.DFid_cupom_fiscal [ID]
	 , ml.TBcupom_fiscal.DFcod_empresa AS [codEmpresa]
     , ml.TBitem_cupom_fiscal.DFcod_item_estoque AS [codProduto]
	 , ml.TBcupom_fiscal.DFcod_operador AS [codOperador]
	 , ml.TBcupom_fiscal.DFpdv AS [codPDV]
	 , CAST(ml.TBcupom_fiscal.DFdata_movimento AS DATE) AS [Data Movimento]
	 , SUM(ml.TBitem_cupom_fiscal.DFquantidade) AS [Quantidade Vendida]
	 , AVG(ml.TBitem_cupom_fiscal.DFpreco_unitario) as [Valor Unitário]
	 , SUM(ml.TBitem_cupom_fiscal.DFvalor_desconto) AS [Valor Desconto Item]
	 , SUM(ml.TBitem_cupom_fiscal.DFvalor_liquido) AS [Valor Venda Liquido]
	 , SUM(ml.TBitem_cupom_fiscal.DFvalor_bruto) AS [Valor Total Bruto]
	 , AVG(ml.TBitem_cupom_fiscal.DFcusto_unitario) AS [Custo Unitário]
	 , AVG(CAST(ml.TBitem_cupom_fiscal.DFcusto_unitario * ml.TBitem_cupom_fiscal.DFquantidade AS DECIMAL(18,2))) AS [Custo Total]
	 , AVG(ISNULL(TBultimo_custo.DFpreco,0)) AS [Custo Real + CE]
	 , SUM(ml.TBitem_cupom_fiscal.DFvalor_icms + isnull(ml.TBitem_cupom_fiscal.DFvalor_pis,0) + isnull(ml.TBitem_cupom_fiscal.DFvalor_cofins,0)) AS [Valor Impostos] 
 	 , CASE WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '00:00:01' AND '01:00:00' THEN 1 
	        WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '01:00:01' AND '02:00:00' THEN 2 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '02:00:01' AND '03:00:00' THEN 3 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '03:00:01' AND '04:00:00' THEN 4 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '04:00:01' AND '05:00:00' THEN 5 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '05:00:01' AND '06:00:00' THEN 6 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '06:00:01' AND '07:00:00' THEN 7 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '07:00:01' AND '08:00:00' THEN 8 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '08:00:01' AND '09:00:00' THEN 9 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '09:00:01' AND '10:00:00' THEN 10
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '10:00:01' AND '11:00:00' THEN 11
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '11:00:01' AND '12:00:00' THEN 12
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '12:00:01' AND '13:00:00' THEN 13
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '13:00:01' AND '14:00:00' THEN 14
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '14:00:01' AND '15:00:00' THEN 15
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '15:00:01' AND '16:00:00' THEN 16
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '16:00:01' AND '17:00:00' THEN 17
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '17:00:01' AND '18:00:00' THEN 18
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '18:00:01' AND '19:00:00' THEN 19
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '19:00:01' AND '20:00:00' THEN 20
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '20:00:01' AND '21:00:00' THEN 21
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '21:00:01' AND '22:00:00' THEN 22
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '22:00:01' AND '23:00:00' THEN 23
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '23:00:01' AND '23:59:59' THEN 24 END AS [ID Hora]
	 , CASE WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '00:00:01' AND '06:00:00' THEN 4 
	        WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '06:00:01' AND '12:00:00' THEN 1
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '12:00:01' AND '18:00:00' THEN 2
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '18:00:01' AND '23:59:59' THEN 3 END AS [ID Periodo]  
    --, COUNT( DISTINCT ml.TBcupom_fiscal.DFid_cupom_fiscal) AS [Qtde Cupom]
  INTO #TBtemp_dados
  FROM ml.TBcupom_fiscal with (nolock)
 INNER JOIN TBempresa WITH (NOLOCK)
    ON TBempresa.DFcod_empresa = ml.TBcupom_fiscal.DFcod_empresa
 INNER JOIN ml.TBitem_cupom_fiscal with (nolock)
    ON ml.TBitem_cupom_fiscal.DFid_cupom_fiscal = ml.TBcupom_fiscal.DFid_cupom_fiscal
  LEFT JOIN (SELECT DFpreco
                  , DFid_unidade_item_estoque
                  , DFcod_empresa
                  , DFdata_alteracao
		  		  , DFid_historico_preco 
              FROM TBhistorico_preco WITH (NOLOCK)
             WHERE DFid_tipo_preco_venda = (SELECT DFvalor FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 821) ) AS TBultimo_custo 
    ON TBultimo_custo.DFid_unidade_item_estoque = ml.TBitem_cupom_fiscal.DFid_unidade_item_estoque 
   AND TBultimo_custo.DFcod_empresa =  ml.TBcupom_fiscal.DFcod_empresa 
   AND TBultimo_custo.DFid_historico_preco = (SELECT MAX(DFid_historico_preco) AS DFid_historico_preco  
                                                FROM TBhistorico_preco WITH (NOLOCK)
                                               WHERE DFid_tipo_preco_venda =  (SELECT DFvalor FROM TBopcoes WITH (NOLOCK) WHERE DFcodigo = 821) 
                                                 AND DFid_unidade_item_estoque =  ml.TBitem_cupom_fiscal.DFid_unidade_item_estoque 
                                                 AND DFcod_empresa =  ml.TBcupom_fiscal.DFcod_empresa 
                                                 AND CAST(CONVERT(NVARCHAR(8), DFdata_alteracao,112) + ' 00:00:00' AS SMALLDATETIME) <= CAST(CONVERT(NVARCHAR(8),  ml.TBcupom_fiscal.DFdata_movimento,112) + ' 00:00:00' AS SMALLDATETIME)) 

 WHERE ml.TBcupom_fiscal.DFdata_fechamento >= '2025-01-01'
   AND ml.TBcupom_fiscal.DFcancelado = 0 
   AND ml.TBitem_cupom_fiscal.DFcancelado = 0
GROUP BY ml.TBcupom_fiscal.DFid_cupom_fiscal 
	 , ml.TBcupom_fiscal.DFcod_empresa  
     , ml.TBitem_cupom_fiscal.DFcod_item_estoque  
	 , ml.TBcupom_fiscal.DFcod_operador 
	 , ml.TBcupom_fiscal.DFpdv
	 , CAST(ml.TBcupom_fiscal.DFdata_movimento AS DATE)   
	 , CASE WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '00:00:01' AND '01:00:00' THEN 1 
	        WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '01:00:01' AND '02:00:00' THEN 2 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '02:00:01' AND '03:00:00' THEN 3 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '03:00:01' AND '04:00:00' THEN 4 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '04:00:01' AND '05:00:00' THEN 5 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '05:00:01' AND '06:00:00' THEN 6 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '06:00:01' AND '07:00:00' THEN 7 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '07:00:01' AND '08:00:00' THEN 8 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '08:00:01' AND '09:00:00' THEN 9 
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '09:00:01' AND '10:00:00' THEN 10
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '10:00:01' AND '11:00:00' THEN 11
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '11:00:01' AND '12:00:00' THEN 12
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '12:00:01' AND '13:00:00' THEN 13
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '13:00:01' AND '14:00:00' THEN 14
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '14:00:01' AND '15:00:00' THEN 15
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '15:00:01' AND '16:00:00' THEN 16
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '16:00:01' AND '17:00:00' THEN 17
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '17:00:01' AND '18:00:00' THEN 18
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '18:00:01' AND '19:00:00' THEN 19
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '19:00:01' AND '20:00:00' THEN 20
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '20:00:01' AND '21:00:00' THEN 21
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '21:00:01' AND '22:00:00' THEN 22
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '22:00:01' AND '23:00:00' THEN 23
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '23:00:01' AND '23:59:59' THEN 24 END  
	 , CASE WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '00:00:01' AND '06:00:00' THEN 4 
	        WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '06:00:01' AND '12:00:00' THEN 1
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '12:00:01' AND '18:00:00' THEN 2
			WHEN CAST(ml.TBcupom_fiscal.DFdata_fechamento AS TIME) BETWEEN '18:00:01' AND '23:59:59' THEN 3 END  
			 


IF DBO.OBJECT_ID('DBDW_Director_Base.DBO.fatoVendaCupom') IS NOT NULL 
DROP TABLE DBDW_Director_Base.DBO.fatoVendaCupom

SELECT * INTO DBDW_Director_Base.DBO.fatoVendaCupom
 FROM #TBtemp_dados

--SELECT  COUNT(*) FROM #TBtemp_dados

END

-- exec DW_FATO_VENDA_CUPOM