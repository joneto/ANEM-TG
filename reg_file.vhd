-------------------------------------------------------------------------------
-- Title      : Arquivo de registradores
-- Project    : 
-------------------------------------------------------------------------------
-- File       : reg_file.vhd
-- Author     : Caio
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_file is
    generic (   n	:natural:=16;
                np:natural:=256;
                m :natural:=4);
    port (  clk,rst     :in std_logic;
            end_A,end_B :in unsigned(3 downto 0);
            end_w       :in unsigned(3 downto 0);
            rf_op       :in unsigned(1 downto 0);
            rf_ent16    :in unsigned(n-1 downto 0);
            rf_ent8     :in unsigned((n/2)-1 downto 0);
            reg_A,reg_B :out unsigned(n-1 downto 0));
end reg_file;

architecture pldp of reg_file is
   type vetor_2d is array ((n-1) downto 0) of unsigned((n -1) downto 0);
   signal big_q : vetor_2d;
   signal rf_controle   : unsigned (2*n - 1 downto 0);
   signal clock         : std_logic;
begin
    clock <= NOT clk; -- passa a ser sensivel a descida do clk.
    
a: entity work.decoder(behavioural) 
   generic map (n => n, m => m) port map (rf_op,end_w,rf_controle);

   big_q(0) <= (others=>'0');
   
regs:
   for i in 1 to n-1 generate         
    reg_i:
      entity work.rf_registrador(behavioural)     
      generic map (n => n) port map (clock,rst,rf_controle(2*i+1 downto 2*i),rf_ent16,rf_ent8,big_q(i));         
    end generate regs;      
            
    reg_A <= big_q(to_integer(end_A));
    reg_B <= big_q(to_integer(end_B));

end pldp;
