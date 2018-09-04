library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BaudRateGen is
  generic(n :natural:=16);
  port(clk      :in std_logic;
       rst      :in std_logic;
       DivConst :in unsigned(n-1 downto 0); -- Registrador do Baud Rate Generator, define por quanto o clock sera dividido.
       sclk     :out std_logic);
end BaudRateGen;

architecture counter of BaudRateGen is
  signal valor  :unsigned(n-1 downto 0);
begin
  divisordefreq: process(clk,rst)
  begin
    if rst = '0' then
      valor <= to_unsigned(0,n);
    elsif rising_edge(clk) then
      if valor = DivConst then
        valor <= to_unsigned(0,n);
      else
        valor <= valor + to_unsigned(1,n);
      end if;
    end if;
  end process divisordefreq;
  
  saida: process(valor,DivConst)
  begin
    if valor = DivConst then
      sclk <= '1';
    else
      sclk <= '0';
    end if;
  end process saida;
end counter;
