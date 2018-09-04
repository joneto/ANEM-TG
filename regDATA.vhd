-------------------------------------------------------------------------------
-- Title      : Registrador de entrada/saida
-- Project    : 
-------------------------------------------------------------------------------
-- File       : regDATA.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador de entrada/saida
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regDATA is
	generic(n	:natural:=16);
	port(	clk,rst,en	:in std_logic;
		reg_in		:in unsigned(n-1 downto 0);
		reg_out		:out unsigned(n-1 downto 0));
end regDATA;

architecture anem16 of regDATA is
begin
registrador: process (clk,rst)
	begin
		if rst = '0' then
			reg_out <= (others => '0');
		elsif en = '1' and rising_edge(clk) then
			reg_out <= reg_in;
		else
			null;
		end if;
end process registrador;
end anem16;
