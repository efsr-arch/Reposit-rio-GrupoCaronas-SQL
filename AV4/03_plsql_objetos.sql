-- Executar APOS 01_alteracoes_e_dml.sql; a ordem interna e importante.
-- Na interface Oracle Live SQL, executar como SCRIPT (terminadores /).

-- [PL 05 CREATE FUNCTION, 06 %TYPE, 13 SELECT INTO, 15 EXCEPTION WHEN]
CREATE OR REPLACE FUNCTION fn_valor_reserva (
    p_codigo IN Reserva.codigo_reserva%TYPE
) RETURN NUMBER
IS
    v_valor NUMBER(12,2);
BEGIN
    SELECT r.qtd_vagas * v.preco_vaga
      INTO v_valor
      FROM Reserva r
      JOIN Viagem v ON v.cpf_motorista = r.cpf_motorista_viagem
                   AND v.id_trajeto = r.id_trajeto
                   AND v.data_hora_partida = r.data_hora_partida
     WHERE r.codigo_reserva = p_codigo;
    RETURN v_valor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Reserva inexistente: ' || p_codigo);
END fn_valor_reserva;
/

-- [PL 04 PROCEDURE, 07 %ROWTYPE, 10 LOOP EXIT WHEN, 14 CURSOR, 16 IN/OUT]
CREATE OR REPLACE PROCEDURE pr_listar_viagens_motorista (
    p_cpf IN Motorista.cpf%TYPE,
    p_total OUT NUMBER
)
IS
    CURSOR c_viagens IS
        SELECT v.id_trajeto, t.origem, t.destino,
               v.data_hora_partida, v.status, v.vagas_disponiveis
          FROM Viagem v
          JOIN Trajeto t ON t.id_trajeto = v.id_trajeto
         WHERE v.cpf_motorista = p_cpf
         ORDER BY v.data_hora_partida;
    v_viagem c_viagens%ROWTYPE;
BEGIN
    p_total := 0;
    OPEN c_viagens;
    LOOP
        FETCH c_viagens INTO v_viagem;
        EXIT WHEN c_viagens%NOTFOUND;
        p_total := p_total + 1;
        DBMS_OUTPUT.PUT_LINE('Trajeto ' || v_viagem.id_trajeto || ': ' ||
            v_viagem.origem || ' -> ' || v_viagem.destino ||
            ' | ' || TO_CHAR(v_viagem.data_hora_partida, 'DD/MM/YYYY HH24:MI') ||
            ' | ' || v_viagem.status ||
            ' | vagas: ' || v_viagem.vagas_disponiveis);
    END LOOP;
    CLOSE c_viagens;
EXCEPTION
    WHEN OTHERS THEN
        IF c_viagens%ISOPEN THEN
            CLOSE c_viagens;
        END IF;
        RAISE;
END pr_listar_viagens_motorista;
/

-- [PL 17 CREATE OR REPLACE PACKAGE, 16 parametros IN / OUT]
CREATE OR REPLACE PACKAGE pkg_reservas AS
    FUNCTION fn_vagas_disponiveis (
        p_motorista IN Viagem.cpf_motorista%TYPE,
        p_trajeto IN Viagem.id_trajeto%TYPE,
        p_partida IN Viagem.data_hora_partida%TYPE
    ) RETURN NUMBER;

    PROCEDURE pr_solicitar (
        p_motorista IN Viagem.cpf_motorista%TYPE,
        p_trajeto IN Viagem.id_trajeto%TYPE,
        p_partida IN Viagem.data_hora_partida%TYPE,
        p_passageiro IN Passageiro.cpf%TYPE,
        p_quantidade IN Reserva.qtd_vagas%TYPE,
        p_codigo OUT Reserva.codigo_reserva%TYPE
    );

    PROCEDURE pr_confirmar (
        p_codigo IN Reserva.codigo_reserva%TYPE,
        p_mensagem OUT VARCHAR2
    );

    PROCEDURE pr_cancelar (
        p_codigo IN Reserva.codigo_reserva%TYPE,
        p_mensagem OUT VARCHAR2
    );
