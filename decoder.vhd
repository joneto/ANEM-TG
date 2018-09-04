-------------------------------------------------------------------------------
-- Title      : Decodificador para endereçar os registradores
-- Project    : 
-------------------------------------------------------------------------------
-- File       : decoder.vhd
-- Author     : Caio / Geraldo
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Usado por reg_file.vhd
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity decoder is 
   generic (n: integer :=16;
            m: integer :=4);
   port( rf_op   :in  unsigned(1 downto 0);
         input   :in  unsigned (m-1 downto 0);
 	       output  :out unsigned (2*n - 1 downto 0));
end decoder;


architecture behavioural of decoder is
  
begin
  decodificar: for i in 0 to n-1 generate
      output(2*i)<= rf_op(0) when to_integer(input)=i else
                  '0';
      output(2*i+1)<= rf_op(1) when to_integer(input)=i else
                  '0';
  end generate;
end architecture behavioural;
