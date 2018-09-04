-------------------------------------------------------------------------------
-- Title      : Registrador especifico para o pipeline
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegMEMWB.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador entre os estados Memory e Write Back
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegMEMWB is
    generic(n           :natural:=16;
            m           :natural:=4); -- qtd de linhas no sinal de controle
    port(   clk,rst,en  :in std_logic;
            
            RegIn0      :in unsigned(m-1 downto 0); -- Sinal de controle
            RegIn1      :in unsigned(n-1 downto 0); -- Endereco da instrucao + 1
            RegIn2      :in unsigned(3 downto 0); -- ra
            RegIn3      :in unsigned(n-1 downto 0); -- Ula_out
            RegIn4      :in unsigned(n-1 downto 0); -- ram_dout
            RegIn5      :in unsigned(11 downto 0); -- ra & byte
            RegIn6      :in std_logic;
            
            RegOut0     :out unsigned(m-1 downto 0);
            RegOut1     :out unsigned(n-1 downto 0);
            RegOut2     :out unsigned(3 downto 0);
            RegOut3     :out unsigned(n-1 downto 0);
            RegOut4     :out unsigned(n-1 downto 0);
            RegOut5     :out unsigned(11 downto 0);
            RegOut6     :out std_logic);
end RegMEMWB;

architecture comum of RegMEMWB is
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
   		 RegOut6 <= '0';
		elsif en = '1' and rising_edge(clk) then
			RegOut0 <= RegIn0;
			RegOut1 <= RegIn1;
			RegOut2 <= RegIn2;
			RegOut3 <= RegIn3;
			RegOut4 <= RegIn4;
			RegOut5 <= RegIn5;
			RegOut6 <= RegIn6;
		else
			null; -- mantem a informacao
		end if;
end process registrador;
end comum;