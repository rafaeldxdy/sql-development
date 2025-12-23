SELECT * FROM sysobjects where name like 'sp_listar_Divergencia_Conferencia_Cega'

/*  
	Nomeclaturas usadas
	sp_Detalhar_NomeDaPagina
	sp_Listar_NomeDaPagina
	sp_Editar_
	sp_Excluir_
	sp_Persistir_
*/

IF OBJECT_ID('sp_listar_Divergencia_Conferencia_Cega') IS NOT NULL
  DROP PROCEDURE sp_listar_Divergencia_Conferencia_Cega
GO

/*
	AUTOR......: Rafael Ribeiro
	AREA.......: Logistica
	MODULO.....: Wms
	DATA/HORA..: 
	
	Função.....: 
*/

CREATE PROCEDURE sp_listar_Divergencia_Conferencia_Cega (@xml XML)
AS
  SET ARITHABORT ON
BEGIN

	/****************************************************
	* Variveis para armazenar os valores lidos de @xml
	****************************************************/

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
		
	/****************************************************
	* Variveis usadas para filtrar a lista
	****************************************************/

	DECLARE @empresaEmitente INT
		  , @empresaDestinataria INT
		  , @pedido NVARCHAR(MAX)
		  , @numeroNF NVARCHAR(MAX)
		  , @serieNF NVARCHAR(MAX)
		  , @item NVARCHAR(MAX)
		  , @dataLancamento NVARCHAR(MAX)
		  , @dataEmissao NVARCHAR(MAX)
		  , @dataUltimaAlteracao NVARCHAR(MAX)
		  , @dataEntrada NVARCHAR(MAX)

	EXEC sp_IO_Log_WMS 'Inicio rotina sp_listar_Divergencia_Conferencia_Cega : '
	
	/****************************************************
	* Carrega as variáveis de filtro 
	****************************************************/

	SELECT @dataEmissao             = DFxml.value('*[lower-case(local-name())="dataemissao"][1]','NVARCHAR(MAX)')
		 , @dataLancamento          = DFxml.value('*[lower-case(local-name())="datalancamento"][1]','NVARCHAR(MAX)')
		 , @dataEntrada             = DFxml.value('*[lower-case(local-name())="dataentrada"][1]','NVARCHAR(MAX)')
		 , @dataUltimaAlteracao     = DFxml.value('*[lower-case(local-name())="dataultimaalteracao"][1]','NVARCHAR(MAX)')
		 , @empresaEmitente         = DFxml.value('*[lower-case(local-name())="empresaemitente"][1]','INT')
	     , @empresaDestinataria     = DFxml.value('*[lower-case(local-name())="empresadestinataria"][1]','INT')
		 , @pedido                  = DFxml.value('*[lower-case(local-name())="pedido"][1]','NVARCHAR(MAX)')
		 , @numeroNF                = DFxml.value('*[lower-case(local-name())="numeronf"][1]','NVARCHAR(MAX)')
		 , @serieNF                 = DFxml.value('*[lower-case(local-name())="serienf"][1]','NVARCHAR(MAX)')
		 , @item                    = DFxml.value('*[lower-case(local-name())="item"][1]','NVARCHAR(MAX)')
	FROM @xml.nodes('./*') AS XMLparametros(DFxml)

	/****************************************************
	* Carrega as variáveis fixas
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
	* Filtro Empresa usuario
	****************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBempresaFiltroUsuario') IS NOT NULL 
		DROP TABLE #TBempresaFiltroUsuario

	SELECT TBempresa.DFcod_empresa
	     , DFid_centro_distribuicao
	  INTO #TBempresaFiltroUsuario
	  FROM TBempresa WITH(NOLOCK) 
INNER JOIN TBcentro_distribuicao  WITH(NOLOCK) 
	    ON TBempresa.DFcod_empresa = TBcentro_distribuicao.DFcod_empresa
	 WHERE TBempresa.DFcod_empresa in (SELECT itens
										  FROM acesso.TBaplicacao WITH(NOLOCK)
									INNER JOIN acesso.TBpapel WITH(NOLOCK) 
											ON TBaplicacao.DFid_aplicacao = TBpapel.DFid_aplicacao
									INNER JOIN acesso.TBpapel_usuario_empresa WITH(NOLOCK) 
											ON TBpapel.DFid_papel = TBpapel_usuario_empresa.DFid_papel
									 cross APPLY dbo.fn_Split (DFcod_empresas, ',')
										 where DFid_usuario = @UsuarioId
										   and TBaplicacao.DFchave = 'wms')

	/**********************************************************************************************
	* FILTRO DE SELECTS
	**********************************************************************************************/
	-- SELECT @empresa = isnull(@empresa + ',','') + DFxml.value('(.)[1]','NVARCHAR(100)')
	  -- FROM @empresaXML.nodes('/*') AS XMLparametros(DFxml)
	  
	/**********************************************************************************************
	* FILTRO DE EMPRESA
	**********************************************************************************************/
 /*   IF OBJECT_ID('tempdb.dbo.#TBempresa') IS NOT NULL DROP TABLE #TBempresa
	
	CREATE TABLE #TBempresa(DFcod int)
	
	IF(ISNULL(@empresa, '') != '')
	BEGIN
	  INSERT INTO #TBempresa
	  EXEC sp_filtro_app_builder 'TBempresa', 'dfcod_empresa', 'dfcod_empresa', @empresa

	  INSERT INTO #TBempresa
	  EXEC sp_filtro_app_builder 'TBempresa', 'dfcod_empresa', 'dfnome_fantasia', @empresa
	END

	*/
	/**********************************************************************************************
	* FILTRO DE DATA - LANÇAMENTO
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBdata_lancamento') IS NOT NULL 
		DROP TABLE #TBdata_lancamento
	
	CREATE TABLE #TBdata_lancamento (
		DtIni SMALLDATETIME,
		DtFim SMALLDATETIME
	)

	IF(ISNULL(@dataLancamento, '') = '')
		BEGIN
			INSERT INTO #TBdata_lancamento
			SELECT CAST(CONVERT(VARCHAR(10), DATEADD(DAY, -1 , GETDATE()), 23) + ' 00:00:00' AS SMALLDATETIME) AS DtIni
		         , CAST(CONVERT(VARCHAR(10), DATEADD(DAY, 1 , GETDATE()), 23) + ' 23:59:00' AS SMALLDATETIME) AS DtFim
		END
	ELSE
		BEGIN
			INSERT INTO #TBdata_lancamento
			SELECT TOP 1 CAST(itens AS SMALLDATETIME) AS DtIni
				 , CAST(NULL AS SMALLDATETIME) AS DtFim
			  FROM dbo.Split(@dataLancamento, ',')
			 ORDER BY CAST(itens AS SMALLDATETIME) ASC
	
			UPDATE #TBdata_lancamento
			  SET DtFim = (SELECT TOP 1 CAST(itens AS SMALLDATETIME) 
							 FROM dbo.Split(@dataLancamento, ',')
							ORDER BY CAST(itens AS SMALLDATETIME) DESC)
		END

	/**********************************************************************************************
	* FILTRO DE DATA - EMISSAO
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBdata_emissao') IS NOT NULL 
		DROP TABLE #TBdata_emissao
	
	CREATE TABLE #TBdata_emissao (
		DtIni SMALLDATETIME,
		DtFim SMALLDATETIME
	)

	
	IF ISNULL(@dataEmissao, '') <> ''
	BEGIN
		INSERT INTO #TBdata_emissao
		SELECT TOP 1 CAST(itens AS SMALLDATETIME) AS DtIni
				, CAST(NULL AS SMALLDATETIME) AS DtFim
			FROM dbo.Split(@dataEmissao, ',')
			ORDER BY CAST(itens AS SMALLDATETIME) ASC
	
		UPDATE #TBdata_emissao
			SET DtFim = (SELECT TOP 1 CAST(itens AS SMALLDATETIME) 
							FROM dbo.Split(@dataEmissao, ',')
						ORDER BY CAST(itens AS SMALLDATETIME) DESC)
	END

	/**********************************************************************************************
	* FILTRO DE DATA - ÚLTIMA ALTERAÇÂO
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBdata_ultima_alteracao') IS NOT NULL 
		DROP TABLE #TBdata_ultima_alteracao
	
	CREATE TABLE #TBdata_ultima_alteracao (
		DtIni SMALLDATETIME,
		DtFim SMALLDATETIME
	)

	IF ISNULL(@dataUltimaAlteracao, '') <> ''
	BEGIN
		INSERT INTO #TBdata_ultima_alteracao
		SELECT TOP 1 CAST(itens AS SMALLDATETIME) AS DtIni
				, CAST(NULL AS SMALLDATETIME) AS DtFim
			FROM dbo.Split(@dataUltimaAlteracao, ',')
			ORDER BY CAST(itens AS SMALLDATETIME) ASC
	
		UPDATE #TBdata_ultima_alteracao
			SET DtFim = (SELECT TOP 1 CAST(itens AS SMALLDATETIME) 
							FROM dbo.Split(@dataUltimaAlteracao, ',')
						ORDER BY CAST(itens AS SMALLDATETIME) DESC)
	END
		
	/**********************************************************************************************
	* FILTRO DE DATA - ENTRADA
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBdata_entrada') IS NOT NULL DROP TABLE #TBdata_entrada
	
	CREATE TABLE #TBdata_entrada (
		DtIni SMALLDATETIME,
		DtFim SMALLDATETIME
	)

	
	IF ISNULL(@dataEntrada, '') <> ''
		BEGIN 
			INSERT INTO #TBdata_entrada
			SELECT TOP 1 CAST(itens AS SMALLDATETIME) AS DtIni
				 , CAST(NULL AS SMALLDATETIME) AS DtFim
			  FROM dbo.Split(@dataEntrada, ',')
			 ORDER BY CAST(itens AS SMALLDATETIME) ASC
	
			UPDATE #TBdata_entrada
			  SET DtFim = (SELECT TOP 1 CAST(itens AS SMALLDATETIME) 
							 FROM dbo.Split(@dataEntrada, ',')
							ORDER BY CAST(itens AS SMALLDATETIME) DESC)
		END

	EXEC sp_IO_Log_WMS  'Fim processo de filtros'

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

		  SET @ordenacao_coluna = CASE WHEN @coluna = ',' OR @coluna IS NULL OR @coluna = '' THEN 'DFcod_entidade' ELSE @coluna END
        --SET @ordenacao_coluna = CASE WHEN @coluna = ',' OR @coluna IS NULL OR @coluna = '' THEN 'dfcod_pedido_venda' ELSE @coluna END
        SET @ordenacao_direcao = ISNULL(@direcao, 'asc')

	EXEC sp_IO_Log_WMS  'Fim processo de tratamento paginacao/ ordenação'

    /***************************************************
    * INÍCIO DO PROCESSO
    ***************************************************/

