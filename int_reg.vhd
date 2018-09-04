-------------------------------------------------------------------------------
-- Title      : Gerencia as interrupcoes
-- Project    : 
-------------------------------------------------------------------------------
-- File       : BancoInterrup.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


Entity int_reg is
  Generic (n :natural := 16);
  Port (clk,rst,ene     :in std_logic;
        in_reg          :in unsigned(n-1 downto 0);
        p               :in integer range 0 to n-1;
        out_reg         :out unsigned(n-1 downto 0));
end entity;

Architecture estrutural of int_reg is
Signal temp  :unsigned(n-1 downto 0) :=(others=>'0');
Begin
  process(clk,rst)
    begin
      if rst = '1' then
        if rising_edge(clk) then
          
          set:for i in 0 to n-1 loop
              if in_reg(i) = '1' then
               temp(i) <= '1';
              end if;
          end loop set; 
          
          if ene = '1' then
            temp(p) <= '0';
          end if;
        end if;
      else
        temp <= (others => '0');
      end if;      
    end process;
    out_reg <= temp;
end estrutural; 
