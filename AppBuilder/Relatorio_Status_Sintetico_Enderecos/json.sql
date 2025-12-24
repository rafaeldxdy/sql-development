
DECLARE @chave_pagina_antiga NVARCHAR(MAX) = ''
      , @caminho_novo NVARCHAR(MAX) = ''

DECLARE @model            NVARCHAR(MAX) = '{ "functionKey":"wms.relatorios_status-sintetico-enderecos","genericPageTitle":"Status Sintetico Enderecos","filtro":{"model":[[{"rowIndex":0,"label":"Nível","name":"nivel","ctype":"input","replicateId":""},{"rowIndex":0,"name":"enderecosOcupados","label":"Endereços Ocupados","ctype":"input","replicateId":""},{"rowIndex":0,"name":"enderecosDesocupados","label":"Endereços Desocupados","ctype":"input","replicateId":""},{"rowIndex":0,"label":"Endereços Vazios","name":"enderecosVazios","ctype":"input","replicateId":""},{"rowIndex":0,"name":"enderecosBloqueados","label":"Endereços Bloqueados","ctype":"input","replicateId":""},{"rowIndex":0,"name":"totalEnderecos","label":"Total Endereços","ctype":"input","replicateId":""}]]},"datagrid":{"api":"/proc/sp_listar_Status_Sintetico_Enderecos","title":"Status Sintetico Enderecos","headers":[{"label":"Nivel","prop":"nivel","sortable":false,"align":"left"},{"label":"Enderecos Ocupados","prop":"enderecosOcupados","sortable":false,"align":"left"},{"label":"Enderecos Desocupados","prop":"enderecosDesocupados","sortable":false,"align":"left"},{"label":"Enderecos Vazios","prop":"enderecosVazios","sortable":false,"align":"left"},{"label":"Enderecos Bloqueados","prop":"enderecosBloqueados","sortable":false,"align":"left"},{"label":"Total Enderecos","prop":"totalEnderecos","sortable":false,"align":"left"}],"limits":[50,100]}}'
      , @resposta         NVARCHAR(MAX) = ''
      , @chave_aplicacao  NVARCHAR(255) = 'wms'
      , @chave_modulo     NVARCHAR(255) = 'wms.relatorios'
      , @chave_pagina     NVARCHAR(255) = 'wms.relatorios_status-sintetico-enderecos'
      , @cliente          NVARCHAR(14)  = ''
      , @status           NVARCHAR(10)  = 'H'
      , @id_aplicacao     INT
      , @id_pagina        INT      

