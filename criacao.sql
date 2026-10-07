CREATE SEQUENCE seq_trajeto START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_reserva START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE Usuario (
    cpf VARCHAR2(11) NOT NULL,
    nome VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) NOT NULL,
    data_cadastro DATE NOT NULL,
    tipo_usuario VARCHAR2(10) NOT NULL,
    cep VARCHAR2(8) NOT NULL,
    rua VARCHAR2(100) NOT NULL,
    bairro VARCHAR2(60) NOT NULL,
    cidade VARCHAR2(60) NOT NULL,
    numero VARCHAR2(10) NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (cpf),
    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_cpf CHECK (LENGTH(cpf) = 11),
    CONSTRAINT ck_usuario_email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT ck_usuario_tipo CHECK (tipo_usuario IN ('MOTORISTA', 'PASSAGEIRO', 'AMBOS')),
    CONSTRAINT ck_usuario_cep CHECK (LENGTH(cep) = 8)
);

CREATE TABLE Telefone_Usuario (
    cpf VARCHAR2(11) NOT NULL,
    telefone  VARCHAR2(11) NOT NULL,
    CONSTRAINT pk_telefone_usuario PRIMARY KEY (cpf, telefone),
    CONSTRAINT fk_telefone_usuario FOREIGN KEY (cpf) REFERENCES Usuario (cpf),
    CONSTRAINT ck_telefone_formato CHECK (LENGTH(telefone) BETWEEN 10 AND 11)
);

CREATE TABLE Usuario_indica (
    cpf_indicador VARCHAR2(11) NOT NULL,
    cpf_indicado VARCHAR2(11) NOT NULL,
    data_indicacao DATE NOT NULL,
    CONSTRAINT pk_usuario_indica PRIMARY KEY (cpf_indicador, cpf_indicado),
    CONSTRAINT fk_indica_indicador FOREIGN KEY (cpf_indicador) REFERENCES Usuario (cpf),
    CONSTRAINT fk_indica_indicado FOREIGN KEY (cpf_indicado) REFERENCES Usuario (cpf),
    CONSTRAINT ck_indica_diferentes CHECK (cpf_indicador <> cpf_indicado)
);

CREATE TABLE Motorista (
    cpf VARCHAR2(11) NOT NULL,
    cnh_numero VARCHAR2(11) NOT NULL,
    cnh_categoria VARCHAR2(2) NOT NULL,
    cnh_validade DATE NOT NULL,
    CONSTRAINT pk_motorista PRIMARY KEY (cpf),
    CONSTRAINT fk_motorista_usuario FOREIGN KEY (cpf) REFERENCES Usuario (cpf),
    CONSTRAINT uq_motorista_cnh UNIQUE (cnh_numero),
    CONSTRAINT ck_motorista_cnh_num CHECK (LENGTH(cnh_numero) = 11),
    CONSTRAINT ck_motorista_cnh_cat CHECK (cnh_categoria IN ('A', 'B', 'C', 'D', 'E', 'AB', 'AC', 'AD', 'AE'))
);

CREATE TABLE Passageiro (
    cpf  VARCHAR2(11) NOT NULL,
    CONSTRAINT pk_passageiro PRIMARY KEY (cpf),
    CONSTRAINT fk_passageiro_usuario FOREIGN KEY (cpf) REFERENCES Usuario (cpf)
);

CREATE TABLE Preferencias (
    cpf_passageiro VARCHAR2(11) NOT NULL,
    preferencia VARCHAR2(60) NOT NULL,
    CONSTRAINT pk_preferencias PRIMARY KEY (cpf_passageiro, preferencia),
    CONSTRAINT fk_preferencias_passageiro FOREIGN KEY (cpf_passageiro) REFERENCES Passageiro (cpf)
);

