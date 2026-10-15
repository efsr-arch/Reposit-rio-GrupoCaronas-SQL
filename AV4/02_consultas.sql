-- Q01 [SQL 06 SELECT/FROM/WHERE, 07 BETWEEN, 21 ORDER BY]:
-- Objetivo/interpretacao: Viagens na faixa de R$ 8 a R$ 20; menor preco primeiro.
SELECT v.cpf_motorista, t.origem, t.destino, v.data_hora_partida,
       v.preco_vaga, v.vagas_disponiveis, v.status
  FROM Viagem v
  JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
 WHERE v.preco_vaga BETWEEN 8 AND 20
 ORDER BY v.preco_vaga ASC, v.data_hora_partida DESC;

-- Q02 [SQL 08 IN, 09 LIKE, 11 INNER JOIN]:
-- Objetivo/interpretacao: Motoristas de Recife/Olinda com iniciais C, M ou R e seus veiculos.
SELECT u.nome AS motorista, m.cnh_categoria, ve.placa, mo.marca, mo.modelo
  FROM Usuario u
  INNER JOIN Motorista m ON m.cpf = u.cpf
  INNER JOIN Veiculo ve ON ve.cpf_proprietario = m.cpf
  INNER JOIN Modelo mo ON mo.modelo = ve.modelo_carro
 WHERE u.cidade IN ('Recife', 'Olinda')
   AND (u.nome LIKE 'C%' OR u.nome LIKE 'M%' OR u.nome LIKE 'R%')
 ORDER BY u.nome, ve.placa;

-- Q03 [SQL 10 IS NULL, 16 LEFT OUTER JOIN]:
-- Objetivo/interpretacao: Passageiros que ainda nao avaliaram Carlos; nao implica que viajaram com ele.
SELECT u.cpf, u.nome
  FROM Passageiro p
  JOIN Usuario u ON u.cpf = p.cpf
  LEFT OUTER JOIN Avalia a ON a.cpf_passageiro = p.cpf
                          AND a.cpf_motorista_viagem = '12345678901'
 WHERE a.cpf_passageiro IS NULL
 ORDER BY u.nome;

-- Q04 [SQL 12 MAX, 13 MIN, 14 AVG, 15 COUNT, 22 GROUP BY, 23 HAVING]:
-- Objetivo/interpretacao: Comparacao de precos por origem com pelo menos duas viagens.
SELECT t.origem, COUNT(*) AS total_viagens,
       MIN(v.preco_vaga) AS menor_preco,
       MAX(v.preco_vaga) AS maior_preco,
       ROUND(AVG(v.preco_vaga), 2) AS preco_medio
  FROM Viagem v
  JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
 GROUP BY t.origem
HAVING COUNT(*) >= 2
 ORDER BY preco_medio DESC;

-- Q05 [SQL 17 SUBCONSULTA COM OPERADOR RELACIONAL]:
-- Objetivo/interpretacao: Viagens acima do preco medio global; identifica ofertas mais caras.
SELECT v.cpf_motorista, v.id_trajeto, v.data_hora_partida, v.preco_vaga
  FROM Viagem v
 WHERE v.preco_vaga > (SELECT AVG(preco_vaga) FROM Viagem)
 ORDER BY v.preco_vaga DESC;

-- Q06 [SQL 18 SUBCONSULTA COM IN]:
-- Objetivo/interpretacao: Usuarios com pelo menos uma reserva confirmada ou concluida.
SELECT u.cpf, u.nome
  FROM Usuario u
 WHERE u.cpf IN (
       SELECT r.cpf_passageiro FROM Reserva r
        WHERE r.status IN ('CONFIRMADA', 'CONCLUIDA'))
 ORDER BY u.nome;

-- Q07 [SQL 19 SUBCONSULTA COM ANY]:
-- Objetivo/interpretacao: Precos superiores a pelo menos um preco de Boa Viagem. Base original: 3 linhas.
SELECT t.origem, t.destino, v.preco_vaga, v.data_hora_partida
  FROM Viagem v
  JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
 WHERE v.preco_vaga > ANY (
       SELECT v2.preco_vaga FROM Viagem v2
       JOIN Trajeto t2 ON t2.id_trajeto = v2.id_trajeto
       WHERE t2.origem = 'Boa Viagem')
 ORDER BY v.preco_vaga DESC;

-- Q08 [SQL 20 SUBCONSULTA COM ALL]:
-- Objetivo/interpretacao: Precos iguais ou superiores a todos os de Boa Viagem. Base original: 1 linha. Se a referencia estiver vazia, ALL aceita todas as linhas.
SELECT t.origem, t.destino, v.preco_vaga, v.data_hora_partida
  FROM Viagem v
  JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
 WHERE v.preco_vaga >= ALL (
       SELECT v2.preco_vaga FROM Viagem v2
       JOIN Trajeto t2 ON t2.id_trajeto = v2.id_trajeto
       WHERE t2.origem = 'Boa Viagem')
 ORDER BY v.preco_vaga DESC;