END pkg_reservas;
/

-- [PL 18 PACKAGE BODY, 08 IF ELSIF, 13 SELECT INTO, 15 EXCEPTION]
CREATE OR REPLACE PACKAGE BODY pkg_reservas AS

    FUNCTION fn_vagas_disponiveis (
        p_motorista IN Viagem.cpf_motorista%TYPE,
        p_trajeto IN Viagem.id_trajeto%TYPE,
        p_partida IN Viagem.data_hora_partida%TYPE
    ) RETURN NUMBER
    IS
        v_vagas Viagem.vagas_disponiveis%TYPE;
    BEGIN
        SELECT vagas_disponiveis INTO v_vagas
          FROM Viagem
         WHERE cpf_motorista = p_motorista
           AND id_trajeto = p_trajeto
           AND data_hora_partida = p_partida;
        RETURN v_vagas;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Viagem nao encontrada.');
    END fn_vagas_disponiveis;

    PROCEDURE pr_solicitar (
        p_motorista IN Viagem.cpf_motorista%TYPE,
        p_trajeto IN Viagem.id_trajeto%TYPE,
        p_partida IN Viagem.data_hora_partida%TYPE,
        p_passageiro IN Passageiro.cpf%TYPE,
        p_quantidade IN Reserva.qtd_vagas%TYPE,
        p_codigo OUT Reserva.codigo_reserva%TYPE
    ) IS
        v_status Viagem.status%TYPE;
        v_existe NUMBER;
    BEGIN
        IF p_quantidade IS NULL OR p_quantidade < 1 OR p_quantidade <> TRUNC(p_quantidade) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Quantidade deve ser inteira e positiva.');
        ELSIF p_passageiro = p_motorista THEN
            RAISE_APPLICATION_ERROR(-20004, 'Motorista nao pode reservar propria viagem.');
        END IF;

        IF p_partida IS NULL OR p_partida <= SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20018, 'A partida deve estar no futuro.');
        END IF;

        SELECT status INTO v_status
          FROM Viagem
         WHERE cpf_motorista = p_motorista
           AND id_trajeto = p_trajeto
           AND data_hora_partida = p_partida FOR UPDATE;

        IF v_status <> 'AGENDADA' THEN
            RAISE_APPLICATION_ERROR(-20005, 'Somente viagens AGENDADAS aceitam solicitacoes.');
        END IF;

        SELECT COUNT(*) INTO v_existe
          FROM Passageiro WHERE cpf = p_passageiro;
        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Passageiro nao cadastrado.');
        END IF;

        SELECT COUNT(*) INTO v_existe
          FROM Reserva
         WHERE cpf_motorista_viagem = p_motorista
           AND id_trajeto = p_trajeto
           AND data_hora_partida = p_partida
           AND cpf_passageiro = p_passageiro
           AND status IN ('SOLICITADA', 'CONFIRMADA');
        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Passageiro ja possui reserva ativa nesta viagem.');
        END IF;

        p_codigo := seq_reserva.NEXTVAL;
        INSERT INTO Reserva (codigo_reserva, cpf_motorista_viagem,
             id_trajeto, data_hora_partida, cpf_passageiro,
             data_solicitacao, qtd_vagas, status)
        VALUES (p_codigo, p_motorista, p_trajeto, p_partida,
             p_passageiro, SYSDATE, p_quantidade, 'SOLICITADA');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20008, 'Viagem nao encontrada.');
    END pr_solicitar;

    PROCEDURE pr_confirmar (
        p_codigo IN Reserva.codigo_reserva%TYPE,
        p_mensagem OUT VARCHAR2
    ) IS
        v_reserva Reserva%ROWTYPE;
    BEGIN
        SELECT * INTO v_reserva FROM Reserva
         WHERE codigo_reserva = p_codigo FOR UPDATE;
        IF v_reserva.status <> 'SOLICITADA' THEN
            RAISE_APPLICATION_ERROR(-20009, 'Apenas reservas SOLICITADAS podem ser confirmadas.');
        END IF;
        -- O trigger ajusta o saldo na mesma instrucao que muda o status.
        UPDATE Reserva SET status = 'CONFIRMADA'
         WHERE codigo_reserva = p_codigo;
        p_mensagem := 'Reserva ' || p_codigo || ' confirmada.';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011, 'Reserva nao encontrada.');
    END pr_confirmar;

    PROCEDURE pr_cancelar (
        p_codigo IN Reserva.codigo_reserva%TYPE,
        p_mensagem OUT VARCHAR2
    ) IS
        v_reserva Reserva%ROWTYPE;
        v_status_viagem Viagem.status%TYPE;
    BEGIN
        SELECT * INTO v_reserva FROM Reserva
         WHERE codigo_reserva = p_codigo FOR UPDATE;
        IF v_reserva.status NOT IN ('SOLICITADA', 'CONFIRMADA') THEN
            RAISE_APPLICATION_ERROR(-20012, 'Somente reservas ativas podem ser canceladas.');
        END IF;
        SELECT status INTO v_status_viagem
          FROM Viagem
         WHERE cpf_motorista = v_reserva.cpf_motorista_viagem
           AND id_trajeto = v_reserva.id_trajeto
           AND data_hora_partida = v_reserva.data_hora_partida
         FOR UPDATE;
        IF v_status_viagem <> 'AGENDADA' THEN
            RAISE_APPLICATION_ERROR(-20013, 'Viagem nao esta agendada.');
        END IF;
        -- O trigger devolve as vagas de reservas confirmadas.
        UPDATE Reserva SET status = 'CANCELADA'
         WHERE codigo_reserva = p_codigo;
        p_mensagem := 'Reserva ' || p_codigo || ' cancelada.';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20014, 'Reserva ou viagem nao encontrada.');
    END pr_cancelar;
