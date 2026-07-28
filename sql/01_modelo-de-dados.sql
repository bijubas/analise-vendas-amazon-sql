-- PostgreSQL | Modelo lógico para análise de vendas de e-commerce

CREATE TABLE clientes (
    id_cliente VARCHAR(25) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    estado VARCHAR(25)
);

CREATE TABLE produtos (
    id_produto VARCHAR(25) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    preco DECIMAL(12, 2),
    custo DECIMAL(12, 2) NOT NULL CHECK (custo >= 0)
);

CREATE TABLE vendedores (
    id_vendedor VARCHAR(25) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL
);

CREATE TABLE pedidos (
    id_pedido VARCHAR(25) PRIMARY KEY,
    data_pedido DATE NOT NULL,
    id_cliente VARCHAR(25) NOT NULL REFERENCES clientes(id_cliente),
    id_produto VARCHAR(25) NOT NULL REFERENCES produtos(id_produto),
    id_vendedor VARCHAR(25) REFERENCES vendedores(id_vendedor),
    estado VARCHAR(25),
    categoria VARCHAR(100) NOT NULL,
    subcategoria VARCHAR(100) NOT NULL,
    preco_unitario DECIMAL(12, 2),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    valor_venda DECIMAL(12, 2) NOT NULL CHECK (valor_venda >= 0)
);

CREATE TABLE devolucoes (
    id_devolucao VARCHAR(25) PRIMARY KEY,
    id_pedido VARCHAR(25) NOT NULL REFERENCES pedidos(id_pedido)
);

CREATE INDEX idx_pedidos_data ON pedidos(data_pedido);
CREATE INDEX idx_pedidos_cliente ON pedidos(id_cliente);
CREATE INDEX idx_pedidos_produto ON pedidos(id_produto);
