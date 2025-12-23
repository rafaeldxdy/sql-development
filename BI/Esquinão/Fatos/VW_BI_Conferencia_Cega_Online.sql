IF DBO.OBJECT_ID('VW_BI_Conferencia_Cega') IS NOT NULL 
    DROP VIEW VW_BI_Conferencia_Cega
GO

CREATE VIEW VW_BI_Conferencia_Cega WITH ENCRYPTION
AS

SELECT DISTINCT TBficha.DFcod_empresa                                                                                                  AS Empresa,
                TBficha.DFid_ficha                                                                                                     AS id_ficha,
                TBficha.DFnum_ficha                                                                                                    AS [Número da Ficha],
                TBficha.DFdescricao                                                                                                    AS Descrição,
                COUNT(DISTINCT TBnota_fiscal_entrada.DFnumero)                                                                         AS [Quantidade de Notas],
                COUNT(TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada)                                                        AS [Quantidade Itens Nota],
                COUNT(CASE WHEN TBitem_conferencia.DFqtde_conferido > 0 THEN 1 END)                                                    AS [Quantidade Itens Conferidos],
                CAST(
                    CASE WHEN COUNT(TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada) > 0 THEN
                              ROUND((CAST(COUNT(CASE WHEN TBitem_conferencia.DFqtde_conferido > 0 THEN 1 END) AS DECIMAL(18, 2)) /
                                          COUNT(TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada)) * 100, 3)
                    ELSE
                        0.00
                    END AS DECIMAL(10,3))                                                                                              AS [Percentual Conferido],
                TBficha.DFstatus                                                                                                       AS [Status da Ficha],
                TBusuario.DFid_usuario                                                                                                 AS [Usuário ID]
FROM TBficha WITH(NOLOCK)
JOIN TBconferencia WITH(NOLOCK) ON Tbficha.DFid_ficha = TBconferencia.DFid_ficha
JOIN TBitem_conferencia WITH(NOLOCK) ON TBconferencia.DFid_relacao = TBitem_conferencia.DFid_relacao
JOIN TBitem_nota_fiscal_entrada WITH(NOLOCK) ON TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada = TBitem_conferencia.DFid_item_nota_fiscal_entrada
JOIN TBnota_fiscal_entrada WITH(NOLOCK) ON TBnota_fiscal_entrada.DFid_nota_fiscal_entrada = TBitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada
JOIN TBunidade_item_estoque WITH(NOLOCK) ON TBunidade_item_estoque.DFid_unidade_item_estoque = TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque
JOIN TBitem_estoque WITH(NOLOCK) ON TBitem_estoque.DFcod_item_estoque = TBunidade_item_estoque.DFcod_item_estoque
JOIN TBrelacao WITH(NOLOCK) ON TBrelacao.DFid_relacao = TBconferencia.DFid_relacao
JOIN TBtarefa WITH(NOLOCK) ON TBtarefa.DFid_relacao = TBrelacao.DFid_relacao
JOIN TBoperacao WITH(NOLOCK) ON TBoperacao.DFid_operacao = TBtarefa.DFid_operacao
JOIN TBequipe_operacao WITH(NOLOCK) ON TBequipe_operacao.DFid_operacao = TBoperacao.DFid_operacao
JOIN TBusuario WITH(NOLOCK) ON TBusuario.DFid_pessoa = TBequipe_operacao.DFid_pessoa
WHERE TBconferencia.DFdata_emissao >= CAST(GETDATE() AS DATE)
GROUP BY TBficha.DFcod_empresa,
         TBficha.DFnum_ficha,
         TBficha.DFid_ficha,
         TBficha.DFdescricao,
         TBficha.DFstatus,
         TBconferencia.DFid_usuario_critica_qtde,
         TBusuario.DFid_usuario
GO
