/*
    AUTOR..................: Rafael Ribeiro
    AREA...................: Logística
    MODULO.................: WMS
    DATA/HORA CRIAÇÃO......: 24/12/2025 15:26 PM
    DATA/HORA MODIFICAÇÃO..: 31/12/2025 11:45 PM
    DATA/HORA REVISÃO......: 01/01/2026 19:51 PM
    OBJETIVO...............: Relatório analítico de armazenamento para BI.
*/

IF OBJECT_ID('VW_BI_Armazenamento') IS NOT NULL 
    DROP VIEW VW_BI_Armazenamento;
GO

CREATE VIEW VW_BI_Armazenamento WITH ENCRYPTION
AS

    WITH CTEcusto_menor_unidade_item AS (
        SELECT
            VWpreco.DFcod_empresa AS DFcod_empresa_custo,
            VWpreco.DFcod_item_estoque,
            VWpreco.DFcusto_transferencia,
            VWpreco.DFdata_ultima_alteracao
        FROM VWpreco WITH (NOLOCK)
        JOIN TBunidade_item_estoque WITH (NOLOCK) 
            ON VWpreco.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque
        JOIN (
            SELECT -- Busca o menor fator para garantir a unidade principal do item
                TBunidade_item_estoque.DFcod_item_estoque,
                MIN(TBunidade_item_estoque.DFfator_conversao) AS DFmenor_fator 
            FROM TBunidade_item_estoque WITH (NOLOCK)
            WHERE TBunidade_item_estoque.DFativo_inativo = 1
            GROUP BY TBunidade_item_estoque.DFcod_item_estoque
        ) AS SBMenor_unidade 
            ON SBMenor_unidade.DFcod_item_estoque = TBunidade_item_estoque.DFcod_item_estoque 
            AND SBMenor_unidade.DFmenor_fator = TBunidade_item_estoque.DFfator_conversao
        JOIN (
            SELECT -- Busca a data máxima para garantir o custo mais recente
                DFid_unidade_item_estoque,
                MAX(DFdata_ultima_alteracao) AS DFmaior_data
            FROM VWpreco WITH (NOLOCK)
            GROUP BY DFid_unidade_item_estoque
        ) AS SBUltima_atualizacao
            ON VWpreco.DFid_unidade_item_estoque = SBUltima_atualizacao.DFid_unidade_item_estoque
            AND VWpreco.DFdata_ultima_alteracao = SBUltima_atualizacao.DFmaior_data
        WHERE 
            TBunidade_item_estoque.DFativo_inativo = 1
            -- AND VWpreco.DFcod_empresa = 7
    ),

    CTEenderecamento AS (
        SELECT 
            TBordem_movimentacao.DFcod_empresa AS DFcod_empresa_movimentacao,
            TBconferencia.DFdata_emissao AS DFdata_recebimento,
            TBficha.DFid_ficha,
            ISNULL(TBnota_fiscal_entrada.DFcod_fornecedor_emitente, TBnota_fiscal_entrada.DFcod_empresa_emitente) AS DFcod_entidade_emitente,
            TBnota_fiscal_entrada.DFid_nota_fiscal_entrada,
            TBordem_movimentacao.DFcod_item_estoque,
            (TBitem_nota_fiscal_entrada.DFqtde * TBunidade_item_estoque.DFfator_conversao) AS DFqtde_nota_fiscal,
            TBitem_conferencia.DFqtde_conferido AS DFqtde_recebido,
            TBconferencia.DFid_usuario_critica_qtde AS DFid_usuario_critica,
            TBordem_movimentacao.DFdata_criacao,
            TBordem_movimentacao.DFid_usuario_criacao AS DFid_usuario_enderecamento,
            (TBordem_movimentacao.DFqtde * TBordem_movimentacao.DFfator_conversao) AS DFqtde_enderecar,
            TBordem_movimentacao.DFstatus,
            TBordem_movimentacao.DFdata_inicio_movto AS DFdata_inicio_enderecamento,
            TBordem_movimentacao.DFdata_fim_movto AS DFdata_fim_enderecamento,
            TBordem_movimentacao.DFid_usuario_movto AS DFid_usuario_armazenamento,
            TBordem_movimentacao.DFid_usuario_cancelado AS DFid_usuario_cancelamento
        FROM 
            TBordem_movimentacao WITH (NOLOCK)
            JOIN TBitem_conferencia WITH (NOLOCK) 
                ON TBitem_conferencia.DFid_item_conferencia = TBordem_movimentacao.DFid_item_conferencia
            JOIN TBitem_nota_fiscal_entrada WITH (NOLOCK)
                ON TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada = TBitem_conferencia.DFid_item_nota_fiscal_entrada
            JOIN TBnota_fiscal_entrada WITH (NOLOCK)
                ON TBnota_fiscal_entrada.DFid_nota_fiscal_entrada = TBitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada
            JOIN TBunidade_item_estoque WITH (NOLOCK)
                ON TBunidade_item_estoque.DFid_unidade_item_estoque = TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque
            JOIN TBconferencia WITH (NOLOCK)
                ON TBconferencia.DFid_relacao = TBitem_conferencia.DFid_relacao
            LEFT JOIN TBficha WITH (NOLOCK)
                ON TBficha.DFid_ficha = TBconferencia.DFid_ficha
        WHERE 
            DFtipo_movimento = 'Entrada'
            AND TBordem_movimentacao.DFdata_criacao >= '2024-01-01'
            -- AND TBordem_movimentacao.DFcod_empresa = 7
    )

    SELECT 
        CTEenderecamento.DFcod_empresa_movimentacao,
        CTEcusto_menor_unidade_item.DFcod_empresa_custo,
        CTEenderecamento.DFdata_recebimento,
        CTEenderecamento.DFid_ficha,
        CTEenderecamento.DFcod_entidade_emitente,
        CTEenderecamento.DFid_nota_fiscal_entrada,
        CTEenderecamento.DFcod_item_estoque,
        CTEenderecamento.DFqtde_nota_fiscal,
        CTEenderecamento.DFqtde_recebido,
        CTEcusto_menor_unidade_item.DFcusto_transferencia,
        CTEenderecamento.DFid_usuario_critica,
        CTEenderecamento.DFdata_criacao,
        CTEenderecamento.DFid_usuario_enderecamento,
        CTEenderecamento.DFqtde_enderecar,
        CTEenderecamento.DFstatus,
        CTEenderecamento.DFdata_inicio_enderecamento,
        CTEenderecamento.DFdata_fim_enderecamento,
        CTEenderecamento.DFid_usuario_armazenamento,
        CTEenderecamento.DFid_usuario_cancelamento
    FROM 
        CTEenderecamento
    JOIN 
        CTEcusto_menor_unidade_item
            ON CTEenderecamento.DFcod_item_estoque = CTEcusto_menor_unidade_item.DFcod_item_estoque

GO
