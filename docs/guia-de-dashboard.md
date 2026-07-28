# Proposta de Dashboard no Power BI

## Página 1 — Resumo executivo

- Cartões: faturamento, lucro, margem média, pedidos e clientes ativos.
- Linha temporal: faturamento e lucro por mês.
- Barras: top produtos e top subcategorias por lucro.
- Segmentadores: ano, estado, categoria e subcategoria.

## Página 2 — Clientes e geografia

- Ranking de clientes por lucro e faturamento.
- Mapa ou matriz de pedidos por estado.
- Dispersão de faturamento versus margem por cliente.
- Indicador de concentração: participação dos cinco principais clientes no lucro.

## Página 3 — Produtos e devoluções

- Matriz de categoria e subcategoria com receita, lucro e margem.
- Ranking de produtos com queda anual de receita.
- Barras de taxa de devolução por categoria.
- Tabela de produtos críticos: alta devolução, baixa margem ou queda de receita.

## Medidas recomendadas

```DAX
Faturamento = SUM(Pedidos[valor_venda])

Lucro =
SUMX(
    Pedidos,
    Pedidos[valor_venda] - RELATED(Produtos[custo]) * Pedidos[quantidade]
)

Margem % = DIVIDE([Lucro], [Faturamento])
```

## Boas práticas

- Exibir o período selecionado e a data de atualização em todas as páginas.
- Priorizar poucos visuais por página e destacar variações relevantes.
- Usar alertas para queda de receita e crescimento de devoluções.
- Validar totais do Power BI contra as consultas SQL antes de publicar.
