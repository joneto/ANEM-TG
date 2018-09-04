-------------------------------------------------------------------------------
-- Title      : Gerencia as interrupcoes
-- Project    : 
-------------------------------------------------------------------------------
-- File       : BancoInterrup.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity BancoInterrup is
      Generic (n    :natural := 16);
      Port(
           HabBanco   :in std_logic;
           endBanco   :in natural range 0 to n-1;
           pulo       :out unsigned(n-1 downto 0)   
           );
end Entity; 


Architecture estrutura of BancoInterrup is

Signal const :unsigned(n-5 downto 0) :="000011111101" ;
Begin

 pulo <= (const & to_unsigned(endBanco,4)) when HabBanco = '1' else
        (others=>'0');    

end estrutura;
