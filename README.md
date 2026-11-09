# Auditoria de alterações de frete

**Status em construção** · Projeto de portfólio com dados fictícios gerados em SQLite.

## Objetivo e escopo

Testar se aumentos no valor de fretes pagos receberam aprovação independente antes do pagamento. O risco é pagar um valor alterado sem revisão. A base simula o fluxo de pedidos, contratação, ajustes, aprovação e pagamento de um ERP de logística.

Cada pedido tem um frete. Um frete pode ter zero, uma ou duas alterações, e cada alteração pode ter até uma aprovação registrada. O teste inicial considera apenas fretes pagos. Fretes abertos e cancelados ajudam a testar o recorte.

## Regra simulada

A [Norma Interna NOR-LOG-001](norma-interna-fretes.md) define o critério de aprovação e as evidências usadas no teste.

Cada aumento **superior a R$ 500,00**, calculado em relação ao valor imediatamente anterior, exige aprovação por outra pessoa, após a alteração e antes do pagamento. A regra é aplicada por alteração. Reduções e aumentos de até R$ 500,00 ficam fora do critério.

Os valores são armazenados em centavos e os horários em UTC no formato ISO 8601. A geração é determinística. Recriar a base produz os mesmos registros e as mesmas exceções.

## Como carregar no DBeaver

1. Crie uma conexão SQLite apontando para um arquivo vazio chamado `auditoria_erp.db`. Escolha um arquivo diferente do banco de cinco fretes.
2. Abra um editor SQL nessa conexão, cole o conteúdo de [base.sql](base.sql) e execute o script completo com **Alt+X**.
3. Atualize a lista de tabelas e rode a consulta abaixo com **Ctrl+Enter**. Execute o script de carga uma vez por banco novo.

```sql
SELECT
    (SELECT COUNT(*) FROM fretes) AS total_fretes,
    (SELECT COUNT(*) FROM alteracoes_frete) AS total_alteracoes,
    (SELECT COUNT(*) FROM aprovacoes) AS total_aprovacoes;
```

Pelo terminal, com o cliente SQLite instalado e aberto na pasta do projeto, use `sqlite3 -bail auditoria_erp.db ".read base.sql"`. Para publicar no GitHub, inclua o script que recria a base.

## Modelo e volume esperado

| Tabela | Registros | Conteúdo |
| --- | ---: | --- |
| `filiais` | 6 | Nome e UF |
| `transportadoras` | 24 | Nome fictício e modal |
| `usuarios` | 60 | Filial e perfil de operação ou supervisão |
| `pedidos` | 12.000 | Filial, canal, data e peso |
| `fretes` | 12.000 | Pedido, transportadora, rota, valor contratado, status e data de pagamento |
| `alteracoes_frete` | 10.000 | Autor, valor anterior e novo, data e motivo |
| `aprovacoes` | 5.669 | Alteração, aprovador e data |

## Resultados de referência

Use estes totais para conferir sua consulta. A unidade de análise é **a alteração**, mesmo quando um frete aparece mais de uma vez.

| Classificação entre alterações acima do limite em fretes pagos | Total |
| --- | ---: |
| Sem aprovação registrada | 420 |
| Autoaprovação | 298 |
| Aprovação após o pagamento | 249 |
| Aprovação independente no prazo | 4.489 |
| **Total no escopo** | **5.456** |

A base inclui aumentos de R$ 499,99, R$ 500,00 e R$ 500,01 para testar a fronteira da regra. Aprovação ausente é um sinal para investigação. Em uma auditoria real, verifique a completude da extração e os registros do ERP antes de concluir que houve falha.

## Próximas entregas

- [x] Definir o escopo, a regra e os cenários.
- [x] Gerar a base fictícia em SQLite.
- [ ] Desenhar o modelo relacional e documentar as principais chaves.
- [ ] Escrever consultas para identificar as exceções e reconciliar os totais.
- [ ] Comparar a taxa de exceções por filial usando como denominador as alterações no escopo de cada filial.
- [ ] Investigar dois casos e registrar a evidência adicional que seria solicitada.
- [ ] Publicar um resumo de auditoria e, se houver, uma captura do painel.
