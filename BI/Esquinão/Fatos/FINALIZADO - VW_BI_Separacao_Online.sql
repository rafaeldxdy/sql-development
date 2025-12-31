/*
    AUTOR..................: Rafael Ribeiro
	AREA...................: Logística
	MODULO.................: WMS
	DATA/HORA CRIAÇÂO......: 24/12/2025 11:02 AM
    DATA/HORA MODIFICAÇÂO..: 31/12/2025 13:26 PM
	OBJETIVO...............: Relatório analítico de separação para BI.

    Dados:

        (v) Empresa;
        (v) Empresa Destinatária;
        (v) Data de criação;
        (v) Código item;
        (v) Id endereço saída;
        (v) Quantidade no endereço;
        (v) Quantidade a separar;
        (v) Quantidade separada;
        (v) Diferença;
        (v) Custo;
        (v) Status separação;
        (v) Início da operação;
        (v) Fim da operação;
        (v) Usuário criação;
        (v) Usuário operação;
        (v) Usuário cancelamento.

    Tabelas base:

        TBordem_movimentacao;
        VWpreco;
        TBunidade_item_estoque;
        TBitem_pedido_venda;
        TBpedido_venda.
*/

IF DBO.OBJECT_ID('VW_BI_Separacao_Online') IS NOT NULL 
    DROP VIEW VW_BI_Separacao_Online
GO

CREATE VIEW VW_BI_Separacao_Online WITH ENCRYPTION
AS

SELECT DISTINCT
      TBordem_movimentacao.DFcod_empresa                                                                                                   AS [Empresa],
      TBpedido_venda.DFcod_empresa_destinataria                                                                                            AS [Empresa Destinatária],
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
    JOIN TBitem_pedido_venda WITH(NOLOCK) ON TBitem_pedido_venda.DFid_item_pedido_venda = TBordem_movimentacao.DFid_item_pedido_venda
    JOIN TBpedido_venda WITH(NOLOCK) ON TBpedido_venda.DFcod_pedido_venda = TBitem_pedido_venda.DFcod_pedido_venda
WHERE
    TBordem_movimentacao.DFdata_criacao >= CAST(GETDATE() AS DATE)
    AND DFtipo_movimento = 'Saida'
    AND TBunidade_item_estoque.DFfator_conversao = 1

GO
