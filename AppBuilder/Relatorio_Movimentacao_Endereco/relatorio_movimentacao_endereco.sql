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

	Objetivo: criar relatório de movimentação de endereços na web.
	TomTicket: https://console.tomticket.com/dashboard/ticket/history/1da35dcb4db615a2c03c7598733051f0
	GitLab: http://gitlab.processa.info/engenharia/director/-/issues/1242
*/

SELECT * FROM sysobjects WHERE NAME LIKE 'sp_listar_Movimentacao_de_Endereco'

IF OBJECT_ID('sp_listar_Movimentacao_de_Endereco') IS NOT NULL
  DROP PROCEDURE sp_listar_Movimentacao_de_Endereco
GO

CREATE PROCEDURE sp_listar_Movimentacao_de_Endereco (@xml XML)
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
		
	/***************************************************************
	* Variveis usadas para filtrar a lista - Declarando as variáveis
	***************************************************************/

	DECLARE @periodo                NVARCHAR(MAX),
	        @endereco               NVARCHAR(MAX),
	        @lado                   NVARCHAR(MAX),
			@condicaoEstocagem      NVARCHAR(MAX),
			@quantidadeEstocagem    NVARCHAR(MAX),
			@observacoes            NVARCHAR(MAX),
			@usuario                NVARCHAR(MAX),
			@motivo                 NVARCHAR(MAX),
			@codigoItem             INT,
			@origem                 NVARCHAR(MAX),
			@tipoMovimento          NVARCHAR(MAX),
			@tipoEstoque            NVARCHAR(MAX),
			@centroDistribuicao     INT,
			@lote                   INT

	EXEC sp_IO_Log_WMS 'Inicio rotina sp_listar_Movimentacao_de_Endereco : '
	
	/****************************************************
	* Carrega as variáveis de filtro - Desserializando XML
	*****************************************************/

	SELECT 	@periodo                = DFxml.value('*[lower-case(local-name())="periodo"][1]','NVARCHAR(MAX)'),
	        @endereco               = DFxml.value('*[lower-case(local-name())="endereco"][1]','NVARCHAR(MAX)'),
	        @lado                   = DFxml.value('*[lower-case(local-name())="lado"][1]','NVARCHAR(MAX)'),
			@condicaoEstocagem      = DFxml.value('*[lower-case(local-name())="condicaoestocagem"][1]','NVARCHAR(MAX)'),
			@quantidadeEstocagem    = DFxml.value('*[lower-case(local-name())="quantidadeestocagem"][1]','NVARCHAR(MAX)'),
			@observacoes            = DFxml.value('*[lower-case(local-name())="observacoes"][1]','NVARCHAR(MAX)'),
			@usuario                = DFxml.value('*[lower-case(local-name())="usuario"][1]','NVARCHAR(MAX)'),
			@motivo                 = DFxml.value('*[lower-case(local-name())="motivo"][1]','NVARCHAR(MAX)'),
			@codigoItem             = DFxml.value('*[lower-case(local-name())="codigoitem"][1]','INT'),
			@origem                 = DFxml.value('*[lower-case(local-name())="origem"][1]','NVARCHAR(MAX)'),
			@tipoMovimento          = DFxml.value('*[lower-case(local-name())="tipomovimento"][1]','NVARCHAR(MAX)'),
			@tipoEstoque            = DFxml.value('*[lower-case(local-name())="tipoestoque"][1]','NVARCHAR(MAX)'),
			@centroDistribuicao     = DFxml.value('*[lower-case(local-name())="centrodistribuicao"][1]','INT'),
			@lote                   = DFxml.value('*[lower-case(local-name())="lote"][1]','INT')
	FROM @xml.nodes('./*') AS XMLparametros(DFxml)

	--SET @periodo = '2025-12-16 00:00, 2025-12-16 23:59'
	--SET @endereco = '23-8-0-8'
 --   SET @codigoItem = 299611

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

	/**********************************************************************************************
	* FILTRO DE DATA - @periodo
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#TBperiodo') IS NOT NULL 
		DROP TABLE #TBperiodo
	
	CREATE TABLE #TBperiodo (
		DtIni SMALLDATETIME,
		DtFim SMALLDATETIME
	)

	IF(ISNULL(@periodo, '') = '')
		BEGIN
			INSERT INTO #TBperiodo
			SELECT CAST(CONVERT(VARCHAR(10), DATEADD(DAY, -1 , GETDATE()), 23) + ' 00:00:00' AS SMALLDATETIME) AS DtIni
		         , CAST(CONVERT(VARCHAR(10), DATEADD(DAY, 1 , GETDATE()), 23) + ' 23:59:00' AS SMALLDATETIME) AS DtFim
		END
	ELSE
		BEGIN
			INSERT INTO #TBperiodo
			SELECT TOP 1 CAST(itens AS SMALLDATETIME) AS DtIni
				       , CAST(NULL AS SMALLDATETIME) AS DtFim
			  FROM dbo.Split(@periodo, ',')
			 ORDER BY CAST(itens AS SMALLDATETIME) ASC
	
			UPDATE #TBperiodo
			  SET DtFim = (SELECT TOP 1 CAST(itens AS SMALLDATETIME) 
							 FROM dbo.Split(@periodo, ',')
							ORDER BY CAST(itens AS SMALLDATETIME) DESC)
		END

	/**********************************************************************************************
	* FILTRO DE ENDEREÇO - @endereco
	**********************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#enderecos') IS NOT NULL 
		DROP TABLE #enderecos

	CREATE TABLE #enderecos(
		id_endereco INT)

	EXEC sp_filtro_Endereco_app_builder @endereco, @tabela_retorno = '#enderecos';

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

		  SET @ordenacao_coluna = CASE WHEN @coluna = ',' OR @coluna IS NULL OR @coluna = '' THEN 'DFcod_item_estoque' ELSE @coluna END
          SET @ordenacao_direcao = ISNULL(@direcao, 'asc')

	EXEC sp_IO_Log_WMS  'Fim processo de tratamento paginacao / ordenação'

    /*******************************
    * INÍCIO DO PROCESSO - SQL BASE
    ********************************/

