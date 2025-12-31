/*
    AUTOR..................: Rafael Ribeiro
	AREA...................: Logística
	MODULO.................: WMS
	DATA/HORA CRIAÇÂO......: 24/12/2025 11:02 AM
    DATA/HORA MODIFICAÇÂO..: 31/12/2025 13:30 PM
	OBJETIVO...............: Relatório analítico de ressuprimento para BI.

    Dados:

        (v) Data Criação;
        (v) Código Item;
        (v) ID Endereço Saída;
        (v) ID Endereço Entrada;
        (v) Quantidade Endereço;
        (v) Quantidade Abastecimento;
        (v) Quantidade Cortada;
        (v) Valor Custo;
        (v) Status;
        (v) Início Operação;
        (v) Fim Operação;
        (v) Usuário Criação;
        (v) Usuário Operação;
        (v) Usuário Cancelamento.

    Tabelas base:

        TBordem_movimentacao;
        VWpreco;
        TBunidade_item_estoque.
*/

IF DBO.OBJECT_ID('VW_BI_Ressuprimento_Online') IS NOT NULL 
    DROP VIEW VW_BI_Ressuprimento_Online
GO

CREATE VIEW VW_BI_Ressuprimento_Online WITH ENCRYPTION
AS

SELECT DISTINCT      
      TBordem_movimentacao.DFdata_criacao                                                                                 AS [Data Criação],
      TBordem_movimentacao.DFcod_item_estoque                                                                             AS [Código Item],
      TBordem_movimentacao.DFid_endereco_saida                                                                            AS [ID Endereço Saída],
      TBordem_movimentacao.DFid_endereco_entrada                                                                          AS [ID Endereço Entrada],
      TBordem_movimentacao.DFqtde_menor_sku_original_endereco_entrada                                                     AS [Quantidade Endereço],
      (TBordem_movimentacao.DFqtde * TBordem_movimentacao.DFfator_conversao)                                              AS [Quantidade Abastecimento],
      CASE WHEN
         TBordem_movimentacao.DFstatus = 'C' THEN (TBordem_movimentacao.DFqtde * TBordem_movimentacao.DFfator_conversao) 
            ELSE 0 END                                                                                                    AS [Quantidade Cortada],
      VWpreco.DFcusto_transferencia                                                                                       AS [Valor Custo],
      TBordem_movimentacao.DFstatus                                                                                       AS [Status],
      TBordem_movimentacao.DFdata_inicio_movto                                                                            AS [Início Operação],
      TBordem_movimentacao.DFdata_fim_movto                                                                               AS [Fim Operação],
      TBordem_movimentacao.DFid_usuario_criacao                                                                           AS [Usuário Criação],
      TBordem_movimentacao.DFid_usuario_movto                                                                             AS [Usuário Operação],
      TBordem_movimentacao.DFid_usuario_cancelado                                                                         AS [Usuário Cancelamento]
FROM
    TBordem_movimentacao WITH(NOLOCK)
    JOIN VWpreco WITH(NOLOCK) ON VWpreco.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
    JOIN TBunidade_item_estoque WITH(NOLOCK) ON TBunidade_item_estoque.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
        AND TBunidade_item_estoque.DFid_unidade_item_estoque = VWpreco.DFid_unidade_item_estoque
WHERE
    TBordem_movimentacao.DFdata_criacao >= CAST(GETDATE() AS DATE)
    AND DFtipo_movimento = 'Transferencia'
    AND TBunidade_item_estoque.DFfator_conversao = 1

GO
