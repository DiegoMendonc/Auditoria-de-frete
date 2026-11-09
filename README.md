# Auditoria de alterações de frete

**Status em construção** · Projeto de portfólio com dados fictícios.

## Objetivo

Avaliar se aumentos no valor do frete receberam aprovação independente antes do pagamento. O risco é pagar um valor alterado sem revisão.

## Regra simulada

Um aumento **superior a R$ 500,00** exige aprovação por uma pessoa diferente de quem fez a alteração. A aprovação precisa ocorrer após a alteração e antes do pagamento. Um aumento de exatamente R$ 500,00 fica fora dessa regra.

O recorte inicial considera fretes pagos, com uma alteração e, quando registrada, uma aprovação por frete. A base guarda os valores em centavos e usa horários UTC em formato ISO 8601. Ela representa eventos para auditoria e inclui casos em que o controle falhou na simulação.

## Como carregar a base

Com o terminal aberto na pasta do projeto e o cliente SQLite instalado, execute em um banco novo:

```powershell
sqlite3 auditoria.db ".read base.sql"
sqlite3 auditoria.db "SELECT COUNT(*) FROM fretes;"
```

O resultado esperado é 5. O arquivo `auditoria.db` é gerado localmente. Ao publicar o projeto, inclua o script para que outras pessoas possam recriar a base.

## Casos para testar

| Frete | Cenário | Resultado esperado |
| --- | --- | --- |
| 1 | Aumento de R$ 600 com aprovação independente no prazo | Conforme |
| 2 | Aumento de R$ 600 sem aprovação registrada | Investigar ausência de aprovação |
| 3 | Aumento de R$ 600 aprovado pelo próprio responsável pela alteração | Investigar autoaprovação |
| 4 | Aumento de R$ 600 aprovado após o pagamento | Investigar aprovação tardia |
| 5 | Aumento de exatamente R$ 500 sem aprovação | Fora do critério |

## Próximas entregas

- [x] Definir o escopo, a regra e os cenários de teste.
- [x] Criar a base fictícia em SQLite.
- [ ] Escrever consultas e conferir o resultado de cada cenário.
- [ ] Documentar duas exceções, as evidências disponíveis e o que falta confirmar.
- [ ] Publicar um resumo dos resultados com uma captura do painel, se houver.

Uma aprovação ausente na base é um sinal para investigação. Em uma auditoria real, a completude da extração e os registros do sistema de origem precisariam ser verificados antes de concluir que o controle falhou.
