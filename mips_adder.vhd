-------------------------------------------------------------------------------
-- Title      : Somador para ser usado na ula (com fast carry)
-- Project    : 
-------------------------------------------------------------------------------
-- File       : testb_alu.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_adder is
	generic(n		:natural:=16; -- numero de bits das entradas => NAO PODE ALTERAR!
			m		:natural:=4); -- numero de bits dos somadores elementares => NAO ALTERAR!
	port (	a,b			:in unsigned(n-1 downto 0);
			CarryIn		:in std_logic;
			CarryOut	:out std_logic;
			Overflow	:out std_logic;
			Result		:buffer unsigned(n-1 downto 0));
end mips_adder;
---------------------------------------------------------------
----------- descricao em baixo nivel incluindo Carry Lookahead-
----------- Carry Lookahead com dois niveis de abstracao ------
---------------------------------------------------------------
architecture fast_carry of mips_adder is
	signal Prop,Gen							:std_logic_vector(n/m-1 downto 0);
	signal Carry								:std_logic_vector(n/m downto 1);
begin
-- o somador de n bits eh formado pela conexao de n/m somadores de m bits:
	concatenate: for i in n/m-1 downto 0 generate
		lsblock: if i=0 generate -- no somador menos significativo temos o CarryIn
			nbitadder_0 : entity work.nbit_adder(estrutural)
				port map (a(m-1 downto 0),b(m-1 downto 0),CarryIn,Result(m-1 downto 0),Prop(i),Gen(i));
		end generate lsblock;
		rest: if i>0 generate -- para o restante dos somadores o carry eh gerado a partir do sistema de Carry Lookahead, usando os sinais Prop e Gen
			nbitadder_i : entity work.nbit_adder(estrutural)
				port map (a((i+1)*m-1 downto i*m),b((i+1)*(m)-1 downto i*(m)),Carry(i),Result((i+1)*(m)-1 downto i*(m)),Prop(i),Gen(i));
		end generate rest;
	end generate concatenate;
-- a partir dos sinais super propagate e super generate (ver apendice C.6 do Patterson-Hennessy), o vetor carry
-- eh gerado pela unidade de carry lookahead
	Carry_Lookahead : entity work.lookahead_unit(estrutural)
--			generic map (n => n/m)
				port map (Prop,Gen,CarryIn,Carry);
	CarryOut <= Carry(n/m);
-- se os sinais das entradas eh o mesmo e este eh diferente do sinal da saida, temos overflow.
	Overflow <= (a(n-1) XNOR b(n-1)) AND (a(n-1) XOR Result(n-1));
	
end fast_carry;
