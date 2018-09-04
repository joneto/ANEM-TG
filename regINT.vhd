-------------------------------------------------------------------------------
-- Title      : Registrador de interrupções para o anem16
-- Project    : 
-------------------------------------------------------------------------------
-- File       : regINT.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Registrador de interrupções para o anem16
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regINT is
	generic(n	:natural:=16);
	port(	clk,rst,en	:in std_logic;
		reg_in		:in unsigned(n-1 downto 0);
		reg_out		:out unsigned(n-1 downto 0));
end regINT;

architecture anem16 of regINT is
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
