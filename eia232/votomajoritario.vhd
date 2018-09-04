library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity votomajoritario is
  generic(n               :natural:=16);
  port(clk,baudenable     :in std_logic;
       rst                :in std_logic;
       UART_RXD           :in std_logic;
       UART_RXDMajoritario:out std_logic); -- retorna o dado majoritario presente no pino UART_RXD durante um ciclo de sclk (valores amostrados usando clk).
end votomajoritario;

architecture contadores of votomajoritario is
  signal  zeros,ones    :unsigned(n-1 downto 0);
begin
  process(clk,rst)
  begin
    if(rst='0')then
      zeros<=to_unsigned(0,n);
      ones<=to_unsigned(0,n);
    elsif(rising_edge(clk))then
      if baudenable='1' then
		  zeros<=to_unsigned(0,n);
		  ones<=to_unsigned(0,n);
      else
		  if(UART_RXD='0')then
			zeros<=zeros+to_unsigned(1,n);
		  else
			ones<=ones+to_unsigned(1,n);
		  end if;
	  end if;
    end if;
  end process;
  
  process(ones,zeros)
  begin
    if(ones>zeros)then
      UART_RXDMajoritario<='1';
    elsif(ones<zeros)then
      UART_RXDMajoritario<='0';
    else
      UART_RXDMajoritario<=UART_RXD;
    end if;
  end process;
end contadores;