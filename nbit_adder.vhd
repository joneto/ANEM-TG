-------------------------------------------------------------------------------
-- Title      : Somador de 4 bits com fast Carry
-- Project    : 
-------------------------------------------------------------------------------
-- File       : nbit_adder.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Bloco fundamental do somador da ula
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nbit_adder is
	generic(m		:natural:=4);
	port (	a,b			:in unsigned(m-1 downto 0);
			CarryIn		:in std_logic;
			Result		:buffer unsigned(m-1 downto 0);
			Prop,Gen	:out std_logic);
end nbit_adder;

architecture estrutural of nbit_adder is
	signal Carry							:unsigned(m-1 downto 0);
	signal g,p								:unsigned(m-1 downto 0);
begin
	-- para obter os carry, precisamos inicialmente gerar os sinais generate (gi=ai*bi) e
	-- propagate (pi=ai+bi). O sinal gi indica que um carry eh produzido na soma dos bits i,
	-- enquanto o sinal pi indica que a soma dos bits i ira propagar um carry vindo da soma
	-- dos bits menos significativos.
	-- ver apendice C.6 do Patterson-Hennessy para mais detalhes
	esquema_generate:	for i in m-1 downto 0 generate
			g(i)<=a(i) AND b(i);
	end generate esquema_generate;
	esquema_propagate:	for i in m-1 downto 0 generate
			p(i)<=a(i) OR b(i);
	end generate esquema_propagate;
	
	Carry(0)<=CarryIn;
	Carry(1)<=g(0) OR (p(0) AND CarryIn);
	Carry(2)<=g(1) OR (p(1) AND g(0)) OR (p(1) AND p(0) AND CarryIn);
	Carry(3)<=g(2) OR (p(2) AND g(1)) OR (p(2) AND p(1) AND g(0)) OR (p(2) AND p(1) AND p(0) AND CarryIn);
	

-- precisamos tambem gerar os sinais super propagate e super generate que serao usados para gerar
-- o vetor carry no segundo nivel de abstracao do carry lookahead.
	Prop <= p(3) AND p(2) AND p(1) AND p(0);
	Gen <= g(3) OR (p(3) AND g(2)) OR (p(3) AND p(2) AND g(1)) OR (p(3) AND p(2) AND p(1) AND g(0));

	Result <= a XOR b XOR Carry(m-1 downto 0);


end estrutural;

