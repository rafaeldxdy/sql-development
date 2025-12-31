/*
    AUTOR..................: Rafael Ribeiro
	AREA...................: Logística
	MODULO.................: WMS
	DATA/HORA CRIAÇÂO......: 24/12/2025 15:26
    DATA/HORA MODIFICAÇÂO..: 31/12/2025 11:11
	OBJETIVO...............: Relatório sintético da Montagem de Carga para BI.

    Dados:

        (v) Data de criação da carga;
        (v) Código da carga;
        (v) Quantidade de pedidos;
        (v) Quantidade de pallets;
        (v) Capacidade do veículo;
        (v) Peso carga;
        (v) Volume carga;
        (v) Valor carga;
        (v) Status da carga;
        (v) Quem a montou.

    Tabelas base:

        TBcarga
        TBpedido_venda_logistica
        TBveiculo
        TBcarroceria
        TBpalete_usado
*/

IF DBO.OBJECT_ID('VW_BI_Montagem_Carga') IS NOT NULL 
    DROP VIEW VW_BI_Montagem_Carga
GO

CREATE VIEW VW_BI_Montagem_Carga WITH ENCRYPTION
AS

WITH Montagem_Carga AS (
    SELECT
        TBcarga.DFdata_criacao                                 AS Data_criacao,
        TBcarga.DFcod_carga                                    AS Codigo_carga,
        COUNT(DISTINCT DFcod_pedido_venda_logistica)           AS Qtde_pedidos,
        COUNT(DISTINCT TBpalete_usado.DFid_palete_usado)       AS Qtde_pallets,
        TBcarroceria.DFnum_paletes                             AS Capacidade_veiculo,
        Tbcarga.DFpeso                                         AS Peso_carga,
        Tbcarga.DFvolume                                       AS Volume_carga,
        Tbcarga.DFvalor                                        AS Valor_carga,
        TBcarga.DFstatus                                       AS Status_carga, 
        TBpalete_usado.DFid_usuario_carregamento               AS id_pessoa_carregamento
    FROM 
        TBcarga WITH(NOLOCK)
        JOIN TBpedido_venda_logistica WITH(NOLOCK) ON TBpedido_venda_logistica.DFcod_carga = TBcarga.DFcod_carga
        JOIN TBveiculo WITH(NOLOCK) ON TBveiculo.DFid_veiculo = TBcarga.DFid_veiculo
        JOIN TBcarroceria WITH(NOLOCK) ON TBcarroceria.DFid_carroceria = TBveiculo.DFid_carroceria
        JOIN TBpalete_usado WITH(NOLOCK) ON TBpalete_usado.DFcod_carga = TBcarga.DFcod_carga
    WHERE 
        TBcarga.DFdata_criacao >= '2024-01-01'
    GROUP BY 
        TBcarga.DFdata_criacao,
        TBcarga.DFcod_carga,
        TBcarroceria.DFnum_paletes,
        Tbcarga.DFpeso,
        Tbcarga.DFvolume,
        Tbcarga.DFvalor,
        TBcarga.DFstatus,
        TBpalete_usado.DFid_usuario_carregamento
)

SELECT *
FROM Montagem_Carga

GO