IF OBJECT_ID('tempdb..#temp_dados') is not null drop table #temp_dados

SELECT ISNULL(TBnota_fiscal_entrada.DFcod_empresa_emitente, TBnota_fiscal_entrada.DFcod_fornecedor_emitente) AS DFcod_entidade
     , TBnota_fiscal_entrada.DFnumero AS DFnumero 
     , TBunidade_item_estoque.DFcod_item_estoque AS DFcod_item_estoque 
     , TBitem_estoque.DFdescricao AS DFdescricao 
     , dbo.und(TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque) AS DFunidade 
     , TBitem_conferencia.DFid_unidade_item_estoque AS DFid_unidade_item_estoque 
     , dbo.c_und(TBitem_conferencia.DFqtde_conferido , TBitem_conferencia.DFid_unidade_item_estoque , TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque) AS DFQtde_Conferida 
     , TBitem_nota_fiscal_entrada.DFqtde AS DFQtde_NF 
     , dbo.c_und(TBitem_conferencia.DFqtde_conferido , TBitem_conferencia.DFid_unidade_item_estoque , TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque) - TBitem_nota_fiscal_entrada.DFqtde AS DFQtde_divergencia 
     , dbo.c_und(TBitem_conferencia.DFqtde_definitivo , TBitem_conferencia.DFid_unidade_item_estoque , TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque) AS DFQtde_Definitivo
	 , tbnota_fiscal_entrada.dfdata_lancamento AS DFdata_lancamento
	 , TBnota_fiscal_entrada.DFdata_emissao AS DFdata_emissao
	 , tbnota_fiscal_entrada.DFdata_ultima_alteracao AS DFdata_ultima_alteracao
	 , TBnota_fiscal_entrada.DFdata_entrada AS DFdata_entrada
  INTO #temp_dados
  FROM TBitem_conferencia WITH (NOLOCK)
 INNER JOIN TBitem_nota_fiscal_entrada WITH (NOLOCK)
    ON TBitem_conferencia.DFid_item_nota_fiscal_entrada = TBitem_nota_fiscal_entrada.DFid_item_nota_fiscal_entrada 
 INNER JOIN TBnota_fiscal_entrada WITH (NOLOCK)
    ON TBitem_nota_fiscal_entrada.DFid_nota_fiscal_entrada = TBnota_fiscal_entrada.DFid_nota_fiscal_entrada 
 INNER JOIN TBunidade_item_estoque WITH (NOLOCK)
    ON TBitem_nota_fiscal_entrada.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque 
 INNER JOIN TBitem_estoque WITH (NOLOCK)
    ON TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
