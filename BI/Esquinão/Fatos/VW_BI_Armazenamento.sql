IF DBO.OBJECT_ID('VW_BI_Armazenamento') IS NOT NULL 
    DROP VIEW VW_BI_Armazenamento
GO

CREATE VIEW VW_BI_Armazenamento WITH ENCRYPTION
AS

SELECT DISTINCT
    TBficha.DFid_ficha                                                                                       AS [ID ficha],
    ISNULL(TBnota_fiscal_entrada.DFcod_empresa_emitente, TBnota_fiscal_entrada.DFcod_fornecedor_emitente)    AS [Entidade emitente],
    COUNT(Tbitem_conferencia.DFid_item_nota_fiscal_entrada)                                                  AS [Quantidade SKUs],
    CASE WHEN TBordem_movimentacao.DFstatus = 'F' THEN SUM(1) ELSE 0 END                                     AS [Quantidade endereçada],
    CAST((
        SUM(CASE WHEN TBordem_movimentacao.DFstatus = 'Feito' THEN 1 ELSE 0 END) * 100.0)
        / NULLIF(COUNT(TBitem_conferencia.DFid_item_nota_fiscal_entrada), 0) AS DECIMAL(5,2))                AS [Percentual endereçado],
    TBnota_fiscal_entrada.DFvalor_total                                                                      AS [Valor recebido],
    FORMAT(TBconferencia.DFdata_emissao, 'dd/MM/yyyy HH:mm:ss')                                              AS [Data recebimento],
    TBordem_movimentacao.DFstatus_descritivo                                                                 AS [Status endereçamento],
    TBordem_movimentacao.DFdata_fim_movto                                                                    AS [Data armazenamento],
    TBordem_movimentacao.DFid_usuario_criacao                                                                AS [Usuário endereçamento],
    TBordem_movimentacao.DFid_usuario_cancelado                                                              AS [Cancelado por],
    TBordem_movimentacao.DFid_usuario_movto                                                                  AS [Usuário armazenamento]
FROM TBficha WITH(NOLOCK)
JOIN TBconferencia WITH(NOLOCK) ON Tbficha.DFid_ficha = TBconferencia.DFid_ficha
JOIN TBitem_conferencia WITH(NOLOCK) ON TBconferencia.DFid_relacao = TBitem_conferencia.DFid_relacao
JOIN TBitem_nota_fiscal_entrada WITH(NOLOCK) ON TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada = TBitem_conferencia.DFid_item_nota_fiscal_entrada
JOIN TBnota_fiscal_entrada WITH(NOLOCK) ON TBnota_fiscal_entrada.DFid_nota_fiscal_entrada = TBitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada
LEFT JOIN TBordem_movimentacao WITH(NOLOCK) ON TBordem_movimentacao.DFid_item_conferencia = TBitem_conferencia.DFid_item_conferencia
WHERE TBconferencia.DFdata_emissao >= '2024-01-01'
AND TBordem_movimentacao.DFtipo_movimento = 'Entrada'
GROUP BY TBficha.DFid_ficha,
         TBordem_movimentacao.DFstatus_descritivo,
         TBnota_fiscal_entrada.DFcod_fornecedor_emitente, 
         TBnota_fiscal_entrada.DFcod_empresa_emitente,
         TBordem_movimentacao.DFdata_fim_movto,
         TBnota_fiscal_entrada.DFvalor_total,
         TBconferencia.DFdata_emissao,
         TBordem_movimentacao.DFstatus,
         TBordem_movimentacao.DFid_usuario_criacao,
         TBordem_movimentacao.DFid_usuario_cancelado,
         TBordem_movimentacao.DFid_usuario_movto

GO
