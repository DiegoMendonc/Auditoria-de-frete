PRAGMA foreign_keys = ON;
BEGIN;

CREATE TABLE filiais (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL,
    uf TEXT NOT NULL
);

CREATE TABLE transportadoras (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL,
    modal TEXT NOT NULL
);

CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL,
    filial_id INTEGER NOT NULL REFERENCES filiais(id),
    perfil TEXT NOT NULL CHECK (perfil IN ('OPERACAO', 'SUPERVISAO'))
);

CREATE TABLE pedidos (
    id INTEGER PRIMARY KEY,
    filial_id INTEGER NOT NULL REFERENCES filiais(id),
    canal TEXT NOT NULL,
    criado_em TEXT NOT NULL,
    peso_kg INTEGER NOT NULL CHECK (peso_kg > 0)
);

CREATE TABLE fretes (
    id INTEGER PRIMARY KEY,
    pedido_id INTEGER NOT NULL UNIQUE REFERENCES pedidos(id),
    transportadora_id INTEGER NOT NULL REFERENCES transportadoras(id),
    rota TEXT NOT NULL,
    contratado_em TEXT NOT NULL,
    valor_contratado_centavos INTEGER NOT NULL CHECK (valor_contratado_centavos > 0),
    status TEXT NOT NULL CHECK (status IN ('PAGO', 'ABERTO', 'CANCELADO')),
    pago_em TEXT,
    CHECK ((status = 'PAGO') = (pago_em IS NOT NULL))
);

CREATE TABLE alteracoes_frete (
    id INTEGER PRIMARY KEY,
    frete_id INTEGER NOT NULL REFERENCES fretes(id),
    alterado_por INTEGER NOT NULL REFERENCES usuarios(id),
    valor_anterior_centavos INTEGER NOT NULL CHECK (valor_anterior_centavos >= 0),
    valor_novo_centavos INTEGER NOT NULL CHECK (valor_novo_centavos >= 0),
    alterado_em TEXT NOT NULL,
    motivo TEXT NOT NULL,
    UNIQUE (frete_id, alterado_em)
);

CREATE TABLE aprovacoes (
    alteracao_id INTEGER PRIMARY KEY REFERENCES alteracoes_frete(id),
    aprovado_por INTEGER NOT NULL REFERENCES usuarios(id),
    aprovado_em TEXT NOT NULL
);

INSERT INTO filiais (id, nome, uf) VALUES
    (1, 'São Paulo', 'SP'), (2, 'Campinas', 'SP'),
    (3, 'Curitiba', 'PR'), (4, 'Belo Horizonte', 'MG'),
    (5, 'Rio de Janeiro', 'RJ'), (6, 'Vitória', 'ES');

WITH RECURSIVE serie(n) AS (
    VALUES (1)
    UNION ALL SELECT n + 1 FROM serie WHERE n < 24
)
INSERT INTO transportadoras (id, nome, modal)
SELECT n, printf('Transportadora %02d', n),
       CASE WHEN n % 6 = 0 THEN 'AEREO' ELSE 'RODOVIARIO' END
FROM serie;

WITH RECURSIVE serie(n) AS (
    VALUES (1)
    UNION ALL SELECT n + 1 FROM serie WHERE n < 60
)
INSERT INTO usuarios (id, nome, filial_id, perfil)
SELECT n, printf('Pessoa %02d', n), (n - 1) / 10 + 1,
       CASE WHEN (n - 1) % 10 < 8 THEN 'OPERACAO' ELSE 'SUPERVISAO' END
FROM serie;

WITH RECURSIVE serie(n) AS (
    VALUES (1)
    UNION ALL SELECT n + 1 FROM serie WHERE n < 12000
)
INSERT INTO pedidos (id, filial_id, canal, criado_em, peso_kg)
SELECT n, ((n * 37 + n / 19) % 6) + 1,
       CASE n % 3 WHEN 0 THEN 'ATACADO' WHEN 1 THEN 'VAREJO' ELSE 'E-COMMERCE' END,
       strftime('%Y-%m-%dT%H:%M:%SZ', '2026-01-01 08:00:00', printf('+%d days', (n * 17) % 181)),
       5 + (n * 23) % 3500