INNER JOIN #TBdata_lancamento WITH(NOLOCK)
    ON TBnota_fiscal_entrada.DFdata_lancamento BETWEEN #TBdata_lancamento.DtIni AND #TBdata_lancamento.DtFim
WHERE (ISNULL(@empresaDestinataria, '') = '' OR TBnota_fiscal_entrada.DFcod_empresa_destinatario = @empresaDestinataria)
  AND (ISNULL(@empresaEmitente, '') = '' OR COALESCE(TBnota_fiscal_entrada.DFcod_empresa_emitente, TBnota_fiscal_entrada.DFcod_fornecedor_emitente, TBnota_fiscal_entrada.DFcod_cliente_emitente) = @empresaEmitente)
  AND (ISNULL(@numeroNF, '') = '' OR TBnota_fiscal_entrada.DFnumero = @numeroNF)
  AND (ISNULL(@serieNF, '') = '' OR TBnota_fiscal_entrada.DFserie = @serieNF)
ORDER BY TBnota_fiscal_entrada.DFnumero, TBunidade_item_estoque.DFcod_item_estoque

	IF EXISTS (SELECT * FROM #TBdata_entrada)
	BEGIN
		DELETE TD
		FROM #temp_dados TD
		INNER JOIN #TBdata_entrada DE
			ON TD.DFdata_entrada < DE.DtIni 
			OR TD.DFdata_entrada > DE.DtFim
	END

	IF EXISTS (SELECT * FROM #TBdata_emissao)
	BEGIN
		DELETE TD
		FROM #temp_dados TD
		INNER JOIN #TBdata_emissao DEM
			ON TD.DFdata_entrada < DEM.DtIni 
			OR TD.DFdata_entrada > DEM.DtFim
	END

	IF EXISTS (SELECT * FROM #TBdata_ultima_alteracao)
	BEGIN
		DELETE TD
		FROM #temp_dados TD
		INNER JOIN #TBdata_ultima_alteracao DUA
			ON TD.DFdata_entrada < DUA.DtIni 
			OR TD.DFdata_entrada > DUA.DtFim
	END
	
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
	
	SELECT @quantidade_total = COUNT(DISTINCT DFnumero) FROM #temp_resultados WITH(NOLOCK)
	SELECT @quantidade_parcial = COUNT(DISTINCT DFnumero) FROM #temp_resultados WITH(NOLOCK)
	
	IF @exportar = 'csv'
	BEGIN
	  SELECT DFnumero as id
		   , ';' + ISNULL(CAST(DFcod_entidade AS VARCHAR), '')               AS ';cod_entidade'
		   , ';' + ISNULL(CAST(DFcod_item_estoque AS NVARCHAR), '')          AS ';codigo_item'
		   , ';' + ISNULL(DFdescricao, '')                                   AS ';descricao'
		   , ';' + ISNULL(DFunidade, '')                                     AS ';unidade'
		   , ';' + ISNULL(CAST(DFid_unidade_item_estoque AS NVARCHAR), '')   AS ';unidade_item_estoque'
		   , ';' + ISNULL(FORMAT(DFQtde_Conferida, 'N', 'pt-br'), '')        AS ';quantidade_conferida'
		   , ';' + ISNULL(FORMAT(DFQtde_NF, 'N', 'pt-br'), '')               AS ';quantidade_nota_fiscal'
		   , ';' + ISNULL(FORMAT(DFQtde_divergencia, 'N', 'pt-br'), '')      AS ';quantidade_divergente '
		   , ';' + ISNULL(FORMAT(DFQtde_Definitivo, 'N', 'pt-br'), '')       AS ';quantidade_definitiva'
	   FROM #temp_resultados
	END
	ELSE
	BEGIN
		; WITH XMLNAMESPACES('http://james.newtonking.com/projects/json' AS [json])
		SELECT 'JuncaoPalete' AS Titulo
		     , (
			     SELECT 'true' AS [@json:Array]
					 , DFcod_entidade                           AS codigo_entidade
					 , DFnumero                                 AS numero
					 , DFcod_item_estoque                       AS codigo_item
					 , DFdescricao                              AS descricao
					 , DFunidade                                AS unidade
					 , DFid_unidade_item_estoque                AS unidade_item_estoque
					 , FORMAT(DFQtde_Conferida, 'N', 'pt-br')   AS quantidade_conferida
					 , FORMAT(DFQtde_NF, 'N', 'pt-br')          AS quantidade_nota_fiscal
					 , FORMAT(DFQtde_divergencia, 'N', 'pt-br') AS quantidade_divergente 
					 , FORMAT(DFQtde_Definitivo, 'N', 'pt-br')  AS quantidade_definitiva
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
	
	EXEC sp_IO_Log_WMS @descricao = 'fim', @acao=1, @procedure='sp_listar_Divergencia_Conferencia_Cega', @xml=@XML

END
GO

/*
BEGIN TRAN
  DECLARE @xml XML =
' 
<Parametros>
  <dataLancamento>2025-06-01 00:00, 2025-07-31 23:59</dataLancamento>
  <dataEmissao>2025-06-01 00:00, 2025-07-31 23:59</dataEmissao>
  <dataUltimaAlteracao>2025-06-01 00:00, 2025-07-31 23:59</dataUltimaAlteracao>
  <dataEntrada>2025-06-01 00:00, 2025-07-31 23:59</dataEntrada>
  <empresaEmitente>11237</empresaEmitente>
  <empresaDestinataria>45</empresaDestinataria>
  <pedido>4034118</pedido>
  <numeroNF>5</numeroNF>
  <serieNF>1</serieNF>
  <item>139572</item>
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
  EXEC sp_listar_Divergencia_Conferencia_Cega @xml
           
  --SELECT top 10 * FROM TBlog_integracao_xml_logistica where DFrotina = 'sp_listar_Divergencia_Conferencia_Cega' order by 1 desc
  --EXEC sp_IO_Log_WMS @acao=2, @procedure='sp_listar_Divergencia_Conferencia_Cega'
  /*
     SELECT top 10 
		    TBlog_integracao_xml_logistica.*
		  , ref.value('(TempoExe)[1]', 'int')
	   FROM TBlog_integracao_xml_logistica 
cross apply DFxml.nodes('./.') XML( ref ) 
	  where DFrotina = 'sp_listar_Divergencia_Conferencia_Cega'  
		and isnull(ref.value('(TempoExe)[1]', 'int'), 0) > 1
   order by 1 desc
   */

  rollback


-- Criei as tags XML com as datas, pedido, nf, serie, item e criei as tabelas temporárias respectivas  
-- Estou jogando tudo na tempdados e depois excluindo os dados nas datas que não tem no meu XML (entre) ???

*/
