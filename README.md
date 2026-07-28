# Análise de Vendas da Amazon com SQL

<p align="center">
  <img src="assets/amazon-logo.svg" alt="Amazon" width="360">
</p>

Projeto de portfólio para exploração de vendas de e-commerce com PostgreSQL. O foco é transformar registros de pedidos, clientes, produtos e devoluções em respostas acionáveis para áreas comercial, operações e estoque.

> **Status:** projeto analítico documentado. As consultas foram escritas para PostgreSQL e usam o modelo em português descrito em [`docs/modelo-de-dados.md`](docs/modelo-de-dados.md).

## Sumário

- [Visão geral](#visão-geral-do-projeto)
- [Objetivos](#objetivos-da-análise)
- [Perguntas de negócio](#perguntas-de-negócio-respondidas)
- [Insights e decisões](#insights-de-negócio)
- [Tecnologias](#tecnologias-utilizadas)
- [Estrutura](#estrutura-do-projeto)
- [Como executar](#como-executar)
- [Evoluções](#evoluções-sugeridas)

---

## Visão Geral do Projeto

A base representa operações de venda de um marketplace: cada pedido registra data, cliente, produto, vendedor, quantidade, valor vendido, categoria e localização. As tabelas auxiliares guardam o cadastro de clientes, o custo dos produtos, os vendedores e as devoluções.

O desafio de negócio é sair de uma visão transacional — milhares de linhas de pedidos — para uma leitura gerencial de receita, margem, demanda e risco de devolução. A análise foi desenhada para que uma pessoa recrutadora ou iniciante consiga entender tanto o raciocínio quanto a implementação SQL.

O objetivo é identificar onde a empresa gera mais valor, quais produtos exigem atenção e como o histórico pode orientar ações comerciais e operacionais.

## Objetivos da Análise

- identificar clientes, produtos e subcategorias com maior geração de lucro;
- medir demanda por categoria, estado e período;
- comparar receita entre anos para encontrar perdas de desempenho;
- calcular margem por venda e participação no faturamento;
- localizar categorias com devoluções relevantes para apoiar melhoria de qualidade e experiência.

---

## Perguntas de Negócio Respondidas

As consultas completas estão em [`sql/02_analises-de-negocio.sql`](sql/02_analises-de-negocio.sql). O resultado numérico depende da base carregada; abaixo, cada bloco explica o que a consulta responde e por que ela é útil.

### 1. Top 5 clientes mais lucrativos

**O que significa:** ranqueia clientes pela soma do lucro gerado, calculado como valor vendido menos custo do produto multiplicado pela quantidade.

**Por que importa:** receita alta não garante rentabilidade. Um cliente pode comprar muito com margens baixas; por isso o lucro é o critério principal.

**Consulta SQL:**

```sql
SELECT c.nome, ROUND(SUM(p.valor_venda - pr.custo * p.quantidade), 2) AS lucro_total
FROM pedidos p JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY c.nome ORDER BY lucro_total DESC LIMIT 5;
```

**Resultado esperado e uso:** retorna cinco clientes prioritários para ações de fidelização, atendimento consultivo ou ofertas exclusivas.

### 2. Quantidade média vendida por categoria

**O que significa:** calcula a média de unidades por pedido em cada categoria.

**Por que importa:** diferencia categorias de alto giro das vendas pontuais de grande valor.

**Consulta SQL:**

```sql
SELECT categoria, ROUND(AVG(quantidade), 2) AS quantidade_media
FROM pedidos GROUP BY categoria ORDER BY quantidade_media DESC;
```

**Resultado esperado e uso:** apoia previsão de reposição e definição de estoque de segurança por categoria.

### 3. Top 5 produtos com maior faturamento

**O que significa:** ordena os produtos pela receita acumulada.

**Por que importa:** revela os itens que mais movimentam o faturamento bruto.

**Consulta SQL:**

```sql
SELECT pr.nome, ROUND(SUM(p.valor_venda), 2) AS faturamento
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY pr.nome ORDER BY faturamento DESC LIMIT 5;
```

**Resultado esperado e uso:** ajuda a priorizar disponibilidade, campanhas e negociação com fornecedores desses itens.

### 4. Produtos com queda de receita em relação ao ano anterior

**O que significa:** compara o faturamento anual de cada produto com o ano imediatamente anterior usando uma função de janela.

**Por que importa:** identifica perda de demanda antes que ela se torne invisível no total da categoria.

**Consulta SQL:**

```sql
WITH receita_anual AS (
  SELECT id_produto, EXTRACT(YEAR FROM data_pedido)::int AS ano, SUM(valor_venda) AS receita
  FROM pedidos GROUP BY id_produto, EXTRACT(YEAR FROM data_pedido)
)
SELECT * FROM (
  SELECT *, LAG(receita) OVER (PARTITION BY id_produto ORDER BY ano) AS receita_anterior
  FROM receita_anual
) comparativo
WHERE receita < receita_anterior;
```

**Resultado esperado e uso:** aponta produtos para investigação de preço, concorrência, estoque ou possível descontinuação.

### 5. Subcategoria mais lucrativa

**O que significa:** soma a margem absoluta por subcategoria.

**Por que importa:** evita confundir a categoria mais vendida com a mais rentável.

**Consulta SQL:**

```sql
SELECT p.subcategoria, ROUND(SUM(p.valor_venda - pr.custo * p.quantidade), 2) AS lucro
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY p.subcategoria ORDER BY lucro DESC LIMIT 1;
```

**Resultado esperado e uso:** orienta decisões de mix, promoção e investimento em categorias.

### 6. Estados com mais pedidos

**O que significa:** conta pedidos por unidade federativa.

**Por que importa:** revela concentração geográfica da demanda e possíveis necessidades logísticas.

**Consulta SQL:**

```sql
SELECT estado, COUNT(DISTINCT id_pedido) AS total_pedidos
FROM pedidos GROUP BY estado ORDER BY total_pedidos DESC;
```

**Resultado esperado e uso:** auxilia a planejar campanhas regionais, centros de distribuição e acordos de frete.

### 7. Mês com mais pedidos

**O que significa:** identifica o período de maior volume de pedidos.

**Por que importa:** a sazonalidade afeta estoque, equipe, orçamento e capacidade logística.

**Consulta SQL:**

```sql
SELECT DATE_TRUNC('month', data_pedido)::date AS mes, COUNT(DISTINCT id_pedido) AS total
FROM pedidos GROUP BY mes ORDER BY total DESC LIMIT 1;
```

**Resultado esperado e uso:** permite antecipar compras, reforçar atendimento e planejar ações sazonais.

### 8. Margem de lucro por venda

**O que significa:** mede o percentual do valor vendido que permanece após o custo do item.

**Por que importa:** faturamento sem margem pode destruir valor para a empresa.

**Consulta SQL:**

```sql
SELECT id_pedido, ROUND(100.0 * (valor_venda - pr.custo * quantidade) / NULLIF(valor_venda, 0), 2) AS margem_pct
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto;
```

**Resultado esperado e uso:** mostra vendas que merecem revisão de preço, desconto ou negociação de custo.

### 9. Participação percentual das subcategorias

**O que significa:** calcula a parcela de cada subcategoria no faturamento total.

**Por que importa:** expõe dependência excessiva de poucas linhas de produto.

**Consulta SQL:**

```sql
SELECT subcategoria, ROUND(100.0 * SUM(valor_venda) / SUM(SUM(valor_venda)) OVER (), 2) AS participacao_pct
FROM pedidos GROUP BY subcategoria ORDER BY participacao_pct DESC;
```

**Resultado esperado e uso:** subsidia diversificação de portfólio e definição de metas de categoria.

### 10. Categorias com mais devoluções

**O que significa:** relaciona devoluções aos pedidos e calcula o índice de retorno por categoria.

**Por que importa:** devoluções podem indicar problema de produto, descrição, entrega ou expectativa do cliente.

**Consulta SQL:**

```sql
SELECT p.categoria, COUNT(d.id_devolucao) AS devolucoes,
       ROUND(100.0 * COUNT(d.id_devolucao) / COUNT(DISTINCT p.id_pedido), 2) AS taxa_devolucao_pct
FROM pedidos p LEFT JOIN devolucoes d ON d.id_pedido = p.id_pedido
GROUP BY p.categoria ORDER BY taxa_devolucao_pct DESC LIMIT 2;
```

**Resultado esperado e uso:** destaca as duas categorias que precisam de revisão de qualidade, conteúdo de produto ou pós-venda.

---

## Insights de Negócio

As análises permitem decisões como:

- **Fidelização de clientes estratégicos:** criar benefícios para quem combina recorrência e alto lucro.
- **Foco em produtos rentáveis:** garantir disponibilidade e exposição para subcategorias de melhor margem.
- **Ajuste de estoque:** aumentar cobertura de itens de alto giro e reduzir capital parado em baixa demanda.
- **Redução de devoluções:** investigar categorias com taxa elevada e corrigir causas antes de ampliar campanhas.
- **Planejamento sazonal:** preparar estoque, equipe e mídia para os meses de maior volume.
- **Gestão geográfica:** adequar frete e ações comerciais aos estados com maior concentração de pedidos.

## Tecnologias Utilizadas

- **SQL (PostgreSQL)** para criação do modelo e consultas analíticas.
- **Modelagem de Dados** para definição de entidades, chaves e cardinalidades.
- **Análise Exploratória** para interpretação de receita, lucro, demanda e devoluções.
- **GitHub** para versionamento, documentação e apresentação do projeto.

## Estrutura do Projeto

| Caminho | Finalidade |
| --- | --- |
| `README.md` | Documentação executiva e técnica do projeto. |
| `sql/01_modelo-de-dados.sql` | DDL do esquema analítico em português. |
| `sql/02_analises-de-negocio.sql` | Consultas que respondem às dez perguntas de negócio. |
| `docs/modelo-de-dados.md` | DER, cardinalidades e explicação dos relacionamentos. |
| `docs/guia-de-dashboard.md` | Sugestões para evolução em Power BI. |

## Como Executar

1. Crie um banco PostgreSQL para o projeto.
2. Execute `sql/01_modelo-de-dados.sql`.
3. Importe os dados para as tabelas correspondentes, respeitando as chaves do modelo.
4. Execute `sql/02_analises-de-negocio.sql` por blocos ou integralmente.
5. Compare os resultados com as perguntas de negócio documentadas acima.
