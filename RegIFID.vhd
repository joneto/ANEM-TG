-------------------------------------------------------------------------------
-- Title      : Registrador especifico para o pipeline
-- Project    : 
-------------------------------------------------------------------------------
-- File       : RegIFID.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador entre os estados Instruction Fetch e Instruction Decode
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegIFID is
    generic(n           :natural:=16);
    port(	clk,rst,en  :in std_logic;
            RegIn0      :in unsigned(n-1 downto 0); -- Instrucao a ser decodificada
            RegIn1      :in unsigned(n-1 downto 0); -- Endereco da inst + 1
            RegOut0     :out unsigned(n-1 downto 0);
            RegOut1     :out unsigned(n-1 downto 0));
end RegIFID;

architecture comum of RegIFID is
begin
registrador: process (clk,rst)
	begin
		if rst = '0' then
			RegOut0 <= (others => '0');
			RegOut1 <= (others => '0');
		elsif en = '1' and rising_edge(clk) then
			RegOut0 <= RegIn0;
			RegOut1 <= RegIn1;
		else
			null; -- mantem a informacao
		end if;
end process registrador;
end comum;
