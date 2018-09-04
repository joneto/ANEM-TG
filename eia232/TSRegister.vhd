library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TSRegister is
  port( clk,baudenable  :in std_logic;
        rst   :in std_logic;
        shift :in std_logic;
        load  :in std_logic;
        regin :in unsigned(8 downto 0);
        parity:buffer std_logic;
        sout  :out std_logic);
end TSRegister;

architecture eia232 of TSRegister is
  signal TSR  :unsigned(8 downto 0);
begin
  registdesloc  :process(clk,rst)
  begin
    if rst = '0' then
      TSR <= to_unsigned(0,9);
      parity <= '0';
    elsif rising_edge(clk) and (baudenable='1') then
      if load = '1' then
        TSR <= regin;
        parity <= regin(7) XOR regin(6) XOR regin(5) XOR regin(4) XOR regin(3) XOR regin(2) XOR regin(1) XOR regin(0);
      elsif shift = '1' then
        TSR <= shift_right(TSR,1);
        parity <= parity;
      end if;
    end if;
  end process registdesloc;
  
  sout <= TSR(0);
    
end eia232;
        
       