FROM serie;

INSERT INTO fretes (
    id, pedido_id, transportadora_id, rota, contratado_em,
    valor_contratado_centavos, status, pago_em
)
SELECT p.id, p.id, 1 + (p.id * 13 + p.id / 23) % 24,
       f.nome || ' - ' || CASE (p.id / 7) % 4
           WHEN 0 THEN 'Santos' WHEN 1 THEN 'Sorocaba'
           WHEN 2 THEN 'Joinville' ELSE 'Juiz de Fora' END,
       strftime('%Y-%m-%dT%H:%M:%SZ', p.criado_em, '+2 hours'),
       90000 + p.peso_kg * 75 + (p.id * 101) % 80000,
       CASE WHEN p.id % 20 = 0 THEN 'CANCELADO'
            WHEN p.id % 10 = 5 THEN 'ABERTO' ELSE 'PAGO' END,
       CASE WHEN p.id % 20 <> 0 AND p.id % 10 <> 5 THEN
           strftime('%Y-%m-%dT%H:%M:%SZ', p.criado_em, '+7 days')
       END
FROM pedidos p JOIN filiais f ON f.id = p.filial_id;

WITH valores AS (
    SELECT f.*, p.filial_id,
           CASE f.id % 7
               WHEN 0 THEN -15000 WHEN 1 THEN 50000 WHEN 2 THEN 49999
               WHEN 3 THEN 50001 ELSE 55000 + (f.id * 41) % 90000
           END AS variacao
    FROM fretes f JOIN pedidos p ON p.id = f.pedido_id
    WHERE f.id % 4 <> 0
)
INSERT INTO alteracoes_frete (
    id, frete_id, alterado_por, valor_anterior_centavos, valor_novo_centavos, alterado_em, motivo
)
SELECT id * 10 + 1, id, (filial_id - 1) * 10 + 1 + (id / 11) % 8,
       valor_contratado_centavos, valor_contratado_centavos + variacao,
       strftime('%Y-%m-%dT%H:%M:%SZ', contratado_em, '+1 day'),
       CASE WHEN variacao < 0 THEN 'Desconto negociado'
            WHEN id % 2 = 0 THEN 'Reentrega' ELSE 'Ajuste de cubagem' END
FROM valores;

INSERT INTO alteracoes_frete (
    id, frete_id, alterado_por, valor_anterior_centavos, valor_novo_centavos, alterado_em, motivo
)
SELECT a.id + 1, a.frete_id, a.alterado_por, a.valor_novo_centavos,
       a.valor_novo_centavos + 65000 + (a.frete_id * 31) % 45000,
       strftime('%Y-%m-%dT%H:%M:%SZ', a.alterado_em, '+2 days'),
       'Adicional de rota'
FROM alteracoes_frete a
WHERE a.frete_id % 6 = 0;

-- As exceções são intencionais. Os identificadores tornam a carga reproduzível.
INSERT INTO aprovacoes (alteracao_id, aprovado_por, aprovado_em)
SELECT a.id,
       CASE WHEN a.id % 17 = 0 THEN a.alterado_por
            ELSE (p.filial_id - 1) * 10 + 9 + (a.frete_id / 13) % 2 END,
       CASE WHEN f.pago_em IS NOT NULL AND a.id % 17 <> 0 AND a.id % 19 = 0
            THEN strftime('%Y-%m-%dT%H:%M:%SZ', f.pago_em, '+1 day')
            ELSE strftime('%Y-%m-%dT%H:%M:%SZ', a.alterado_em, '+4 hours') END
FROM alteracoes_frete a
JOIN fretes f ON f.id = a.frete_id
JOIN pedidos p ON p.id = f.pedido_id
WHERE a.valor_novo_centavos - a.valor_anterior_centavos > 50000
  AND a.id % 13 <> 0;

COMMIT;