END pkg_reservas;
/

-- [PL 20 CREATE OR REPLACE TRIGGER (LINHA)]
-- Saldo centralizado aqui: package e UPDATE direto seguem a mesma regra.
-- Reserva nao muda de passageiro, viagem, quantidade ou data: cancele e solicite outra.
CREATE OR REPLACE TRIGGER trg_reserva_linha
BEFORE INSERT OR UPDATE OR DELETE ON Reserva
FOR EACH ROW
DECLARE
    v_status Viagem.status%TYPE;
BEGIN
    IF DELETING THEN
        IF :OLD.status IN ('CONFIRMADA', 'CONCLUIDA') THEN
            RAISE_APPLICATION_ERROR(-20019, 'Reserva confirmada/concluida nao pode ser excluida.');
        END IF;
    ELSE
        IF :NEW.cpf_passageiro = :NEW.cpf_motorista_viagem THEN
            RAISE_APPLICATION_ERROR(-20015, 'Passageiro nao pode ser o motorista da viagem.');
        END IF;
        IF :NEW.qtd_vagas IS NULL OR :NEW.qtd_vagas <= 0 THEN
            RAISE_APPLICATION_ERROR(-20016, 'Quantidade de vagas invalida.');
        END IF;
        IF UPDATING THEN
            IF :NEW.codigo_reserva <> :OLD.codigo_reserva
               OR :NEW.cpf_motorista_viagem <> :OLD.cpf_motorista_viagem
               OR :NEW.id_trajeto <> :OLD.id_trajeto
               OR :NEW.data_hora_partida <> :OLD.data_hora_partida
               OR :NEW.cpf_passageiro <> :OLD.cpf_passageiro
               OR :NEW.qtd_vagas <> :OLD.qtd_vagas
               OR :NEW.data_solicitacao <> :OLD.data_solicitacao THEN
                RAISE_APPLICATION_ERROR(-20020, 'Dados da reserva imutaveis; cancele e solicite outra.');
            END IF;
        END IF;
        IF INSERTING THEN
            IF :NEW.status IS NULL OR :NEW.status <> 'SOLICITADA' THEN
                RAISE_APPLICATION_ERROR(-20021, 'Nova reserva deve iniciar como SOLICITADA.');
            END IF;
            IF :NEW.data_hora_partida <= SYSDATE THEN
                RAISE_APPLICATION_ERROR(-20018, 'A partida deve estar no futuro.');
            END IF;
            SELECT status INTO v_status FROM Viagem
             WHERE cpf_motorista = :NEW.cpf_motorista_viagem
               AND id_trajeto = :NEW.id_trajeto
               AND data_hora_partida = :NEW.data_hora_partida FOR UPDATE;
            IF v_status <> 'AGENDADA' THEN
                RAISE_APPLICATION_ERROR(-20005, 'Somente viagens AGENDADAS aceitam solicitacoes.');
            END IF;
        ELSIF :NEW.status <> :OLD.status THEN
            IF :OLD.status = 'SOLICITADA' AND :NEW.status = 'CONFIRMADA' THEN
                UPDATE Viagem SET vagas_disponiveis = vagas_disponiveis - :NEW.qtd_vagas
                 WHERE cpf_motorista = :NEW.cpf_motorista_viagem
                   AND id_trajeto = :NEW.id_trajeto
                   AND data_hora_partida = :NEW.data_hora_partida
                   AND status = 'AGENDADA' AND data_hora_partida > SYSDATE
                   AND vagas_disponiveis >= :NEW.qtd_vagas;
                IF SQL%ROWCOUNT = 0 THEN
                    RAISE_APPLICATION_ERROR(-20010, 'Sem vagas, viagem nao agendada ou partida passada.');
                END IF;
            ELSIF :OLD.status IN ('SOLICITADA','CONFIRMADA') AND :NEW.status = 'CANCELADA' THEN
                SELECT status INTO v_status FROM Viagem
                 WHERE cpf_motorista = :NEW.cpf_motorista_viagem
                   AND id_trajeto = :NEW.id_trajeto
                   AND data_hora_partida = :NEW.data_hora_partida FOR UPDATE;
                IF v_status <> 'AGENDADA' THEN
                    RAISE_APPLICATION_ERROR(-20013, 'Viagem nao esta agendada.');
                END IF;
                IF :OLD.status = 'CONFIRMADA' THEN
                    UPDATE Viagem SET vagas_disponiveis = vagas_disponiveis + :OLD.qtd_vagas
                     WHERE cpf_motorista = :OLD.cpf_motorista_viagem
                       AND id_trajeto = :OLD.id_trajeto
                       AND data_hora_partida = :OLD.data_hora_partida;
                END IF;
            ELSIF :OLD.status = 'CONFIRMADA' AND :NEW.status = 'CONCLUIDA' THEN
                SELECT status INTO v_status FROM Viagem
                 WHERE cpf_motorista = :NEW.cpf_motorista_viagem
                   AND id_trajeto = :NEW.id_trajeto
                   AND data_hora_partida = :NEW.data_hora_partida;
                IF v_status <> 'CONCLUIDA' THEN
                    RAISE_APPLICATION_ERROR(-20022, 'A viagem deve estar CONCLUIDA.');
                END IF;
                -- Conclusao preserva as vagas consumidas como registro historico.
            ELSE
                RAISE_APPLICATION_ERROR(-20017, 'Transicao de status de reserva invalida.');
            END IF;
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'Viagem nao encontrada.');
END trg_reserva_linha;
/

-- [PL 19 CREATE OR REPLACE TRIGGER (COMANDO)]
CREATE OR REPLACE TRIGGER trg_reserva_comando
AFTER INSERT OR UPDATE OR DELETE ON Reserva
DECLARE
    v_pendentes NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_pendentes
      FROM Reserva WHERE status = 'SOLICITADA';
    DBMS_OUTPUT.PUT_LINE('Fila de reservas solicitadas: ' || v_pendentes);
END trg_reserva_comando;
/
