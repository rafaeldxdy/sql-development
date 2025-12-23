/*
IF DBO.OBJECT_ID('VW_BI_Conferencia_Expedicao') IS NOT NULL 
    DROP VIEW VW_BI_Conferencia_Expedicao
GO

CREATE VIEW VW_BI_Conferencia_Expedicao WITH ENCRYPTION
AS
*/

SELECT DISTINCT
    TBordem_movimentacao.DFid_palete_usado                                                                                 AS [ID Palete Usado],
    COUNT(TBordem_movimentacao.DFid_palete_usado)                                                                          AS [Quantidade Itens],
    CASE WHEN TBordem_movimentacao.DFstatus = 'F' THEN SUM(1) ELSE SUM(0) END                                              AS [Quantidade Itens Separados],
    COUNT(TBitem_retorno_coletor_conferencia_doca.DFqtde_definitivo)                                                       AS [Quantidade Definitiva],
    COUNT(TBitem_retorno_coletor_conferencia_doca.DFqtde_definitivo) / COUNT(TBordem_movimentacao.DFid_palete_usado) * 100 AS [Percentual Conferido]
FROM
    TBordem_movimentacao WITH (NOLOCK)
    JOIN TBpalete_usado WITH (NOLOCK) ON TBpalete_usado.DFid_palete_usado = TBordem_movimentacao.DFid_palete_usado
    JOIN TBunidade_item_estoque WITH (NOLOCK) ON TBunidade_item_estoque.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
    JOIN TBitem_retorno_coletor_conferencia_doca WITH (NOLOCK) ON TBitem_retorno_coletor_conferencia_doca.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque
    JOIN TBretorno_coletor_conferencia_doca WITH (NOLOCK) ON TBretorno_coletor_conferencia_doca.DFid_retorno_coletor_conferencia_doca = TBitem_retorno_coletor_conferencia_doca.DFid_item_retorno_coletor_conferencia_doca
GROUP BY
    TBordem_movimentacao.DFid_palete_usado,
    TBordem_movimentacao.DFstatus
    
    /*

select * from TBretorno_coletor_conferencia_doca
select * from TBitem_retorno_coletor_conferencia_doca
select * from tbpalete_usado

SELECT DISTINCT
      TBordem_movimentacao.DFdata_criacao                                                                                                  AS [Data Criação],
      TBordem_movimentacao.DFcod_item_estoque                                                                                              AS [Código Item],
      TBordem_movimentacao.DFid_endereco_saida                                                                                             AS [ID Endereço Saída],
      TBordem_movimentacao.DFqtde_menor_sku_original_endereco_saida                                                                        AS [Quantidade Endereço],
      (TBordem_movimentacao.DFqtde * TBordem_movimentacao.DFfator_conversao)                                                               AS [Quantidade Separar],
      TBordem_movimentacao.DFqtde_movimentada_menor_sku                                                                                    AS [Quantidade Separada],
      ABS((TBordem_movimentacao.DFqtde * TBordem_movimentacao.DFfator_conversao) - (TBordem_movimentacao.DFqtde_movimentada_menor_sku))    AS [Diferença],
      VWpreco.DFcusto_transferencia                                                                                                        AS [Valor Custo],
      TBordem_movimentacao.DFstatus                                                                                                        AS [Status],
      TBordem_movimentacao.DFdata_inicio_movto                                                                                             AS [Início Operação],
      TBordem_movimentacao.DFdata_fim_movto                                                                                                AS [Fim Operação],
      TBordem_movimentacao.DFid_usuario_criacao                                                                                            AS [Usuário Criação],
      TBordem_movimentacao.DFid_usuario_movto                                                                                              AS [Usuário Operação],
      TBordem_movimentacao.DFid_usuario_cancelado                                                                                          AS [Usuário Cancelamento]
FROM
    TBordem_movimentacao WITH(NOLOCK)
    JOIN VWpreco WITH(NOLOCK) ON VWpreco.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
    JOIN TBunidade_item_estoque WITH(NOLOCK) ON TBunidade_item_estoque.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
        AND TBunidade_item_estoque.DFid_unidade_item_estoque = VWpreco.DFid_unidade_item_estoque
WHERE
    TBordem_movimentacao.DFdata_criacao >= CAST(GETDATE() AS DATE)
    AND DFtipo_movimento = 'Saida'
    AND TBunidade_item_estoque.DFfator_conversao = 1

/*
GO
*/

*/