-- Q09 [SQL 24 UNION]: usuarios com participacao efetiva em viagens concluidas.
-- Motoristas que ofereceram viagens + passageiros com reservas concluidas.
-- UNION elimina repeticoes, inclusive de quem participou nos dois papeis.
SELECT u.cpf, u.nome, u.email
  FROM Usuario u JOIN Viagem v ON v.cpf_motorista = u.cpf
 WHERE v.status = 'CONCLUIDA'
UNION
SELECT u.cpf, u.nome, u.email
  FROM Usuario u JOIN Reserva r ON r.cpf_passageiro = u.cpf
 WHERE r.status = 'CONCLUIDA'
ORDER BY nome, cpf;

-- Q10 [SQL 11, 14, 15, 16, 22]: reputacao dos motoristas,
-- Objetivo/interpretacao: Reputacao por motorista, incluindo quem nao tem avaliacoes.
SELECT m.cpf, u.nome, COUNT(a.nota) AS total_avaliacoes,
       ROUND(AVG(a.nota), 2) AS nota_media
  FROM Motorista m
  JOIN Usuario u ON u.cpf = m.cpf
  LEFT JOIN Avalia a ON a.cpf_motorista_viagem = m.cpf
 GROUP BY m.cpf, u.nome
 ORDER BY nota_media DESC NULLS LAST, total_avaliacoes DESC;

-- Q11 [SQL 11, 15, 22]: demanda por motorista (reservas confirmadas ou concluidas).
-- Objetivo/interpretacao: Volume de reservas e valor associado; valor reservado nao significa pagamento recebido.
SELECT u.nome AS motorista, COUNT(r.codigo_reserva) AS total_reservas,
       NVL(SUM(r.qtd_vagas * v.preco_vaga), 0) AS valor_reservado
  FROM Motorista m
  JOIN Usuario u ON u.cpf = m.cpf
  JOIN Viagem v ON v.cpf_motorista = m.cpf
  LEFT JOIN Reserva r ON r.cpf_motorista_viagem = v.cpf_motorista
                     AND r.id_trajeto = v.id_trajeto
                     AND r.data_hora_partida = v.data_hora_partida
                     AND r.status IN ('CONFIRMADA', 'CONCLUIDA')
 GROUP BY m.cpf, u.nome
 ORDER BY valor_reservado DESC;

-- Q12 [SQL 10 IS NOT NULL]: avaliacoes que contam com comentario.
-- Objetivo/interpretacao: Avaliacoes com texto, para analise qualitativa alem da nota.
SELECT cpf_passageiro, cpf_motorista_viagem, nota, comentario
  FROM Avalia
 WHERE comentario IS NOT NULL
 ORDER BY data_avaliacao DESC;

-- Q13 [SQL 25 CREATE VIEW]: consolidacao de ocupacao sem duplicar
-- Objetivo/interpretacao: Ocupacao por viagem; SOLICITADA e CANCELADA nao consomem vagas.
CREATE OR REPLACE VIEW vw_ocupacao_viagem AS
SELECT v.cpf_motorista, u.nome AS motorista, v.id_trajeto,
       t.origem, t.destino, v.data_hora_partida, v.status,
       ve.capacidade_passageiros, v.vagas_disponiveis,
       NVL(SUM(CASE WHEN r.status IN ('CONFIRMADA', 'CONCLUIDA')
                    THEN r.qtd_vagas ELSE 0 END), 0) AS vagas_reservadas,
       ROUND(100 * NVL(SUM(CASE WHEN r.status IN ('CONFIRMADA', 'CONCLUIDA')
                     THEN r.qtd_vagas ELSE 0 END), 0)
             / ve.capacidade_passageiros, 1) AS ocupacao_percentual
  FROM Viagem v
  JOIN Usuario u ON u.cpf = v.cpf_motorista
  JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
  JOIN Veiculo ve ON ve.placa = v.placa
  LEFT JOIN Reserva r ON r.cpf_motorista_viagem = v.cpf_motorista
                     AND r.id_trajeto = v.id_trajeto
                     AND r.data_hora_partida = v.data_hora_partida
 GROUP BY v.cpf_motorista, u.nome, v.id_trajeto, t.origem, t.destino,
          v.data_hora_partida, v.status, ve.capacidade_passageiros,
          v.vagas_disponiveis;

-- Q14 - uso da view: ocupacao e conferencia do saldo de vagas.
-- Objetivo/interpretacao: Painel de ocupacao para conferir capacidade e saldo de vagas.
SELECT motorista, origem, destino, data_hora_partida, status,
       capacidade_passageiros, vagas_reservadas,
       vagas_disponiveis, ocupacao_percentual
  FROM vw_ocupacao_viagem
 ORDER BY data_hora_partida, motorista;

-- [SQL 26 GRANT / REVOKE] Nao executar no Oracle Live SQL.
-- GRANT concede privilegios sobre objetos; REVOKE retira privilegios concedidos.
-- Exemplo: autorizar uma conta de consulta a ler o painel e depois retirar acesso.
-- Exemplos conceituais: manter comentados, conforme orientacao da AV4.
-- GRANT SELECT ON vw_ocupacao_viagem TO usuario_consulta;
-- REVOKE SELECT ON vw_ocupacao_viagem FROM usuario_consulta;