IF OBJECT_ID('tempdb..#temp_dados') IS NOT NULL
	DROP TABLE #temp_dados

SELECT
	dbo.MONTAR_ENDERECO(TBio_endereco.DFid_endereco_armazenagem)    AS endereco,
	TBmovto_endereco.DFdata_validade,
	TBmovto_endereco.DFcod_item_estoque,
	TBitem_estoque.DFdescricao,
	TBusuario.DFnome_usuario,
	CAST(TBmovto_endereco.DFqtde_tot_estoque AS DECIMAL(18,4))      AS DFqtde_tot_estoque,           -- quantidade_anterior
	CASE WHEN TBio_endereco.DFtipo = 'S' THEN (TBmovto_endereco.DFqtde * (-1)) END AS quantidade_movimentada, -- quantidade_movimentada
	CASE WHEN TBio_endereco.DFtipo = 'E' THEN (TBmovto_endereco.DFqtde_tot_estoque + TBmovto_endereco.DFqtde)
	                                     ELSE (TBmovto_endereco.DFqtde_tot_estoque - TBmovto_endereco.DFqtde) END AS quantidade_atual,             -- quantidade_atualTBunidade.DFdescricao                                           AS unidade,
	TBunidade.DFdescricao                                           AS unidade,
	TBorigem_movto_endereco.DFdescricao_resumida,
	TBmovto_endereco.DFdata_conferida,
	TBmovto_endereco.DFdata_hora_movto_endereco,
	TBmovto_endereco.DFobs
INTO #temp_dados
FROM 
	TBmovto_endereco WITH(NOLOCK)
	JOIN TBusuario WITH(NOLOCK) ON TBmovto_endereco.DFid_usuario = TBusuario.DFid_usuario
	JOIN TBunidade_item_estoque WITH(NOLOCK) ON TBmovto_endereco.DFid_unidade_item_estoque = TBunidade_item_estoque.DFid_unidade_item_estoque
	JOIN TBitem_estoque WITH(NOLOCK) ON TBunidade_item_estoque.DFcod_item_estoque = TBitem_estoque.DFcod_item_estoque
	JOIN TBunidade WITH(NOLOCK) ON TBunidade.DFcod_unidade = TBunidade_item_estoque.DFcod_unidade
	JOIN TBorigem_movto_endereco WITH(NOLOCK) ON TBorigem_movto_endereco.DFid_origem_movto_endereco = TBmovto_endereco.DFid_origem_movto_endereco
	JOIN TBio_endereco WITH(NOLOCK) ON TBmovto_endereco.DFid_movto_endereco = TBio_endereco.DFid_movto_endereco
	JOIN TBendereco_armazenagem WITH(NOLOCK) ON TBio_endereco.DFid_endereco_armazenagem = TBendereco_armazenagem.DFid_endereco_armazenagem
	JOIN TBitem_endereco_armazenagem_lote WITH(NOLOCK) ON TBendereco_armazenagem.DFid_endereco_armazenagem = TBitem_endereco_armazenagem_lote.DFid_item_endereco_armazenagem
	JOIN #enderecos WITH(NOLOCK) ON TBendereco_armazenagem.DFid_endereco_armazenagem = #enderecos.id_endereco
