select CAST(DFrua AS NVARCHAR(3)) + '-' + CAST(DFpredio AS NVARCHAR(3)) + '-' + CAST(DFnivel AS NVARCHAR(3)) + '-' + CAST(DFapto AS NVARCHAR(3)), *
from TBendereco_armazenagem

-- dimensao -> enderecos
-- fato -> 
