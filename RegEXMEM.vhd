-------------------------------------------------------------------------------
-- Title      : Registrador especifico para o pipeline
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegEXMEM.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador entre os estados Execute e Memory
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegEXMEM is
    generic(n           :natural:=16;
            m           :natural:=14); -- qtd de linhas no sinal de controle
    port(   clk,rst,en  :in std_logic;
            
            RegIn0      :in unsigned(m-1 downto 0); -- Sinal de controle
            RegIn1      :in unsigned(n-1 downto 0); -- Endereco da instrucao + 1
            --RegIn2      :in unsigned(n-1 downto 0); -- Endereco para BEQ
            RegIn3      :in unsigned(n-1 downto 0); -- Reg a
            --RegIn4      :in std_logic; -- Ula_zero
            RegIn5      :in unsigned(n-1 downto 0); -- Ula_out
            RegIn6      :in unsigned(11 downto 0); -- endereco (daqui tb tiramos ra, byte e func)
            RegIn7      :in std_logic;
            
            RegOut0     :out unsigned(m-1 downto 0);
            RegOut1     :out unsigned(n-1 downto 0);
            --RegOut2     :out unsigned(n-1 downto 0);
            RegOut3     :out unsigned(n-1 downto 0);
            --RegOut4     :out std_logic;
            RegOut5     :out unsigned(n-1 downto 0);   
            RegOut6     :out unsigned(11 downto 0);   
            RegOut7     :out std_logic);
end RegEXMEM;

architecture comum of RegEXMEM is
begin
registrador: process (clk,rst)
	begin
		if rst = '0' then
			RegOut0 <= (others => '0');
			RegOut1 <= (others => '0');
			--RegOut2 <= (others => '0');
			RegOut3 <= (others => '0');
			--RegOut4 <= '0';
			RegOut5 <= (others => '0');
			RegOut6 <= (others => '0');
			RegOut7 <= '0';
		elsif en = '1' and rising_edge(clk) then
			RegOut0 <= RegIn0;
			RegOut1 <= RegIn1;
			--RegOut2 <= RegIn2;
			RegOut3 <= RegIn3;
			--RegOut4 <= RegIn4;
			RegOut5 <= RegIn5;
			RegOut6 <= RegIn6;
			RegOut7 <= RegIn7;
		else
			null; -- mantem a informacao
		end if;
end process registrador;
end comum;