-------------------------------------------------------------------------------
-- Title      : Registrador especifico para o pipeline
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegIDEX.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador entre os estados Instruction Decode e Execute
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegIDEX is
    generic(n           :natural:=16;
            m           :natural:=11); -- qtd de linhas no sinal de controle
    port(   clk,rst,en  :in std_logic;
            
            RegIn0      :in unsigned(m-1 downto 0); -- Sinal gerado pela unidade de controle
            RegIn1      :in unsigned(n-1 downto 0); -- Endereco da instrucao + 1
            RegIn2      :in unsigned(n-1 downto 0); -- Reg a
            RegIn3      :in unsigned(n-1 downto 0); -- Reg b
            RegIn4      :in unsigned(n-1 downto 0); -- endereco (daqui tb tiramos ra, byte, func e shamt)
            RegIn5      :in unsigned(n-1 downto 0); -- Offset ja estendido
            RegIn6      :in unsigned(n-1 downto 0); -- endereco para interrupcoes
            RegIn7      :in std_logic; -- eh uma interrupcao
            RegIn8      :in std_logic; -- precisa esperar pq vai ocorrer uma interrupcao (wait_id)
            RegIn9      :in std_logic; -- indicador de excecao
						RegIn10			:in std_logic;
						--RegIn11   :in std_logic;
            
            RegOut0     :out unsigned(m-1 downto 0);
            RegOut1     :out unsigned(n-1 downto 0);
            RegOut2     :out unsigned(n-1 downto 0);
            RegOut3     :out unsigned(n-1 downto 0);
            RegOut4     :out unsigned(n-1 downto 0);
            RegOut5     :out unsigned(n-1 downto 0);
            RegOut6     :out unsigned(n-1 downto 0);
            RegOut7     :out std_logic;
            RegOut8     :out std_logic;
            RegOut9     :out std_logic;
						RegOut10		:out std_logic);
						--RegOut11  :out std_logic);
end RegIDEX;

architecture comum of RegIDEX is
begin
registrador: process (clk,rst)
	begin
		if rst = '0' then
			RegOut0 <= (others => '0');
			RegOut1 <= (others => '0');
			RegOut2 <= (others => '0');
			RegOut3 <= (others => '0');
			RegOut4 <= (others => '0');
			RegOut5 <= (others => '0');
			RegOut6 <= (others => '0');
			RegOut7 <= '0';
      RegOut8 <= '0';
      RegOut9 <= '0';
      RegOut10 <= '0';
--      RegOut11 <= '0';
		elsif en = '1' and rising_edge(clk) then
			RegOut0 <= RegIn0;
			RegOut1 <= RegIn1;
			RegOut2 <= RegIn2;
			RegOut3 <= RegIn3;
			RegOut4 <= RegIn4;
			RegOut5 <= RegIn5;
			RegOut6 <= RegIn6;
			RegOut7 <= RegIn7;
      RegOut8 <= RegIn8;
      RegOut9 <= RegIn9;
      RegOut10 <= RegIn10;
--      RegOut11 <= RegIn11;
		else
			null; -- mantem a informacao
		end if;
end process registrador;
end comum;
