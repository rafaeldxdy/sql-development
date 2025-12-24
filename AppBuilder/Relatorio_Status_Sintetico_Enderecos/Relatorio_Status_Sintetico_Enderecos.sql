/*
	Nomenclaturas usadas nos projetos:

	sp_Detalhar_NomeDaPagina
	sp_Listar_NomeDaPagina
	sp_Editar_
	sp_Excluir_
	sp_Persistir_

	Documentação:

	AUTOR......: Rafael Ribeiro
	AREA.......: Logística
	MODULO.....: WMS
	DATA/HORA..: 
	
	Função.....: Analista de Suporte Técnico Jr.

	Objetivo: criar relatório sintético de status de endereços.
	TomTicket: 
	GitLab: 
*/

SELECT * FROM sysobjects WHERE NAME LIKE 'sp_listar_Status_Sintetico_Enderecos'

IF OBJECT_ID('sp_listar_Status_Sintetico_Enderecos') IS NOT NULL
  DROP PROCEDURE sp_listar_Status_Sintetico_Enderecos
GO

CREATE PROCEDURE sp_listar_Status_Sintetico_Enderecos (@xml XML)
AS
  SET ARITHABORT ON
BEGIN

	/**************************************************************
	* Variveis para armazenar os valores lidos de @xml - Não mexer
	***************************************************************/

	DECLARE @pagina               NVARCHAR(10)
		  , @limite               INT
		  , @ordenacao            NVARCHAR(500)
		  , @UsuarioId            INT
		  , @idCdPadrao           INT
		  , @codEmpresaPadrao     INT
		  , @indice_de			  INT
		  , @indice_ate			  INT
		  , @pagina_int			  INT
		  , @limite_int			  INT
		  , @quantidade_total	  INT
		  , @quantidade_parcial	  INT
		  , @ordenacao_coluna	  NVARCHAR(150)
		  , @ordenacao_direcao    NVARCHAR(10)
		  , @data_entrada_inicial NVARCHAR(30)
		  , @data_entrada_final   NVARCHAR(30)
		  , @stealth              INT
		  , @exportar             NVARCHAR(20)
		
	EXEC sp_IO_Log_WMS 'Inicio rotina sp_listar_Status_Sintetico_Enderecos : '
	
	/****************************************************
	* Carrega as variáveis fixas - Não mexer
	****************************************************/

	SELECT @stealth           = isnull(DFxml.value('*[lower-case(local-name())="stealth"][1]', 'INT'), 1) 
		 , @pagina            = DFxml.value('*[lower-case(local-name())="pagina"][1]', 'NVARCHAR(10)')
		 , @limite            = DFxml.value('*[lower-case(local-name())="limite"][1]', 'INT')
		 , @ordenacao         = DFxml.value('*[lower-case(local-name())="ordenacao"][1]', 'NVARCHAR(100)')
		 , @UsuarioId         = DFxml.value('(id_usuario)[1]','INT')
		 , @exportar          = DFxml.value('*[lower-case(local-name())="exportar"][1]', 'NVARCHAR(10)')
	FROM @xml.nodes('./*') AS XMLparametros(DFxml)

	EXEC sp_IO_Log_WMS 'Desserializando o xml '

	/****************************************************
	* Filtro Empresa usuario - Não mexer
	****************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBempresaFiltroUsuario') IS NOT NULL 
		DROP TABLE #TBempresaFiltroUsuario

	SELECT TBempresa.DFcod_empresa
	     , DFid_centro_distribuicao
	  INTO #TBempresaFiltroUsuario
	  FROM TBempresa WITH(NOLOCK) 
INNER JOIN TBcentro_distribuicao  WITH(NOLOCK) 
	    ON TBempresa.DFcod_empresa = TBcentro_distribuicao.DFcod_empresa
	 WHERE TBempresa.DFcod_empresa IN (SELECT itens
										  FROM acesso.TBaplicacao WITH(NOLOCK)
									INNER JOIN acesso.TBpapel WITH(NOLOCK) 
											ON TBaplicacao.DFid_aplicacao = TBpapel.DFid_aplicacao
									INNER JOIN acesso.TBpapel_usuario_empresa WITH(NOLOCK) 
											ON TBpapel.DFid_papel = TBpapel_usuario_empresa.DFid_papel
									 CROSS APPLY dbo.fn_Split (DFcod_empresas, ',')
										 where DFid_usuario = @UsuarioId
										   AND TBaplicacao.DFchave = 'wms')

	/***************************************************
	* TRATAMENTO PARA PAGINAÇÃO:
	***************************************************/

     IF(ISNULL(@pagina, '') = '' OR @pagina = '0')
     BEGIN
		SET @pagina = 1
     END
     
     IF(ISNULL(@limite, '') = '' OR @limite = '0')
     BEGIN
		SET @limite = 10
     END

     SELECT @pagina_int = CAST(@pagina AS INT)
          , @limite_int = CAST(@limite AS INT)
     
        SET @indice_de  = ((@pagina_int - 1) * @limite_int) + 1
        SET @indice_ate = @pagina_int * @limite_int

    /***************************************************
    * TRATAMENTO PARA ORDENAÇÃO:
    ***************************************************/

    DECLARE @coluna  NVARCHAR(256) = (SELECT Itens FROM Split(@ordenacao, ',') WHERE Id = 1)
          , @direcao NVARCHAR(256) = (SELECT Itens FROM Split(@ordenacao, ',') WHERE Id = 2)

		  SET @ordenacao_coluna = CASE WHEN @coluna = ',' OR @coluna IS NULL OR @coluna = '' THEN 'DFnivel' ELSE @coluna END
          SET @ordenacao_direcao = ISNULL(@direcao, 'asc')

	EXEC sp_IO_Log_WMS  'Fim processo de tratamento paginacao / ordenação'

    /*******************************
    * INÍCIO DO PROCESSO - SQL BASE
    ********************************/

	IF OBJECT_ID('tempdb..#temp_dados') IS NOT NULL
		DROP TABLE #temp_dados

	SELECT
		ISNULL(
			CASE WHEN CAST(DFnivel AS NVARCHAR(MAX)) = '0' THEN 'Picking' 
				 ELSE CAST(DFnivel AS NVARCHAR(MAX)) 
			END, 'Total' )                                                                                              AS DFnivel,
		SUM(CASE WHEN TBitem_endereco_armazenagem_lote.DFqtde <> 0 THEN 1 ELSE 0 END)                                   AS DFenderecos_ocupados,
		SUM(CASE WHEN TBitem_endereco_armazenagem.DFid_item_endereco_armazenagem IS NULL THEN 1 ELSE 0 END)             AS DFenderecos_desocupados,
		SUM(CASE WHEN TBitem_endereco_armazenagem_lote.DFqtde = 0 THEN 1 ELSE 0 END)                                    AS DFenderecos_vazios,
		SUM(CASE WHEN TBendereco_armazenagem.DFid_motivo_bloqueio_endereco IN (4, 5, 6, 7, 2, 10) THEN 1 ELSE 0 END)    AS DFenderecos_bloqueados,
		COUNT(TBendereco_armazenagem.DFid_endereco_armazenagem)                                                         AS DFtotal_enderecos
	INTO #temp_dados
	FROM TBendereco_armazenagem WITH(NOLOCK)
	LEFT JOIN TBitem_endereco_armazenagem WITH(NOLOCK) 
		ON TBendereco_armazenagem.DFid_endereco_armazenagem = TBitem_endereco_armazenagem.DFid_item_endereco_armazenagem
	LEFT JOIN TBitem_endereco_armazenagem_lote WITH(NOLOCK) 
		ON TBitem_endereco_armazenagem_lote.DFid_item_endereco_armazenagem = TBitem_endereco_armazenagem.DFid_item_endereco_armazenagem
	WHERE
		TBendereco_armazenagem.DFid_tipo_estoque = 2
	GROUP BY DFnivel WITH ROLLUP
	ORDER BY GROUPING(DFnivel), DFnivel

	/***************************************************
    * FIM DO PROCESSO
    ***************************************************/

	EXEC sp_IO_Log_WMS  'Fim processo principal'

	BEGIN TRY
		DECLARE @query NVARCHAR(MAX)
		
		CREATE TABLE #temp_resultados ( Linha INT )

		SET @query = STUFF(
		(SELECT ';ALTER TABLE #temp_resultados ADD ' + cols.name + ' ' + tipo.name + CASE WHEN tipo.name NOT IN ('nvarchar', 'bit', 'int', 'tinyint', 'smallint', 'bigint', 'binary', 'float', 'date', 'datetime', 'smalldatetime', 'time') 
		                                                                                  THEN 
		  																					CASE WHEN cols.precision = 0 
		  																					     THEN '(' + CAST(cols.max_length AS VARCHAR) + ')'
		  																						 ELSE '(' + CAST(cols.precision AS VARCHAR) + CASE WHEN cols.scale > 0 THEN ',' + CAST(cols.scale AS VARCHAR) END + ')'
		  																					 END 
		  																				  WHEN tipo.name = 'NVARCHAR'
																						  THEN '(' + ( CASE WHEN cols.max_length > 0 THEN CAST(cols.max_length / 2 AS VARCHAR) ELSE 'MAX' END ) + ')'
																						  ELSE '' 
		  																			 END + CHAR(10)
		 FROM tempdb.sys.columns AS cols
		INNER JOIN SYS.types AS tipo
		        ON tipo.user_type_id = cols.user_type_id
		WHERE object_id = object_id('tempdb..#temp_dados')
		  FOR XML PATH ('')), 1, 1, '') 
		
		EXEC(@query)

	END TRY
	
	BEGIN CATCH
		PRINT '---------------------------------------------------------------------------'
		PRINT 'OCORREU UM ERRO AO ALTERAR AS TABELAS'
		PRINT 'VERIFIQUE O ERRO PELA QUERY CRIADA E AJUSTE O QUE FOR NECESSÁRIO'
		PRINT '---------------------------------------------------------------------------'
		PRINT @QUERY
		
		SELECT 'OCORREU UM ERRO'
		EXEC sp_IO_Log_WMS  'Ocorreu um erro' 

		RETURN
	END CATCH

	SET @query = 'INSERT INTO #temp_resultados '
	SET @query = @query + 'SELECT '
	SET @query = @query + 'ROW_NUMBER() OVER(ORDER BY '
	SET @query = @query + @ordenacao_coluna + ' ' + @ordenacao_direcao
	SET @query = @query + ') AS linha, '

	SET @query = @query + STUFF(
                            (SELECT ',' + cols.name
                             FROM tempdb.sys.columns AS cols
                             INNER JOIN SYS.types AS tipo
                                     ON tipo.user_type_id = cols.user_type_id
                             WHERE object_id = object_id('tempdb..#temp_dados')
                               FOR XML PATH ('')), 1, 1, '') 

	SET @query = @query + ' FROM #temp_dados;'
	
	EXEC(@query)

	SELECT @quantidade_total = COUNT(DISTINCT DFnivel) FROM #temp_resultados WITH(NOLOCK)
	SELECT @quantidade_parcial = COUNT(DISTINCT DFnivel) FROM #temp_resultados WITH(NOLOCK)
		
	IF @exportar = 'csv'
	BEGIN
	  SELECT 
		DFnivel AS id
		  , ';' + ISNULL(CAST(DFenderecos_ocupados AS VARCHAR), '')       AS ';Enderecos Ocupados'
		  , ';' + ISNULL(CAST(DFenderecos_desocupados AS VARCHAR), '')    AS ';Enderecos Desocupados'
		  , ';' + ISNULL(CAST(Dfenderecos_vazios AS VARCHAR), '')         AS ';Enderecos Vazios'
		  , ';' + ISNULL(CAST(DFenderecos_bloqueados AS VARCHAR), '')     AS ';Enderecos Bloqueados'
		  , ';' + ISNULL(CAST(Dftotal_enderecos AS VARCHAR), '')          AS ';Total Enderecos'
	   FROM #temp_resultados
	END
	ELSE
	BEGIN
		; WITH XMLNAMESPACES('http://james.newtonking.com/projects/json' AS [json])
		SELECT 'statusSinteticoEnderecos' AS Titulo
		     , (
			     SELECT 'true' AS [@json:Array]
					 , DFnivel                     AS nivel
					 , DFenderecos_ocupados        AS enderecosOcupados
					 , DFenderecos_desocupados     AS enderecosDesocupados
					 , Dfenderecos_vazios          AS enderecosVazios
					 , DFenderecos_bloqueados      AS enderecosBloqueados
					 , Dftotal_enderecos           AS totalEnderecos
				 FROM #temp_resultados
			      WHERE Linha BETWEEN @indice_de AND @indice_ate
			        FOR XML PATH('Linha'), ROOT('Linhas'), TYPE
		       )
		     , @quantidade_parcial AS QuantidadeParcial
		     , @quantidade_total AS QuantidadeTotal
		   FOR XML PATH('Relatorio'), TYPE
    END

	IF @stealth = 0
		SELECT * FROM #temp_resultados
	
	EXEC sp_IO_Log_WMS @descricao = 'fim', @acao=1, @procedure='sp_listar_Status_Sintetico_Enderecos', @xml=@XML

