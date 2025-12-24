/*
    Documentação:

	AUTOR......: Rafael Ribeiro
	AREA.......: Logística
	MODULO.....: WMS
	DATA/HORA..: 24/12/2025 13:35
    VERSÃO.....: 1.0
	
	Função.....: Analista de Suporte Técnico Jr.

    Objetivo: criar relatório sintético da conferência de expedição, contendo os seguintes dados:

        * Dados:

            (v) Relação (cada relação é um pallet);
            (v) Quantidade de itens;
            (v) Quantidade conferida;
            (v) Quantidade restante;
            (v) Percentual conferido;
            (v) Status;
            (v) id_pessoa;
            (v) Crítico.

        * Tabelas base:

            - TBretorno_coletor_conferencia_doca
            - TBitem_retorno_coletor_conferencia_doca
            - TBtarefa
            - TBoperacao
            - TBequipe_operacao
*/

IF DBO.OBJECT_ID('VW_BI_Conferencia_Expedicao') IS NOT NULL 
    DROP VIEW VW_BI_Conferencia_Expedicao
GO

CREATE VIEW VW_BI_Conferencia_Expedicao WITH ENCRYPTION
AS

WITH Conferencia_Doca AS (
    SELECT TBretorno_coletor_conferencia_doca.DFid_relacao                                                     AS Relacao,
           COUNT(TBitem_retorno_coletor_conferencia_doca.DFid_item_retorno_coletor_conferencia_doca)           AS Quantidade_itens,
           SUM(CASE WHEN TBitem_retorno_coletor_conferencia_doca.DFqtde_conferido > 0 THEN 1 ELSE 0 END)       AS Quantidade_conferida,
           TBretorno_coletor_conferencia_doca.DFstatus                                                         AS [Status],
           TBequipe_operacao.DFid_pessoa                                                                       AS id_pessoa,
           TBretorno_coletor_conferencia_doca.DFid_usuario_critica                                             AS id_usuario_critica
    FROM TBretorno_coletor_conferencia_doca WITH(NOLOCK)
    JOIN TBitem_retorno_coletor_conferencia_doca WITH(NOLOCK)
        ON TBretorno_coletor_conferencia_doca.DFid_retorno_coletor_conferencia_doca = TBitem_retorno_coletor_conferencia_doca.DFid_retorno_coletor_conferencia_doca
    JOIN TBtarefa WITH(NOLOCK)
        ON TBtarefa.DFid_relacao = TBretorno_coletor_conferencia_doca.DFid_relacao
    JOIN TBoperacao WITH(NOLOCK)
        ON TBoperacao.DFid_operacao = TBtarefa.DFid_operacao
    JOIN TBequipe_operacao WITH(NOLOCK)
        ON TBequipe_operacao.DFid_operacao = TBoperacao.DFid_operacao
    WHERE TBretorno_coletor_conferencia_doca.DFdata_hora > '2024-01-01'
    GROUP BY TBretorno_coletor_conferencia_doca.DFid_relacao,
             TBretorno_coletor_conferencia_doca.DFstatus,
             TBequipe_operacao.DFid_pessoa,
             TBretorno_coletor_conferencia_doca.DFid_usuario_critica
)

SELECT Relacao,
       Quantidade_itens,
       Quantidade_conferida,
       (Quantidade_itens - Quantidade_conferida)                                             AS Quantidade_restante,
       FORMAT(CAST(Quantidade_conferida AS DECIMAL(10,2)) / Quantidade_itens * 100, 'N2')    AS Percentual_conferido,
       [Status],
       id_pessoa,
       id_usuario_critica
FROM Conferencia_Doca;

GO
