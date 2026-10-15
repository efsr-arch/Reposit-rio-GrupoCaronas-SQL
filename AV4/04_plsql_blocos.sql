-- B01 [PL 01 RECORD, 03 BLOCO ANONIMO, 06 %TYPE, 07 %ROWTYPE, 08 IF ELSIF, 09 CASE]
DECLARE
    TYPE t_indicadores IS RECORD (
        cpf Motorista.cpf%TYPE,
        nome Usuario.nome%TYPE,
        total_avaliacoes NUMBER,
        media_notas NUMBER
    );
    v_info t_indicadores;
    v_usuario Usuario%ROWTYPE;
    v_faixa VARCHAR2(30);
BEGIN
    SELECT * INTO v_usuario FROM Usuario WHERE cpf = '12345678901';
    SELECT m.cpf, u.nome, COUNT(a.nota), NVL(AVG(a.nota), 0)
      INTO v_info.cpf, v_info.nome,
           v_info.total_avaliacoes, v_info.media_notas
      FROM Motorista m
      JOIN Usuario u ON u.cpf = m.cpf
      LEFT JOIN Avalia a ON a.cpf_motorista_viagem = m.cpf
     WHERE m.cpf = v_usuario.cpf
     GROUP BY m.cpf, u.nome;

    IF v_info.total_avaliacoes = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ainda nao possui avaliacoes.');
    ELSIF v_info.media_notas >= 4 THEN
        DBMS_OUTPUT.PUT_LINE('Motorista com otima avaliacao.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Avaliacao abaixo de 4.');
    END IF;

    v_faixa := CASE
        WHEN v_info.media_notas >= 4.5 THEN 'EXCELENTE'
        WHEN v_info.media_notas >= 3.0 THEN 'SATISFATORIO'
        ELSE 'PRECISA MELHORAR'
    END;
    DBMS_OUTPUT.PUT_LINE(v_info.nome || ' (' || v_info.cpf || '): ' ||
        v_info.total_avaliacoes || ' avaliacoes; media ' ||
        TO_CHAR(ROUND(v_info.media_notas, 2)) || '; faixa ' || v_faixa);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Usuario nao encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao gerar painel: ' || SQLERRM);
END;
/

-- B02 [PL 02 TABLE associativa, 11 WHILE LOOP, 12 FOR IN LOOP].
DECLARE
    TYPE t_codigos IS TABLE OF Reserva.codigo_reserva%TYPE
        INDEX BY PLS_INTEGER;
    v_codigos t_codigos;
    v_indice PLS_INTEGER := 1;
BEGIN
    FOR r IN (
        SELECT codigo_reserva
          FROM Reserva
         ORDER BY data_solicitacao DESC, codigo_reserva DESC
         FETCH FIRST 5 ROWS ONLY
    ) LOOP
        v_codigos(v_indice) := r.codigo_reserva;
        v_indice := v_indice + 1;
    END LOOP;

    v_indice := 1;
    WHILE v_indice <= v_codigos.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Reserva ' || v_codigos(v_indice) ||
            ', valor R$ ' || fn_valor_reserva(v_codigos(v_indice)));
        v_indice := v_indice + 1;
    END LOOP;
END;
/

-- B03 [PL 04 PROCEDURE, 10 LOOP EXIT WHEN, 14 CURSOR, 16 IN/OUT]
DECLARE
    v_total NUMBER;
BEGIN
    pr_listar_viagens_motorista('12345678901', v_total);
    DBMS_OUTPUT.PUT_LINE('Total de viagens do motorista: ' || v_total);
END;
/

-- B04 [PL 17/18 PACKAGE/BODY, 16 parametros IN]:
DECLARE
    v_vagas NUMBER;
BEGIN
    v_vagas := pkg_reservas.fn_vagas_disponiveis(
        '56789012345', 6,
        TO_DATE('2026-10-17 08:00', 'YYYY-MM-DD HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('Viagem 17/10: ' || v_vagas || ' vaga(s) disponivel(is).');
END;
/
