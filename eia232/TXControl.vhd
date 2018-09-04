library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TXControl is
  port(clk,baudenable     :in std_logic;
       rst      :in std_logic;
       TXEN     :in std_logic;
       TX9      :in std_logic;
       PBEN     :in std_logic;
       BufEmpty :in std_logic;
       GBufPop   :out std_logic;
       BitSel   :out unsigned(1 downto 0);
       TXIF     :out std_logic;
       TSRLoad  :out std_logic;
       TSRShift :out std_logic);
end TXControl;

architecture eia232 of TXControl is
  type state is (start,bit0,bit1,bit2,bit3,bit4,bit5,bit6,bit7,bit8,stop);
  signal currentstate,nextstate :state;
  signal BufPop :std_logic;
  constant Low : unsigned := "00";
  constant Data : unsigned := "01";
  constant Parity : unsigned := "10";
  constant High : unsigned := "11";

begin
  GBufPop <= BufPop and baudenable;
  P1: process(clk,rst)
  begin
      if rst = '0' then
        currentstate <= stop;
      elsif rising_edge(clk) and (baudenable='1') then
        currentstate <= nextstate;
      end if;
  end process P1;
  
  P2: process(currentstate,TXEN,TX9,PBEN,BufEmpty)
  begin
    case currentstate is
      when start =>
        nextstate <= bit0;
        BufPop <= '0';
        BitSel <= Low;
        TSRLoad <= '1';
        TSRShift <= '0';
      when bit0 =>
        nextstate <= bit1;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';
      when bit1 =>
        nextstate <= bit2;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit2 =>
        nextstate <= bit3;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit3 =>
        nextstate <= bit4;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit4 =>
        nextstate <= bit5;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit5 =>
        nextstate <= bit6;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit6 =>
        nextstate <= bit7;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';        
      when bit7 =>
        case TX9 is
          when '0'    => nextstate <= stop;
          when others => nextstate <= bit8;
        end case;
        BufPop <= '0';
        BitSel <= Data;
        TSRLoad <= '0';
        TSRShift <= '1';   
      when bit8 =>
        nextstate <= stop;
        case PBEN is
          when '1'    => BitSel <= Parity;
          when others => BitSel <= Data;
        end case;
        BufPop <= '0';
        TSRLoad <= '0';
        TSRShift <= '1';        
      when stop =>
        if (TXEN = '0') OR (BufEmpty = '1') then
          nextstate <= stop;
          BufPop <= '0';
        else
          nextstate <= start;
          BufPop <= '1';
        end if;
        BitSel <= High;
        TSRLoad <= '0'; 
        TSRShift <= '0';        
    end case;      
  end process P2;
  
  TXIF <= BufEmpty AND TXEN;
end eia232;
       
