# Norma interna de alteração e aprovação de fretes

| Identificação | Detalhe |
| --- | --- |
| Código | NOR-LOG-001 |
| Versão | 1.0 |
| Vigência simulada | 1º de janeiro de 2026 |
| Área responsável | Logística |
| Natureza | Norma fictícia para projeto de portfólio |

## 1. Objetivo e abrangência

Prevenir pagamentos de fretes com aumentos de valor sem revisão independente. A norma se aplica às alterações de valor de fretes registrados no ERP de todas as filiais da operação simulada.

## 2. Registro da alteração

A área de Logística deve registrar no ERP o frete, o valor imediatamente anterior, o novo valor, o motivo da alteração, o usuário responsável e o horário do registro. Se houver mais de uma alteração no mesmo frete, cada alteração deve ter seu próprio registro.

## 3. Aprovação e liberação para pagamento

1. O limite de aprovação é aplicado **por alteração**, pela diferença entre o valor novo e o valor imediatamente anterior.
2. Cada **aumento superior a R$ 500,00** exige aprovação de uma pessoa diferente de quem registrou a alteração.
3. A aprovação deve estar vinculada à alteração específica. O ERP deve registrar o aprovador e o horário da aprovação.
4. Para ser válida, a aprovação deve ocorrer **depois do registro da alteração e antes do pagamento**. Horários iguais não atendem à ordem exigida.
5. A área Financeira deve liberar o pagamento somente quando todas as alterações do frete sujeitas à regra tiverem aprovação válida.
6. Reduções e aumentos de até R$ 500,00, inclusive, ficam dispensados dessa aprovação.

| Alteração individual | Exigência |
| --- | --- |
| De R$ 1.000,00 para R$ 1.499,99 | Aprovação dispensada |
| De R$ 1.000,00 para R$ 1.500,00 | Aprovação dispensada |
| De R$ 1.000,00 para R$ 1.500,01 | Aprovação independente obrigatória |

Se um frete passar de R$ 1.000,00 para R$ 1.600,00 e depois para R$ 2.250,00, cada aumento exige sua própria aprovação.

## 4. Aplicação no teste de auditoria

A unidade de análise é **cada alteração de valor em um frete pago**. Fretes abertos e cancelados ficam fora deste teste de pagamento. Os valores da base estão em centavos e os horários estão em UTC.

| Evidência | Onde verificar na base |
| --- | --- |
| Status e data de pagamento | `fretes.status` e `fretes.pago_em` |
| Valor anterior e valor novo | `alteracoes_frete.valor_anterior_centavos` e `alteracoes_frete.valor_novo_centavos` |
| Responsável e horário da alteração | `alteracoes_frete.alterado_por` e `alteracoes_frete.alterado_em` |
| Vínculo da aprovação | `aprovacoes.alteracao_id` |
| Aprovador e horário da aprovação | `aprovacoes.aprovado_por` e `aprovacoes.aprovado_em` |

Para alterações acima do limite, registre como exceção a ausência de aprovação na extração, a autoaprovação ou a aprovação fora da ordem exigida. Guarde o ID do frete, o ID da alteração, a diferença de valor e a evidência que sustenta a classificação.

Uma aprovação ausente na extração deve ser investigada. Confira a completude da base e procure a evidência no ERP de origem antes de concluir que a aprovação não ocorreu.
