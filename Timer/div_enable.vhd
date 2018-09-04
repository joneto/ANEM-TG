-------------------------------------------------------------------------------
-- Title      : Timer
-- Project    : anem16
-------------------------------------------------------------------------------
-- File       : div_enable.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity div_enable is
  Generic (n :natural := 16;
           m :natural := 4;
           p :natural := 4**15);
  Port(clk,rst     :in std_logic;
       prescale    :in unsigned(m-1 downto 0);
       enable      :out std_logic);
end entity;

Architecture estrutural of div_enable is
Signal temp    :integer range 0 to p := 0;
Signal compara :integer range 0 to p := 0;
Begin
  process(prescale)
    Begin
      generico: for i in 0 to n-1 loop
        if prescale = i then
          compara <= 4**i;
        end if;
      end loop generico;
    end process;
  
  process(clk)
    Begin
      if rst = '1' then
        if rising_edge(clk) then
         if temp /= compara then 
           temp <= temp + 1;
         else
           temp <= 0;
         end if;
        end if;
      else
        temp <= 0;
      end if;
    end process;
      
enable <= '1' when temp = compara  AND rst = '1' else
          '0';
           
end estrutural;
