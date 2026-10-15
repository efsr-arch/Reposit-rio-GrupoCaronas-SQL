-- Pre-requisito: criacao.sql e povoamento.sql do repositório original.
-- EXECUTAR UMA UNICA VEZ: ALTER TABLE / CREATE INDEX sao DDL persistentes.

-- [SQL 01] ALTER TABLE: regra util para a data da solicitacao.
ALTER TABLE Reserva ADD CONSTRAINT ck_reserva_solic_antes_partida
  CHECK (data_solicitacao <= data_hora_partida);

-- [SQL 02] CREATE INDEX: acelera filtros por status e data da viagem.
CREATE INDEX idx_viagem_status_partida ON Viagem(status, data_hora_partida);
CREATE INDEX idx_reserva_status_solic ON Reserva(status, data_solicitacao);

-- Uma reserva ativa por passageiro/viagem, inclusive com INSERT direto.
CREATE UNIQUE INDEX uq_reserva_ativa ON Reserva (
  CASE WHEN status IN ('SOLICITADA','CONFIRMADA') THEN cpf_motorista_viagem END,
  CASE WHEN status IN ('SOLICITADA','CONFIRMADA') THEN id_trajeto END,
  CASE WHEN status IN ('SOLICITADA','CONFIRMADA') THEN data_hora_partida END,
  CASE WHEN status IN ('SOLICITADA','CONFIRMADA') THEN cpf_passageiro END
);

-- [SQL 03, 04, 05] INSERT / UPDATE / DELETE coerentes em Preferencias.
INSERT INTO Preferencias (cpf_passageiro, preferencia)
VALUES ('34567890123', 'Prefere ar-condicionado');

UPDATE Preferencias
   SET preferencia = 'Ar-condicionado ligado'
 WHERE cpf_passageiro = '34567890123'
   AND preferencia = 'Prefere ar-condicionado';

DELETE FROM Preferencias
 WHERE cpf_passageiro = '34567890123'
   AND preferencia = 'Ar-condicionado ligado';

COMMIT;
