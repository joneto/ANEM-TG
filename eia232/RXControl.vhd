library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RXControl is
  port(clk        :in std_logic;
       baudenable :in std_logic;
       rst      :in std_logic;
       UART_RXD :in std_logic;
       RegCfgWe :in std_logic;
       SRENOut  :out std_logic;
       SRENIn,CREN:in std_logic;
       RX9      :in std_logic;
       BufFull  :in std_logic;
       GBufPush  :out std_logic;
       RXIF     :out std_logic;
       OERR,FERR:buffer std_logic;
       RSR9bit  :buffer std_logic;
       RSRShift :out std_logic);
end RXControl;

architecture eia232 of RXControl is
  type state is (bit0,bit1,bit2,bit3,bit4,bit5,bit6,bit7,bit8,bitstop,stop,iddle,framerror);
  signal currentstate,nextstate :state;
  signal RegSREN,SRENClear,SRENClear2,RegSRENClear  :std_logic;
  signal BufPush	:std_logic;
  
begin
  GBufPush <= BufPush and baudenable;
  P1: process(clk,rst)
  begin
      if rst = '0' then
        currentstate <= iddle;
      elsif rising_edge(clk) then
        if baudenable = '1' then
			currentstate <= nextstate;
		end if;
      end if;
  end process P1;
  
  P2: process(currentstate,RegSREN,CREN,RX9,BufFull,UART_RXD)
  begin
    case currentstate is
      when iddle =>
        if(UART_RXD='0') and ((RegSREN='1') or (CREN='1')) then
          nextstate <= bit0;
          RSRShift <= '1';
        else
          nextstate <= iddle;
          RSRShift <= '0';          
        end if;
        SRENClear <= '0';
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
      when bit0 =>
        nextstate <= bit1;
        SRENClear <= '1';
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';
      when bit1 =>
        nextstate <= bit2;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';        
      when bit2 =>
        nextstate <= bit3;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';
      when bit3 =>
        nextstate <= bit4;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';        
      when bit4 =>
        nextstate <= bit5;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';
      when bit5 =>
        nextstate <= bit6;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';
      when bit6 =>
        nextstate <= bit7;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';        
      when bit7 =>
        case RX9 is
          when '0'    => nextstate <= bitstop;
          when others => nextstate <= bit8;
        end case;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '-';
        RSRShift <= '1';
      when bit8 =>
        nextstate <= bitstop;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= '1';
        RSRShift <= '1';       
      when bitstop =>     
        SRENClear <= '0';        
        if (UART_RXD='0') then
          nextstate <= framerror;
        else
          nextstate <= stop;
        end if;
        BufPush <= '0';
        OERR <= '0';
        FERR <= '0';
        RSR9bit <= RSR9bit;
        RSRShift <= '1';
      when stop =>
        if (CREN='1' or RegSREN='1') and (BufFull='0') then
          OERR <= '0';
          BufPush <= '1';
          if (UART_RXD='0') then
            nextstate <= bit0;
            RSRShift <= '1';
          else
            nextstate <= iddle;
            RSRShift <= '0';
          end if;
        elsif (CREN='0' and RegSREN='0') and (BufFull='0') then
          nextstate <= iddle;
          RSRShift <= '0';
          BufPush <= '1';
          OERR <= '0';
        elsif (CREN='1' or RegSREN='1') and (BufFull='1') then
          nextstate <= stop;
          RSRShift <= '0';
          BufPush <= '0';
          OERR <= '1';
        else
          nextstate <= iddle;
          RSRShift <= '0';
          BufPush <= '0';
          OERR <= '1';
        end if;
        FERR <= '0';
        SRENClear <= '0';
        RSR9bit <= RSR9bit;
      when framerror =>
        if (CREN='1' or RegSREN='1') then
          if (UART_RXD='0') then
            nextstate <= bit0;
            RSRShift <= '1';
          else
            nextstate <= iddle;
            RSRShift <= '0';
          end if;
        else
          nextstate <= framerror;
          RSRShift <= '0';
        end if;
        SRENClear <= '0';        
        BufPush <= '0';
        OERR <= '0';
        FERR <= '1';
        RSR9bit <= RSR9bit;
    end case;      
  end process P2;
  
  RXIF <= (BufFull and (RegSREN or CREN)) or FERR or OERR; -- pode gerar uma interrupcao em qualquer um desses erros, cabe ao usuario descobrir qual interrupcao ocorreu
  
  process(clk,rst)
  		begin
		   if(rst='0') then
		     RegSRENClear<='0';
		   elsif rising_edge(clk) then
		     RegSRENClear<=SRENClear;
		   end if;
	end process;
  SRENClear2 <= SRENClear AND NOT(RegSRENClear);
  
  
  P3: process(clk,rst,SRENClear2)
  begin
      if rst = '0' or SRENClear2='1' then
        RegSREN <= '0';
      elsif rising_edge(clk) and RegCfgWe='1' then
        RegSREN <= SRENIn;
      end if;
  end process P3;
  
  SRENOut <= RegSREN;
  
end eia232;
       

