-------------------------------------------------------------------------------
-- Title      : Registrador especial para ser usado no Arquivo de Registradores
-- Project    : 
-------------------------------------------------------------------------------
-- File       : testb_alu.vhd
-- Author     : Caio / Geraldo
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Este registrador permite as operações lil e liu
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rf_registrador is
	generic(n	:natural:=16);
	port(	clk,rst	:in std_logic;
			ctrl		:in unsigned(1 downto 0);
			ent16		:in unsigned(n-1 downto 0);
			ent8   :in unsigned(n/2-1 downto 0);
			q16    :out unsigned(n-1 downto 0));
end rf_registrador;

architecture behavioural of rf_registrador is
  signal ent_msb,ent_lsb  :unsigned(n/2-1 downto 0);
begin
reg_msb:  entity work.uregistrador(comum)     
      generic map (n => n/2) port map (clk,rst,ctrl(1),ent_msb,q16(n-1 downto n/2));
reg_lsb:  entity work.uregistrador(comum)     
      generic map (n => n/2) port map (clk,rst,ctrl(0),ent_lsb,q16(n/2-1 downto 0));
  with ctrl(0) select
    ent_msb <=  ent8 when '0',
                ent16(n-1 downto n/2) when others;
  with ctrl(1) select  
    ent_lsb <=  ent8 when '0',
                ent16(n/2-1 downto 0) when others;
end behavioural;