CREATE TABLE Dependente (
    cpf VARCHAR2(11) NOT NULL,
    n_dependente NUMBER(2) NOT NULL,
    nome VARCHAR2(100) NOT NULL,
    data_nascimento DATE NOT NULL,
    relacao_usuario VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_dependente PRIMARY KEY (cpf, n_dependente),
    CONSTRAINT fk_dependente_passageiro FOREIGN KEY (cpf) REFERENCES Passageiro (cpf),
    CONSTRAINT ck_dependente_numero CHECK (n_dependente > 0)
);

CREATE TABLE Modelo (
    modelo  VARCHAR2(50) NOT NULL,
    marca   VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_modelo PRIMARY KEY (modelo)
);

CREATE TABLE Veiculo (
    placa VARCHAR2(7) NOT NULL,
    cpf_proprietario VARCHAR2(11) NOT NULL,
    modelo_carro VARCHAR2(50) NOT NULL,
    cor VARCHAR2(30) NOT NULL,
    ano NUMBER(4) NOT NULL,
    capacidade_passageiros NUMBER(2) NOT NULL,
    CONSTRAINT pk_veiculo PRIMARY KEY (placa),
    CONSTRAINT fk_veiculo_proprietario FOREIGN KEY (cpf_proprietario) REFERENCES Motorista (cpf),
    CONSTRAINT fk_veiculo_modelo FOREIGN KEY (modelo_carro) REFERENCES Modelo (modelo),
    CONSTRAINT ck_veiculo_placa CHECK (LENGTH(placa) = 7),
    CONSTRAINT ck_veiculo_ano CHECK (ano BETWEEN 1990 AND 2100),
    CONSTRAINT ck_veiculo_capacidade CHECK (capacidade_passageiros BETWEEN 1 AND 15)
);

CREATE TABLE Trajeto (
    id_trajeto NUMBER(10) NOT NULL,
    origem VARCHAR2(100) NOT NULL,
    destino VARCHAR2(100) NOT NULL,
    distancia NUMBER(6,2) NOT NULL,   -- km
    tempo_estimado  NUMBER(4) NOT NULL,   -- minutos
    CONSTRAINT pk_trajeto PRIMARY KEY (id_trajeto),
    CONSTRAINT ck_trajeto_distancia CHECK (distancia > 0),
    CONSTRAINT ck_trajeto_tempo CHECK (tempo_estimado > 0)
);

CREATE TABLE Parada (
    id_trajeto NUMBER(10) NOT NULL,
    ordem NUMBER(2) NOT NULL,
    horario_estimado VARCHAR2(5) NOT NULL,   -- formato HH24:MI
    logradouro VARCHAR2(100) NOT NULL,
    numero VARCHAR2(10) NOT NULL,
    bairro VARCHAR2(60) NOT NULL,
    CONSTRAINT pk_parada PRIMARY KEY (id_trajeto, ordem),
    CONSTRAINT fk_parada_trajeto FOREIGN KEY (id_trajeto) REFERENCES Trajeto (id_trajeto),
    CONSTRAINT ck_parada_ordem CHECK (ordem > 0),
    CONSTRAINT ck_parada_horario CHECK (horario_estimado LIKE '__:__')
);

CREATE TABLE Viagem (
    cpf_motorista VARCHAR2(11) NOT NULL,
    id_trajeto NUMBER(10) NOT NULL,
    data_hora_partida DATE NOT NULL,
    preco_vaga NUMBER(8,2) NOT NULL,
    vagas_disponiveis NUMBER(2) NOT NULL,
    status VARCHAR2(15) NOT NULL,
    placa VARCHAR2(7) NOT NULL,
    CONSTRAINT pk_viagem PRIMARY KEY (cpf_motorista, id_trajeto, data_hora_partida),
    CONSTRAINT fk_viagem_motorista FOREIGN KEY (cpf_motorista) REFERENCES Motorista (cpf),
    CONSTRAINT fk_viagem_trajeto FOREIGN KEY (id_trajeto) REFERENCES Trajeto (id_trajeto),
    CONSTRAINT fk_viagem_veiculo FOREIGN KEY (placa) REFERENCES Veiculo (placa),
    CONSTRAINT ck_viagem_preco CHECK (preco_vaga >= 0),
    CONSTRAINT ck_viagem_vagas CHECK (vagas_disponiveis >= 0),
    CONSTRAINT ck_viagem_status CHECK (status IN ('AGENDADA', 'EM_ANDAMENTO', 'CONCLUIDA', 'CANCELADA'))
);

