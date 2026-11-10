-- Auditoria de alterações de frete. Execute após carregar base.sql.
-- Cada consulta pode ser executada separadamente.

-- 1. População no escopo
SELECT COUNT(*) AS total_no_escopo
FROM alteracoes_frete AS a
JOIN fretes AS f ON f.id = a.frete_id
WHERE f.status = 'PAGO'
  AND a.valor_novo_centavos - a.valor_anterior_centavos > 50000;

-- 2. Classificação por alteração
WITH classificadas AS (
    SELECT
        a.id AS alteracao_id,
        f.id AS frete_id,
        a.valor_novo_centavos - a.valor_anterior_centavos AS aumento_centavos,
        a.alterado_por,
        ap.aprovado_por,
        a.alterado_em,
        ap.aprovado_em,
        f.pago_em,
        CASE
            WHEN ap.alteracao_id IS NULL
                THEN 'Sem aprovação registrada'
            WHEN ap.aprovado_por = a.alterado_por
                THEN 'Autoaprovação'
            WHEN ap.aprovado_em <= a.alterado_em
              OR ap.aprovado_em >= f.pago_em
                THEN 'Aprovação fora da ordem exigida'
            ELSE 'Conforme'
        END AS classificacao
    FROM alteracoes_frete AS a
    JOIN fretes AS f ON f.id = a.frete_id
    LEFT JOIN aprovacoes AS ap ON ap.alteracao_id = a.id
    WHERE f.status = 'PAGO'
      AND a.valor_novo_centavos - a.valor_anterior_centavos > 50000
)
SELECT *
FROM classificadas
ORDER BY alteracao_id;

-- 3. Reconciliação por classificação
WITH classificadas AS (
    SELECT
        a.id AS alteracao_id,
        f.id AS frete_id,
        a.valor_novo_centavos - a.valor_anterior_centavos AS aumento_centavos,
        a.alterado_por,
        ap.aprovado_por,
        a.alterado_em,
        ap.aprovado_em,
        f.pago_em,
        CASE
            WHEN ap.alteracao_id IS NULL
                THEN 'Sem aprovação registrada'
            WHEN ap.aprovado_por = a.alterado_por
                THEN 'Autoaprovação'
            WHEN ap.aprovado_em <= a.alterado_em
              OR ap.aprovado_em >= f.pago_em
                THEN 'Aprovação fora da ordem exigida'
            ELSE 'Conforme'
        END AS classificacao
    FROM alteracoes_frete AS a
    JOIN fretes AS f ON f.id = a.frete_id
    LEFT JOIN aprovacoes AS ap ON ap.alteracao_id = a.id
    WHERE f.status = 'PAGO'
      AND a.valor_novo_centavos - a.valor_anterior_centavos > 50000
)
SELECT
    classificacao,
    COUNT(*) AS total_alteracoes
FROM classificadas
GROUP BY classificacao
ORDER BY classificacao;

-- 4. Taxa de exceções por filial do pedido
WITH classificadas AS (
    SELECT
        a.id AS alteracao_id,
        p.filial_id,
        f.id AS frete_id,
        a.valor_novo_centavos - a.valor_anterior_centavos AS aumento_centavos,
        a.alterado_por,
        ap.aprovado_por,
        a.alterado_em,
        ap.aprovado_em,
        f.pago_em,
        CASE
            WHEN ap.alteracao_id IS NULL
                THEN 'Sem aprovação registrada'
            WHEN ap.aprovado_por = a.alterado_por
                THEN 'Autoaprovação'
            WHEN ap.aprovado_em <= a.alterado_em
              OR ap.aprovado_em >= f.pago_em
                THEN 'Aprovação fora da ordem exigida'
            ELSE 'Conforme'
        END AS classificacao
    FROM alteracoes_frete AS a
    JOIN fretes AS f ON f.id = a.frete_id
    JOIN pedidos AS p ON p.id = f.pedido_id
    LEFT JOIN aprovacoes AS ap ON ap.alteracao_id = a.id
    WHERE f.status = 'PAGO'
      AND a.valor_novo_centavos - a.valor_anterior_centavos > 50000
)
SELECT
    fi.nome AS filial,
    COUNT(*) AS total_no_escopo,
    SUM(CASE WHEN c.classificacao <> 'Conforme' THEN 1 ELSE 0 END)
        AS total_excecoes,
    ROUND(
        100.0 * SUM(CASE WHEN c.classificacao <> 'Conforme' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS taxa_excecoes_pct
FROM classificadas AS c
JOIN filiais AS fi ON fi.id = c.filial_id
GROUP BY fi.id, fi.nome
ORDER BY taxa_excecoes_pct DESC, fi.id;

-- 5. Casos investigados
WITH classificadas AS (
    SELECT
        a.id AS alteracao_id,
        f.id AS frete_id,
        a.valor_novo_centavos - a.valor_anterior_centavos AS aumento_centavos,
        a.alterado_por,
        ap.aprovado_por,
        a.alterado_em,
        ap.aprovado_em,
        f.pago_em,
        CASE
            WHEN ap.alteracao_id IS NULL
                THEN 'Sem aprovação registrada'
            WHEN ap.aprovado_por = a.alterado_por
                THEN 'Autoaprovação'
            WHEN ap.aprovado_em <= a.alterado_em
              OR ap.aprovado_em >= f.pago_em
                THEN 'Aprovação fora da ordem exigida'
            ELSE 'Conforme'
        END AS classificacao
    FROM alteracoes_frete AS a
    JOIN fretes AS f ON f.id = a.frete_id
    LEFT JOIN aprovacoes AS ap ON ap.alteracao_id = a.id
    WHERE f.status = 'PAGO'
      AND a.valor_novo_centavos - a.valor_anterior_centavos > 50000
)
SELECT
    alteracao_id,
    frete_id,
    aumento_centavos / 100.0 AS aumento_reais,
    alterado_por,
    aprovado_por,
    alterado_em,
    aprovado_em,
    pago_em,
    classificacao
FROM classificadas
WHERE alteracao_id IN (1742, 1862)
ORDER BY alteracao_id;