END
GO

/*
BEGIN TRAN
  DECLARE @xml XML =
'
<Parametros>
  <pagina>1</pagina>
  <limite>10</limite>
  <ordenacao>,</ordenacao>
  <id_usuario>1</id_usuario>
  <stealth>0</stealth>
  <exportar>csv</exportar>
</Parametros>
'

/*
select DFcod_pedido_compra, tbunidade_item_estoque.DFcod_item_estoque, dfserie, DFcod_fornecedor_emitente, dfnumero, * from TBnota_fiscal_entrada
inner join tbitem_nota_fiscal_entrada
on tbitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada = TBnota_fiscal_entrada.DFid_nota_fiscal_entrada
inner join TBunidade_item_estoque
on TBunidade_item_estoque.DFid_unidade_item_estoque = TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque
where DFdata_emissao between '2025-01-01' and '2025-02-28' and DFcod_fornecedor_emitente is not null
and DFnumero = 12636
*/
  EXEC sp_listar_Status_Sintetico_Enderecos @xml
           
  --SELECT top 10 * FROM TBlog_integracao_xml_logistica where DFrotina = 'sp_listar_Status_Sintetico_Enderecos' order by 1 desc
  --EXEC sp_IO_Log_WMS @acao=2, @procedure='sp_listar_Status_Sintetico_Enderecos'
  /*
     SELECT top 10 
		    TBlog_integracao_xml_logistica.*
		  , ref.value('(TempoExe)[1]', 'int')
	   FROM TBlog_integracao_xml_logistica 
cross apply DFxml.nodes('./.') XML( ref ) 
	  where DFrotina = 'sp_listar_Status_Sintetico_Enderecos'  
		and isnull(ref.value('(TempoExe)[1]', 'int'), 0) > 1
   order by 1 desc
   */

  rollback

-- Criei as tags XML com as datas, pedido, nf, serie, item e criei as tabelas temporárias respectivas  
-- Estou jogando tudo na tempdados e depois excluindo os dados nas datas que não tem no meu XML (entre) ???

*/