CREATE TABLE Avalia (
    cpf_passageiro VARCHAR2(11) NOT NULL,
    cpf_motorista_viagem VARCHAR2(11) NOT NULL,
    id_trajeto NUMBER(10) NOT NULL,
    data_hora_partida DATE NOT NULL,
    nota NUMBER(1) NOT NULL,
    comentario VARCHAR2(300),
    data_avaliacao DATE NOT NULL,
    CONSTRAINT pk_avalia PRIMARY KEY (cpf_passageiro, cpf_motorista_viagem, id_trajeto, data_hora_partida),
    CONSTRAINT fk_avalia_passageiro FOREIGN KEY (cpf_passageiro) REFERENCES Passageiro (cpf),
    CONSTRAINT fk_avalia_viagem FOREIGN KEY (cpf_motorista_viagem, id_trajeto, data_hora_partida)
        REFERENCES Viagem (cpf_motorista, id_trajeto, data_hora_partida),
    CONSTRAINT ck_avalia_nota CHECK (nota BETWEEN 1 AND 5)
);

CREATE TABLE Embarca_desembarca (
    cpf_motorista_viagem VARCHAR2(11) NOT NULL,
    id_trajeto NUMBER(10) NOT NULL,
    data_hora_partida DATE NOT NULL,
    ordem NUMBER(2) NOT NULL,
    cpf_passageiro VARCHAR2(11) NOT NULL,
    tipo VARCHAR2(12) NOT NULL,
    horario_real DATE NOT NULL,
    CONSTRAINT pk_embarca_desembarca PRIMARY KEY
        (cpf_motorista_viagem, id_trajeto, data_hora_partida, ordem, cpf_passageiro),
    CONSTRAINT fk_ed_viagem FOREIGN KEY (cpf_motorista_viagem, id_trajeto, data_hora_partida)
        REFERENCES Viagem (cpf_motorista, id_trajeto, data_hora_partida),
    CONSTRAINT fk_ed_parada FOREIGN KEY (id_trajeto, ordem) REFERENCES Parada (id_trajeto, ordem),
    CONSTRAINT fk_ed_passageiro FOREIGN KEY (cpf_passageiro) REFERENCES Passageiro (cpf),
    CONSTRAINT ck_ed_tipo CHECK (tipo IN ('EMBARQUE', 'DESEMBARQUE'))
);

CREATE TABLE Reserva (
    codigo_reserva NUMBER(10) NOT NULL,
    cpf_motorista_viagem VARCHAR2(11) NOT NULL,
    id_trajeto NUMBER(10) NOT NULL,
    data_hora_partida DATE NOT NULL,
    cpf_passageiro VARCHAR2(11) NOT NULL,
    data_solicitacao DATE NOT NULL,
    qtd_vagas NUMBER(2) NOT NULL,
    status VARCHAR2(15) NOT NULL,
    CONSTRAINT pk_reserva PRIMARY KEY (codigo_reserva),
    CONSTRAINT fk_reserva_viagem FOREIGN KEY (cpf_motorista_viagem, id_trajeto, data_hora_partida)
        REFERENCES Viagem (cpf_motorista, id_trajeto, data_hora_partida),
    CONSTRAINT fk_reserva_passageiro FOREIGN KEY (cpf_passageiro) REFERENCES Passageiro (cpf),
    CONSTRAINT ck_reserva_qtd CHECK (qtd_vagas > 0),
    CONSTRAINT ck_reserva_status CHECK (status IN ('SOLICITADA', 'CONFIRMADA', 'CANCELADA', 'CONCLUIDA'))
);