WHERE
     ISNULL(@endereco, '') = '' OR TBendereco_armazenagem.DFid_endereco_armazenagem IN (SELECT id_endereco FROM #enderecos)    -- Endereço armazenagem
	AND (ISNULL(@lado, '') = ''                                                                                                      -- Lado
		 OR (@lado = 'Par'   AND TBendereco_armazenagem.DFpredio % 2 = 0)												     
		 OR (@lado = 'Ímpar' AND TBendereco_armazenagem.DFpredio % 2 <> 0))												     
	AND (ISNULL(@condicaoEstocagem, '') = '' OR TBendereco_armazenagem.DFcondicao = @condicaoEstocagem)                          -- condicaoEstocagem
	AND (ISNULL(@quantidadeEstocagem, '') = ''                                                                                   -- quantidadeEstocagem
		OR (@quantidadeEstocagem = 'Existente' AND (TBmovto_endereco.DFqtde_tot_estoque + TBmovto_endereco.DFqtde) > 0)          
		OR (@quantidadeEstocagem = 'Vazio' AND (TBmovto_endereco.DFqtde_tot_estoque + TBmovto_endereco.DFqtde) = 0))             
	AND (ISNULL(@observacoes, '') = '' OR TBmovto_endereco.DFobs = @observacoes)                                                 -- Observações
	AND (ISNULL(@usuario, '') = '' OR TBusuario.DFnome_usuario = @usuario)                                                       -- Usuário
	AND (ISNULL(@motivo, '') = '' OR TBorigem_movto_endereco.DFdescricao_resumida = @motivo)                                     -- Motivo
	AND (ISNULL(@codigoItem, '') = '' OR TBmovto_endereco.DFcod_item_estoque = @codigoItem)                                      -- Item
	AND (ISNULL(@origem, '') = '' OR TBorigem_movto_endereco.DForigem = @origem)                                                 -- Origem
	AND (ISNULL(@tipoMovimento, '') = '' OR TBmovto_endereco.DFtipo = @tipoMovimento)                                            -- Tipo de movimento
	AND (ISNULL(@tipoEstoque, '') = '' OR TBendereco_armazenagem.DFid_tipo_estoque = @tipoEstoque)                               -- Tipo de estoque
	AND (ISNULL(@centroDistribuicao, '') = '' OR TBendereco_armazenagem.DFcod_empresa = @centroDistribuicao)                     -- Centro de distribuição
    AND (ISNULL(@lote, '') = '' OR TBitem_endereco_armazenagem_lote.DFlote = @lote)                                              -- Lote
ORDER BY DFdata_hora_movto_endereco

IF EXISTS (SELECT * FROM #TBperiodo)
BEGIN
	DELETE D
	FROM #temp_dados D
	JOIN #tbperiodo P 
		ON D.DFdata_hora_movto_endereco NOT BETWEEN P.DtIni AND P.DtFim
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

	SELECT @quantidade_total = COUNT(DISTINCT DFcod_item_estoque) FROM #temp_resultados WITH(NOLOCK)
	SELECT @quantidade_parcial = COUNT(DISTINCT DFcod_item_estoque) FROM #temp_resultados WITH(NOLOCK)
			
	IF @exportar = 'csv'
	BEGIN
	  SELECT DFcod_item_estoque as id
	       , ';' + ISNULL(CAST(endereco AS VARCHAR), '')                                                     AS ';endereco'
		   , ';' + ISNULL(FORMAT(CAST(DFdata_validade AS DATE), 'dd/MM/yyyy'), '')                        AS ';validade'
		   , ';' + ISNULL(DFdescricao, '')                                                                   AS ';descricao'
		   , ';' + ISNULL(DFnome_usuario, '')                                                                AS ';usuario'
		   , ';' + ISNULL(FORMAT(DFqtde_tot_estoque, 'N', 'pt-br'), '')                                      AS ';quantidade_anterior'
		   , ';' + ISNULL(FORMAT(quantidade_movimentada, 'N', 'pt-br'), '')                                                  AS ';quantidade_movimentada'
		   , ';' + ISNULL(FORMAT(quantidade_atual, 'N', 'pt-br'), '')                                        AS ';quantidade_atual'
		   , ';' + ISNULL(unidade, '')                                                                       AS ';unidade'
		   , ';' + ISNULL(CAST(DFdescricao_resumida AS VARCHAR), '')                                         AS ';motivo'
		   , ';' + ISNULL(CAST(DFdata_conferida AS VARCHAR), '')              AS ';data_conferida'
		   , ';' + ISNULL(CAST(DFdata_hora_movto_endereco AS VARCHAR), '')    AS ';data_movimentacao'
		   , ';' + ISNULL(DFobs, '')                                                                         AS ';observacao'
	   FROM #temp_resultados
	END
	ELSE
	BEGIN
		; WITH XMLNAMESPACES('http://james.newtonking.com/projects/json' AS [json])
		SELECT 'MovimentacaoDeEnderecos' AS Titulo
		     , (
			     SELECT 'true' AS [@json:Array]
					 , endereco                                                     AS endereco
					 , FORMAT(DFdata_validade, 'dd/MM/yyyy')                        AS validade
					 , DFcod_item_estoque								            AS codigo_item_estoque
		             , DFdescricao                                                  AS descricao
		             , DFnome_usuario                                               AS usuario
		             , FORMAT(DFqtde_tot_estoque, 'N', 'pt-br')                     AS quantidade_anterior
		             , FORMAT(quantidade_movimentada, 'N', 'pt-br')                                 AS quantidade_movimentada
		             , FORMAT(quantidade_atual, 'N', 'pt-br')                       AS quantidade_atual
		             , unidade                                                      AS unidade
		             , DFdescricao_resumida                                         AS motivo
		             , FORMAT(DFdata_conferida, 'dd/MM/yyyy HH:mm:ss')              AS data_conferida
		             , FORMAT(DFdata_hora_movto_endereco, 'dd/MM/yyyy HH:mm:ss')    AS data_movimentacao
		             , DFobs                                                        AS observacao
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
	
	EXEC sp_IO_Log_WMS @descricao = 'fim', @acao=1, @procedure='sp_listar_Movimentacao_de_Endereco', @xml=@XML

END
GO

/*
BEGIN TRAN
  DECLARE @xml XML =
'
<Parametros>
  <periodo>2025-12-16 00:00, 2025-12-16 23:59</periodo>
  <endereco>23-8-0-8</endereco>
  <lado></lado>
  <condicaoEstocagem></condicaoEstocagem>
  <quantidadeEstocagem></quantidadeEstocagem>
  <observacoes></observacoes>
  <usuario></usuario>
  <motivo></motivo>
  <codigoItem>299611</codigoItem>
  <origem></origem>
  <tipoMovimento></tipoMovimento>
  <tipoEstoque></tipoEstoque>
  <centroDistribuicao></centroDistribuicao>
  <lote></lote>
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
  EXEC sp_listar_Movimentacao_de_Endereco @xml
           
  --SELECT top 10 * FROM TBlog_integracao_xml_logistica where DFrotina = 'sp_listar_Movimentacao_de_Endereco' order by 1 desc
  --EXEC sp_IO_Log_WMS @acao=2, @procedure='sp_listar_Movimentacao_de_Endereco'
  /*
     SELECT top 10 
		    TBlog_integracao_xml_logistica.*
		  , ref.value('(TempoExe)[1]', 'int')
	   FROM TBlog_integracao_xml_logistica 
cross apply DFxml.nodes('./.') XML( ref ) 
	  where DFrotina = 'sp_listar_Movimentacao_de_Endereco'  
		and isnull(ref.value('(TempoExe)[1]', 'int'), 0) > 1
   order by 1 desc
   */

  rollback

-- Criei as tags XML com as datas, pedido, nf, serie, item e criei as tabelas temporárias respectivas  
-- Estou jogando tudo na tempdados e depois excluindo os dados nas datas que não tem no meu XML (entre) ???

*/
