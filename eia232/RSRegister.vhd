library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RSRegister is
  port( clk,baudenable  :in std_logic;
        rst   :in std_logic;
        RX9   :in std_logic;
        shift :in std_logic;
        regout :out unsigned(8 downto 0);
        sin   :in std_logic);
end RSRegister;

architecture eia232 of RSRegister is
  signal RSR  :unsigned(10 downto 0);
begin
  registdesloc  :process(clk,rst)
  begin
    if rst = '0' then
      RSR <= to_unsigned(0,11);
    elsif rising_edge(clk) then
      if (shift = '1') and (baudenable = '1') then
        RSR <= shift_right(RSR,1);
        RSR(10) <= sin;
      end if;
    end if;
  end process registdesloc;

  with RX9 select
   regout(7 downto 0) <= RSR(9 downto 2) when '1',
                         RSR(8 downto 1) when others;
  with RX9 select
	regout(8) <= RSR(1) when '1',
				 '0' when others;
    
end eia232;
        
       
