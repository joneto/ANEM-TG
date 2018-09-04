-------------------------------------------------------------------------------
-- Title      : Timer
-- Project    : timer
-------------------------------------------------------------------------------
-- File       : timer.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity timer is
  Generic(n :natural := 16);
  Port (
        clk,rst                :in std_logic;
        config                 :in unsigned(n-1 downto 0);
        enc                    :in std_logic;
        parada0,parada1        :in unsigned(n-1 downto 0);
		  en0, en1               :in std_logic;
        timer0, timer1         :out unsigned(n-1 downto 0);
        int_timer0, int_timer1 :out std_logic;
        int_timer32            :out std_logic  
        );
end entity;
-- Registrador de Configuracao:
-- bit 0 => os dois timers trabalhando separadamente ou como um unico de 32 bits
-- bit 1 => on/off timer 0
-- bit 2 => contar ate o numero gravado no registrador de parada ou ate o contador estourar
-- bit 3 => --
-- bit 4 => prescale
-- bit 5 => prescale
-- bit 6 => prescale
-- bit 7 => prescale
-- bit 8 => on/off timer 1
-- bit 9 => contar ate o numero gravado no registrador de parada ou ate o contador estourar
-- bit 10 => --
-- bit 11 => prescale
-- bit 12 => prescale
-- bit 13 => prescale
-- bit 14 => prescale
-- bit 15 => --

Architecture estrutural of timer is 
Signal reg_config, reg_parada0, reg_parada1 :unsigned(n-1 downto 0); --saida dos registraodores de configuracao e parada;
Signal out_timer0, out_timer1               :unsigned(n-1 downto 0);
Signal contr0, contr1                       :std_logic := '0';
Signal rst0, rst1,rste1, stop0, stop1       :std_logic := '0';
Signal ovf0,ovf1, enable0, enable1, ent1    :std_logic := '0';

-----------
-- geraldo: tentanto corrigir o problema do sincronismo das interrupcoes com o clock do anem (esta sincronizado com o do timer, gerando varias interrupcoes)
signal int_timer0_interno, int_timer1_interno,int_timer32_interno    :std_logic;
signal int_timer0_interno_atrasado, int_timer1_interno_atrasado,int_timer32_interno_atrasado   :std_logic;
-----------

Begin
  
Reg_Configuracao: entity work.uregistrador
   generic map (n) port map (clk,rst,enc,config,reg_config); 
   
Reg_Parad0: entity work.uregistrador
   generic map (n) port map (clk,rst,en0,parada0,reg_parada0);
   
Reg_Parad1: entity work.uregistrador
   generic map (n) port map (clk,rst,en1,parada1,reg_parada1); 
   
Timer_0: entity work.contador 
   generic map (n) port map (clk,rst0,enable0,contr0,reg_parada0,out_timer0,ovf0,stop0); 

Timer_1: entity work.contador 
   generic map (n) port map (clk,rst1,ent1,contr1,reg_parada1,out_timer1,ovf1,stop1);   
   
Clock_enable0: entity work.div_enable
   port map (clk,rst0,reg_config(7 downto 4),enable0);
  
Clock_enable1: entity work.div_enable
   port map (clk,rste1,reg_config(14 downto 11),enable1);  

--definicao das entradas de controle;
contr0 <= '1' when  reg_config(2) = '1' else
          '0';
contr1 <= '1' when  reg_config(9) = '1' else
          '0';
rst0 <=  '1' when reg_config(1) = '1' OR reg_config(0) = '1' else
         '0';
rst1 <=  '1' when reg_config(8) = '1' OR reg_config(0) = '1' else
         '0';
rste1 <=  '1' when reg_config(8) = '1' AND reg_config(0) = '0' else --so funciona se o timer1 estiver trabalhando independente do timer0;
          '0';

ent1 <= enable1 when reg_config(0) = '0' else
        ovf0 AND enable0;

--interrupcoes;
int_timer0_interno <= '1' when ((ovf0 = '1' AND reg_config(2) = '0') OR (stop0 = '1' AND reg_config(2) = '1')) AND reg_config(0) = '0' else
              '0';

int_timer1_interno <= '1' when ((ovf1 = '1' AND reg_config(9) = '0') OR (stop1 = '1' AND reg_config(9) = '1')) AND reg_config(0) = '0' else
              '0';

int_timer32_interno <= '1' when reg_config(0) = '1' AND ((out_timer1 & out_timer0) = (reg_parada1 & reg_parada0)) else
 
              '0';

-----------
-- geraldo: tentanto corrigir o problema do sincronismo das interrupcoes com o clock do anem (esta sincronizado com o do timer, gerando varias interrupcoes)

interrupcoes1: process(clk,rst)
begin
    if rst='0' then
      int_timer0_interno_atrasado <= '0';
      int_timer1_interno_atrasado <= '0';
      int_timer32_interno_atrasado <= '0';
    elsif rising_edge(clk) then
      int_timer0_interno_atrasado <= int_timer0_interno;
      int_timer1_interno_atrasado <= int_timer1_interno;
      int_timer32_interno_atrasado <= int_timer32_interno;
    end if;
end process interrupcoes1;

int_timer0 <= '1' when (int_timer0_interno='1') and (int_timer0_interno_atrasado='0') else
              '0';
int_timer1 <= '1' when (int_timer1_interno='1') and (int_timer1_interno_atrasado='0') else
              '0';
int_timer32 <= '1' when (int_timer32_interno='1') and (int_timer32_interno_atrasado='0') else
              '0';

-----------


--saida dos timers;
timer0 <= out_timer0;
timer1 <= out_timer1;
end estrutural;        
    
