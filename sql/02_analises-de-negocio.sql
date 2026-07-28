-- PostgreSQL | Consultas de negócio

-- 1. Top 5 clientes mais lucrativos
SELECT c.id_cliente, c.nome, ROUND(SUM(p.valor_venda - pr.custo * p.quantidade), 2) AS lucro_total
FROM pedidos p JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY c.id_cliente, c.nome ORDER BY lucro_total DESC LIMIT 5;

-- 2. Quantidade média vendida por categoria
SELECT categoria, ROUND(AVG(quantidade), 2) AS quantidade_media
FROM pedidos GROUP BY categoria ORDER BY quantidade_media DESC;

-- 3. Top 5 produtos com maior faturamento
SELECT pr.id_produto, pr.nome, ROUND(SUM(p.valor_venda), 2) AS faturamento
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY pr.id_produto, pr.nome ORDER BY faturamento DESC LIMIT 5;

-- 4. Produtos com queda de receita em relação ao ano anterior
WITH receita_anual AS (
    SELECT id_produto, EXTRACT(YEAR FROM data_pedido)::INT AS ano, SUM(valor_venda) AS receita
    FROM pedidos GROUP BY id_produto, EXTRACT(YEAR FROM data_pedido)
), comparativo AS (
    SELECT *, LAG(receita) OVER (PARTITION BY id_produto ORDER BY ano) AS receita_ano_anterior
    FROM receita_anual
)
SELECT pr.nome, ano, receita_ano_anterior, receita, receita - receita_ano_anterior AS variacao
FROM comparativo c JOIN produtos pr ON pr.id_produto = c.id_produto
WHERE receita < receita_ano_anterior ORDER BY variacao;

-- 5. Subcategoria mais lucrativa
SELECT p.subcategoria, ROUND(SUM(p.valor_venda - pr.custo * p.quantidade), 2) AS lucro_total
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto
GROUP BY p.subcategoria ORDER BY lucro_total DESC LIMIT 1;

-- 6. Estados com mais pedidos
SELECT estado, COUNT(DISTINCT id_pedido) AS total_pedidos
FROM pedidos GROUP BY estado ORDER BY total_pedidos DESC;

-- 7. Mês com mais pedidos
SELECT DATE_TRUNC('month', data_pedido)::DATE AS mes, COUNT(DISTINCT id_pedido) AS total_pedidos
FROM pedidos GROUP BY mes ORDER BY total_pedidos DESC LIMIT 1;

-- 8. Margem de lucro por venda
SELECT p.id_pedido, p.valor_venda, pr.custo, p.quantidade,
       ROUND(100.0 * (p.valor_venda - pr.custo * p.quantidade) / NULLIF(p.valor_venda, 0), 2) AS margem_lucro_pct
FROM pedidos p JOIN produtos pr ON pr.id_produto = p.id_produto;

-- 9. Participação percentual das subcategorias no faturamento
SELECT subcategoria, ROUND(SUM(valor_venda), 2) AS faturamento,
       ROUND(100.0 * SUM(valor_venda) / SUM(SUM(valor_venda)) OVER (), 2) AS participacao_pct
FROM pedidos GROUP BY subcategoria ORDER BY participacao_pct DESC;

-- 10. Duas categorias com maior taxa de devolução
SELECT p.categoria, COUNT(d.id_devolucao) AS total_devolucoes,
       COUNT(DISTINCT p.id_pedido) AS total_pedidos,
       ROUND(100.0 * COUNT(d.id_devolucao) / NULLIF(COUNT(DISTINCT p.id_pedido), 0), 2) AS taxa_devolucao_pct
FROM pedidos p LEFT JOIN devolucoes d ON d.id_pedido = p.id_pedido
GROUP BY p.categoria ORDER BY taxa_devolucao_pct DESC LIMIT 2;
