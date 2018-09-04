-------------------------------------------------------------------------------
-- Title      : contador
-- Project    : timer
-------------------------------------------------------------------------------
-- File       : contador.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity contador is
  Generic(n   :natural := 16;
          m   :natural := 65535);
  Port (clk,rst,en  :in std_logic;
        controle    :in std_logic; -- 1 se for para contar ate a parada 0 caso seja pra contar ate estourar;
        parada      :in unsigned(n-1 downto 0);
        out_cont    :out unsigned(n-1 downto 0);
        ovf         :out std_logic;
        stop        :out std_logic
        );
end entity;

Architecture estrutural of contador is
Signal temp    :unsigned(n-1 downto 0) := (others =>'0');
Begin
  process(clk,en,rst)
  Begin
    if rst = '1' then
      if rising_edge(clk) AND en = '1' then
		  if controle = '0' OR (controle = '1' AND temp /= parada) then
          temp <= temp + 1;
		  end if;
      end if;
    else
      temp <= (others=>'0');
    end if;
  end process;
  
  ovf <= '1' when temp = m else
         '0';
  stop <= '1' when (temp = parada AND controle = '1') OR (temp = m AND controle = '0') else
          '0';
  out_cont <= temp;
          
  
end estrutural;