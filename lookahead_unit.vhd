-------------------------------------------------------------------------------
-- Title      : Unidade de Carry Lookahead (fast carry)
-- Project    : 
-------------------------------------------------------------------------------
-- File       : testb_alu.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Entidade usada por mips_adder
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity lookahead_unit is -- entidade responsavel por gerar os sinais de carry do segundo nivel de abstracao
	generic (n			:natural:= 4); -- n eh o numero de somadores envolvidos
	port (	P			:in std_logic_vector(n-1 downto 0); -- vetor com os sinais "super" propagate de cada um dos n somadores
			G			:in std_logic_vector(n-1 downto 0); -- vetor com os sinais "super" generate de cada um dos n somadores
			CarryIn		:in std_logic;
			Carry		:out std_logic_vector(n downto 1));
end lookahead_unit;

architecture estrutural of lookahead_unit is
begin
-- ver apendice C.6 do Patterson-Hennessy para explicacoes detalhadas
	Carry(1)<=G(0) OR (P(0) AND CarryIn);
	Carry(2)<=G(1) OR (P(1) AND G(0)) OR (P(1) AND P(0) AND CarryIn);
	Carry(3)<=G(2) OR (P(2) AND G(1)) OR (P(2) AND P(1) AND G(0)) OR (P(2) AND P(1) AND P(0) AND CarryIn);
	Carry(4)<=G(3) OR (P(3) AND G(2)) OR (P(3) AND P(2) AND G(1)) OR (P(3) AND P(2) AND P(1) AND G(0)) OR (P(3) AND P(2) AND P(1) AND P(0) AND CarryIn);
end estrutural;