IF EXISTS (SELECT * FROM sys.schemas WITH(NOLOCK) WHERE name = 'acesso')
BEGIN
  BEGIN TRY
    BEGIN TRAN
    --Validacao de existencia da aplicacao
    IF NOT EXISTS ( SELECT * FROM acesso.TBaplicacao WITH(NOLOCK) WHERE DFchave = @chave_aplicacao)
    BEGIN
      DECLARE @tabela_aplicacao 
        TABLE (
        DFnome      NVARCHAR(255),
        DFdescricao NVARCHAR(255),
        DFicone     NVARCHAR(255),
        DFendereco  NVARCHAR(255),
        DFchave     NVARCHAR(255)
      )
      INSERT INTO @tabela_aplicacao (DFnome,DFdescricao,DFicone,DFendereco,DFchave)
      VALUES ('WMS','Warehouse Managment System','cilStorage','http://127.0.0.1:4300',@chave_aplicacao)

      INSERT INTO acesso.TBaplicacao (DFnome,DFdescricao,DFicone,DFendereco,DFchave)
      SELECT t1.DFnome,t1.DFdescricao,t1.DFicone,t1.DFendereco,t1.DFchave 
        FROM @tabela_aplicacao t1
    END
    
    --Validacao de existencia do modulo
    DECLARE @tabela_modulo
      TABLE (
      DFtitulo        NVARCHAR(255),
      DFdescricao     NVARCHAR(255),
      DFcaminho       NVARCHAR(255),
      DFicone         NVARCHAR(255),
      DFchave         NVARCHAR(255),
      DFid_aplicacao  INT
    )
    
    INSERT INTO @tabela_modulo (DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_aplicacao)
    VALUES (
        'Relatorios',
        '',
        '/relatorios',
        'cilTransfer',
        @chave_modulo,
        (select DFid_aplicacao from acesso.TBaplicacao WITH(NOLOCK) WHERE DFchave = @chave_aplicacao)
    )

    INSERT INTO acesso.TBmodulo (DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_aplicacao)
    SELECT DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_aplicacao
      FROM @tabela_modulo 
     WHERE DFchave NOT IN ( SELECT DFchave FROM acesso.TBmodulo WITH(NOLOCK) )

    --Validacao de existencia da pagina
    DECLARE @tabela_pagina TABLE (
      DFtitulo        NVARCHAR(255),
      DFdescricao     NVARCHAR(255),
      DFcaminho       NVARCHAR(255),
      DFicone         NVARCHAR(255),
      DFchave         NVARCHAR(255),
      DFid_modulo     INT,
      DFid_aplicacao  INT,
      DFpalavra_chave NVARCHAR(255)
    )
    INSERT INTO @tabela_pagina (DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_modulo,DFid_aplicacao,DFpalavra_chave)
     VALUES (
       'Status Sintetico Enderecos',
       'Relatório de status sintético de endereços',
       '/relatorios/status_sintetico_enderecos',
       'cil-transfer',
       @chave_pagina,
       (select DFid_modulo from acesso.TBmodulo WITH(NOLOCK) WHERE DFchave = @chave_modulo),
       (select DFid_aplicacao from acesso.TBaplicacao WITH(NOLOCK) WHERE DFchave = @chave_aplicacao),
       'relatorio, enderecos, sintetico' 
    )

    -- Atualização de informações quando a aplicação ou módulo de uma página é alterado 
    IF @caminho_novo <> ''
    BEGIN
      IF EXISTS(SELECT * FROM acesso.TBpagina WHERE DFchave = @chave_pagina_antiga )
      BEGIN
        UPDATE acesso.TBpagina 
           SET DFtitulo         = t1.DFtitulo       
             , DFdescricao      = t1.DFdescricao    
             , DFcaminho        = t1.DFcaminho      
             , DFicone          = t1.DFicone        
             , DFchave          = t1.DFchave        
             , DFpalavra_chave  = t1.DFpalavra_chave
             , DFid_aplicacao   = t1.DFid_aplicacao
             , DFid_modulo      = t1.DFid_modulo
          FROM @tabela_pagina t1
         WHERE acesso.TBpagina.DFchave = @chave_pagina_antiga
      END
      ELSE
      BEGIN
        INSERT INTO acesso.TBpagina (DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_modulo,DFid_aplicacao)
        SELECT DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_modulo,DFid_aplicacao 
          FROM @tabela_pagina
      END
    END
    ELSE
    BEGIN
      INSERT INTO acesso.TBpagina (DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_modulo,DFid_aplicacao)
      SELECT DFtitulo,DFdescricao,DFcaminho,DFicone,DFchave,DFid_modulo,DFid_aplicacao 
        FROM @tabela_pagina
       WHERE DFchave NOT IN (SELECT DFchave FROM acesso.TBpagina WITH(NOLOCK) )
      
      UPDATE acesso.TBpagina
         SET DFtitulo         = t1.DFtitulo       
           , DFdescricao      = t1.DFdescricao    
           , DFcaminho        = t1.DFcaminho      
           , DFicone          = t1.DFicone        
           , DFchave          = t1.DFchave        
           , DFpalavra_chave  = t1.DFpalavra_chave
        FROM @tabela_pagina t1
       INNER JOIN acesso.TBpagina t2 
          ON t1.DFchave = t2.DFchave
    END

    --Funcoes
    

    -- Criação de tabela temporaria para realizar validações
    DECLARE @tabela_model_pagina TABLE (
      DFvalor         NVARCHAR(MAX),
      DFchave_pagina  NVARCHAR(255),
      DFcnpj_cliente  NVARCHAR(14),
      DFstatus        NVARCHAR(10)
    )
    INSERT INTO @tabela_model_pagina (DFvalor,DFchave_pagina,DFcnpj_cliente,DFstatus)
    VALUES (@model,@chave_pagina,@cliente,@status)
    
    -- Atualização de informações quando a aplicação ou módulo de uma página é alterado
    IF @caminho_novo <> ''
    BEGIN
     IF EXISTS (SELECT * FROM acesso.TBmodel_pagina WHERE DFchave_pagina = @chave_pagina_antiga )
     BEGIN
       UPDATE acesso.TBmodel_pagina
          SET DFvalor = @model
            , DFstatus = @status
            , DFdata_modificacao = GETDATE()
            , DFchave_pagina = @chave_pagina
         FROM @tabela_model_pagina t1
        WHERE acesso.TBmodel_pagina.DFchave_pagina = @chave_pagina_antiga
     END
     ELSE
     BEGIN
       INSERT INTO acesso.TBmodel_pagina (DFvalor,DFchave_pagina,DFcnpj_cliente,DFstatus )
       SELECT DFvalor,DFchave_pagina,DFcnpj_cliente,DFstatus 
         FROM @tabela_model_pagina t1 
     END
    END
    ELSE
    BEGIN
      -- Insercao caso não exista 
      INSERT INTO acesso.TBmodel_pagina (DFvalor,DFchave_pagina,DFcnpj_cliente,DFstatus )
      SELECT DFvalor,DFchave_pagina,DFcnpj_cliente,DFstatus 
        FROM @tabela_model_pagina t1
       WHERE t1.DFchave_pagina 
         NOT IN ( SELECT DFchave_pagina
                    FROM acesso.TBmodel_pagina WITH(NOLOCK)
                   WHERE ( @cliente IS NULL 
                         OR @cliente = '' 
                         OR @cliente = DFcnpj_cliente ) )
 
      -- Atualizacao caso exista
      UPDATE acesso.TBmodel_pagina
         SET DFvalor = @model,
             DFstatus = @status,
             DFdata_modificacao = GETDATE()
        FROM @tabela_model_pagina t1
       INNER JOIN acesso.TBmodel_pagina t2
          ON t1.DFchave_pagina = t2.DFchave_pagina
       WHERE ( ( ( @cliente IS NULL OR @cliente = '') AND (t2.DFcnpj_cliente IS NULL OR t2.DFcnpj_cliente = '') ) 
             OR ( ( @cliente IS NOT NULL AND @cliente <> '') AND t2.DFcnpj_cliente = @cliente ) )
    END

    --Queries da pagina
     

    --Procedures

    SET @resposta ='{"status":200,"sucesso":true,"dados":"A operação foi realizada com sucesso."}'
    COMMIT TRAN
  END TRY
  BEGIN CATCH
    DECLARE @PROCEDURE NVARCHAR(max)    
    SET @PROCEDURE = ERROR_PROCEDURE()    
    IF @PROCEDURE IS NOT NULL    
      SET @PROCEDURE = 'OCORREU UM ERRO NA ' + @PROCEDURE + ','    
    ELSE    
      SET @PROCEDURE = 'OCORREU UM ERRO,'    
  
    DECLARE @MENSAGEM_ERRO NVARCHAR(MAX) =
    'Falha na criação da página,' 
    + @PROCEDURE 
    +' ERRO NUMERO: ' + CAST(ERROR_NUMBER () AS NVARCHAR(20))
    + ERROR_MESSAGE()    
    + 'ERRO NA LINHA: ' + CAST(ERROR_LINE() AS NVARCHAR(10))
  
    SET @resposta ='{"status":500,"sucesso":false,"dados":' + ERROR_MESSAGE() + @MENSAGEM_ERRO + '}'
    ROLLBACK TRAN  
  END CATCH
END
ELSE
BEGIN
  SET @resposta ='{"status":200,"sucesso":false,"dados":"O schema de tabelas do portal director não existe no banco de dados."}'
END
SELECT @resposta 