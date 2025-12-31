/*
    AUTOR..................: Rafael Ribeiro
	AREA...................: Logística
	MODULO.................: WMS
	DATA/HORA CRIAÇÂO......: 24/12/2025 16:00 PM
    DATA/HORA MODIFICAÇÂO..: 31/12/2025 12:08 PM
    DATA/HORA REVISÂO......: 31/12/2025 15:48 PM
	OBJETIVO...............: Relatório analítico de Conferência Cega para BI.

    Dados:

        (v) Data;
        (v) Empresa;
        (v) id ficha;
        (v) Número ficha;
        (v) Descrição;
        (v) Quantidade notas;
        (v) Quantidade itens nas notas;
        (v) Quantidade itens conferidos;
        (v) Devolução (sim/não);
        (v) Percentual conferidos;
        (v) Status ficha;
        (v) Id do usuário.

    Tabelas base:

        TBficha,
        TBconferencia,
        TBitem_conferencia,
        TBitem_nota_fiscal_entrada,
Deus    TBnota_fiscal_entrada,
        TBunidade_item_estoque,
        TBitem_estoque,
        TBrelacao,
        TBtarefa,
        TBoperacao,
        TBequipe_operacao,
        TBusuario;
*/

IF DBO.OBJECT_ID('VW_BI_Conferencia_Cega_Online') IS NOT NULL 
    DROP VIEW VW_BI_Conferencia_Cega_Online
GO

CREATE VIEW VW_BI_Conferencia_Cega_Online WITH ENCRYPTION
AS

WITH Conferencia AS(
    SELECT DISTINCT
    FORMAT(TBconferencia.DFdata_emissao, 'dd/MM/yyyy HH:mm')                                                                          AS [Data conferência],
    TBficha.DFcod_empresa                                                                                                             AS Empresa,
    TBficha.DFid_ficha                                                                                                                AS id_ficha,
    TBficha.DFnum_ficha                                                                                                               AS [Número da Ficha],
    TBficha.DFdescricao                                                                                                               AS Descrição,
    COUNT(DISTINCT TBnota_fiscal_entrada.DFnumero)                                                                                    AS [Quantidade de Notas],
    COUNT(DISTINCT TBitem_conferencia.DFid_item_nota_fiscal_entrada)                                                                  AS [Quantidade Itens Conferência],
    COUNT(DISTINCT CASE 
        WHEN TBitem_conferencia.DFqtde_conferido > 0 
        THEN TBitem_conferencia.DFid_item_nota_fiscal_entrada 
    END)                                                                                                                              AS [Quantidade Itens Conferidos],
    CAST(
    (CAST(COUNT(DISTINCT CASE 
        WHEN TBitem_conferencia.DFqtde_conferido > 0 THEN TBitem_conferencia.DFid_item_nota_fiscal_entrada END) AS DECIMAL(18, 2)) 
        / NULLIF(COUNT(DISTINCT TBitem_conferencia.DFid_item_nota_fiscal_entrada), 0)) * 100                                          AS DECIMAL(10,3)) AS [Percentual Conferido],
    TBficha.DFstatus                                                                                                                  AS [Status da Ficha],
    TBusuario.DFid_usuario                                                                                                            AS [Usuário ID]
FROM 
    TBficha WITH(NOLOCK)
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
WHERE 
    TBconferencia.DFdata_emissao >= CAST(GETDATE() AS DATE)
GROUP BY
    FORMAT(TBconferencia.DFdata_emissao, 'dd/MM/yyyy HH:mm'),
    TBficha.DFcod_empresa,
    TBficha.DFnum_ficha,
    TBficha.DFid_ficha,
    TBficha.DFdescricao,
    TBficha.DFstatus,
    TBconferencia.DFid_usuario_critica_qtde,
    TBusuario.DFid_usuario
)

SELECT 
    [Data conferência],
    Empresa,
    id_ficha,
    [Número da Ficha],
    Descrição,
    [Quantidade de Notas],
    [Quantidade Itens Conferência],
    [Quantidade Itens Conferidos],
    CASE
        WHEN [Quantidade Itens Conferidos] < [Quantidade Itens Conferência] 
            AND [Status da Ficha] IN ('Endereçadas', 'Criticadas', 'Parcialmente Endereçadas', 'Endereçado Total online', 'Parcialmente Endereçadas Online')
        THEN 'Sim'
        ELSE 'Não' 
    END AS [Devolução],
    [Percentual Conferido],
    [Status da Ficha],
    [Usuário ID]
FROM Conferencia

GO
