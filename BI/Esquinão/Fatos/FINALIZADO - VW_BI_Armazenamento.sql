/*
    AUTOR..................: Rafael Ribeiro
	AREA...................: Logística
	MODULO.................: WMS
	DATA/HORA CRIAÇÂO......: 24/12/2025 15:26
    DATA/HORA MODIFICAÇÂO..: 31/12/2025 10:57
	OBJETIVO: Relatório analítico de armazenamento para BI.

    Dados:

        (v) Data;
        (v) ID da ficha;
        (v) Entidade emitente (fornecedor ou empresa);
        (v) Qtde. SKUs;
        (v) Qtde. endereçada;
        (v) Percentual endereçado;
        (v) Valor recebido;
        (v) Custo;
        (v) Data recebimento;
        (v) Status endereçamento;
        (v) Data armazenamento;
        (v) Usuário endereçamento;
        (v) Cancelado por;
        (v) Usuário armazenamento.

    Tabelas base:

        TBficha;
        TBconferencia;
        TBitem_conferencia;
        TBitem_nota_fiscal_entrada;
        TBnota_fiscal_entrada;
        JOIN TBordem_movimentacao;
        VWpreco.
*/

IF DBO.OBJECT_ID('VW_BI_Armazenamento') IS NOT NULL 
    DROP VIEW VW_BI_Armazenamento
GO

CREATE VIEW VW_BI_Armazenamento WITH ENCRYPTION
AS

SELECT DISTINCT
    TBordem_movimentacao.DFdata_criacao                                                                      AS [Data],
    TBficha.DFid_ficha                                                                                       AS [ID ficha],
    ISNULL(TBnota_fiscal_entrada.DFcod_empresa_emitente, TBnota_fiscal_entrada.DFcod_fornecedor_emitente)    AS [Entidade emitente],
    COUNT(Tbitem_conferencia.DFid_item_nota_fiscal_entrada)                                                  AS [Quantidade SKUs],
    SUM(CASE WHEN TBordem_movimentacao.DFstatus = 'F' THEN 1 ELSE 0 END)                                     AS [Quantidade endereçada],
    CAST((
        SUM(CASE WHEN TBordem_movimentacao.DFstatus = 'F' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(TBitem_conferencia.DFid_item_nota_fiscal_entrada), 0) AS DECIMAL(5,2))                AS [Percentual endereçado],
    TBnota_fiscal_entrada.DFvalor_total                                                                      AS [Valor recebido],
    VWpreco.DFcusto_transferencia                                                                            AS [Custo],
    FORMAT(TBconferencia.DFdata_emissao, 'dd/MM/yyyy HH:mm:ss')                                              AS [Data recebimento],
    TBordem_movimentacao.DFstatus                                                                            AS [Status endereçamento],
    TBordem_movimentacao.DFdata_fim_movto                                                                    AS [Data armazenamento],
    TBordem_movimentacao.DFid_usuario_criacao                                                                AS [Usuário endereçamento],
    TBordem_movimentacao.DFid_usuario_cancelado                                                              AS [Cancelado por],
    TBordem_movimentacao.DFid_usuario_movto                                                                  AS [Usuário armazenamento]
FROM 
    TBficha WITH(NOLOCK)
    JOIN TBconferencia WITH(NOLOCK) ON Tbficha.DFid_ficha = TBconferencia.DFid_ficha
    JOIN TBitem_conferencia WITH(NOLOCK) ON TBconferencia.DFid_relacao = TBitem_conferencia.DFid_relacao
    JOIN TBitem_nota_fiscal_entrada WITH(NOLOCK) ON TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada = TBitem_conferencia.DFid_item_nota_fiscal_entrada
    JOIN TBnota_fiscal_entrada WITH(NOLOCK) ON TBnota_fiscal_entrada.DFid_nota_fiscal_entrada = TBitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada
    LEFT JOIN TBordem_movimentacao WITH(NOLOCK) ON TBordem_movimentacao.DFid_item_conferencia = TBitem_conferencia.DFid_item_conferencia
    JOIN VWpreco WITH(NOLOCK) ON VWpreco.DFcod_item_estoque = TBordem_movimentacao.DFcod_item_estoque
WHERE 
    TBconferencia.DFdata_emissao > '2024-01-01'
    AND TBordem_movimentacao.DFtipo_movimento = 'Entrada'
GROUP BY 
    TBordem_movimentacao.DFdata_criacao,
    TBficha.DFid_ficha,
    TBnota_fiscal_entrada.DFcod_empresa_emitente,
    TBnota_fiscal_entrada.DFcod_fornecedor_emitente, 
    TBordem_movimentacao.DFstatus,
    VWpreco.DFcusto_transferencia,
    TBconferencia.DFdata_emissao,
    TBordem_movimentacao.DFdata_fim_movto,
    TBnota_fiscal_entrada.DFvalor_total,
    TBordem_movimentacao.DFid_usuario_criacao,
    TBordem_movimentacao.DFid_usuario_cancelado,
    TBordem_movimentacao.DFid_usuario_movto
    
GO
