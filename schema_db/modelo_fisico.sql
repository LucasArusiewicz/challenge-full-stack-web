-- Fonte da função 'verificar_cpf': https://wiki.postgresql.org/wiki/CPF
-- Esta função retorna true se o CPF é válido  e falso caso contrário
-- Ela verifica o tamanho e os dígitos verificadores
--
CREATE OR REPLACE FUNCTION verificar_cpf(text)
RETURNS BOOLEAN AS $$
-- se o tamanho for 11 prossiga com o cálculo
-- senão retorne falso
SELECT CASE WHEN length($1) = 11 THEN
(
  -- verifica se os dígitos coincidem com os especificados
  SELECT
      substr($1, 10, 1) = CAST(digit1 AS text) AND
      substr($1, 11, 1) = CAST(digit2 AS text)
  FROM
  (
    -- calcula o segundo dígito verificador (digit2)
    SELECT
        -- se o resultado do módulo for 0 ou 1 temos 0
        -- senão temos a subtração de 11 pelo resultado do módulo
        CASE res2
        WHEN 0 THEN 0
        WHEN 1 THEN 0
        ELSE 11 - res2
        END AS digit2,
        digit1
    FROM
    (
      -- soma da multiplicação dos primeiros 9 dígitos por 11, 10, ..., 4, 3
      -- obtemos o módulo da soma por 11
      SELECT
          MOD(SUM(m * CAST(substr($1, 12 - m, 1) AS integer)) + digit1 * 2, 11) AS res2,
          digit1
      FROM
      generate_series(11, 3, -1) AS m,
      (
        -- calcula o primeiro dígito verificador (digit1)
        SELECT
            -- se o resultado do módulo for 0 ou 1 temos 0
            -- senão temos a subtração de 11 pelo resultado do módulo
            CASE res1
            WHEN 0 THEN 0
            WHEN 1 THEN 0
            ELSE 11 - res1
            END AS digit1
        FROM
        (
          -- soma da multiplicação dos primeiros 9 dígitos por 10, 9, ..., 3, 2
          -- obtemos o módulo da soma por 11
          SELECT
              MOD(SUM(n * CAST(substr($1, 11 - n, 1) AS integer)), 11) AS res1
          FROM generate_series(10, 2, -1) AS n
        ) AS sum1
      ) AS first_digit
      GROUP BY digit1
    ) AS sum2
  ) AS first_sec_digit
)
ELSE false END;

$$ LANGUAGE sql
IMMUTABLE STRICT;

COMMENT ON FUNCTION verificar_cpf(text) IS 'retorna verdadeiro se e, somente se, o CPF 
possui o tamanho correto (11 dígitos) e os dígitos calculados coincidem com os especificados';

-- Validação de domínio
CREATE DOMAIN email AS varchar(255) CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
CREATE DOMAIN cpf AS character(11) CHECK (verificar_cpf(VALUE));


-- Criação de entidades
CREATE TABLE Alunos (
    RA serial PRIMARY KEY,
    CPF cpf NOT NULL,
    Nome varchar(255) NOT NULL,
    Email email NOT NULL
);

