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

Entity teste is
  Generic (n   :natural := 16);
  Port(outint   :unsigned(n-1 downto 0));
End entity;


Architecture estrutural of teste is
Signal  clk             : std_logic := '0';
Signal rst             : std_logic;
Signal we              : std_logic := '1';
Signal jal             : std_logic;                  -- ocorreu um jal;
Signal hab             : std_logic;                  -- habilita as interrupcoes;   
Signal VetorInterrup   : unsigned(n-1 downto 0):=(others => '1');     -- OBS1;
Signal VetorHabilita   : unsigned(n-1 downto 0);     -- OBS2;
Signal RegHab          : unsigned(n-1 downto 0);  -- indica as interrupcoes que estao habilitadas no programa utilizado;
Signal pulo            : std_logic;                 -- manda o processador fazer um jal;
Signal InstrucInterrup : unsigned(n-1 downto 0);    -- instrucao a ser mandada no para o pipeline;
Signal IntEnCo, IntEnOv: std_logic; 
Begin
  

  Interrup: Entity work.interrupcoes
  generic map(n) port map(clk,rst,we,jal,hab,VetorInterrup,VetorHabilita,RegHab,pulo,InstrucInterrup,IntEnCo, IntEnOv);
  
process(clk)
  Begin
    clk <= not clk after 5ns;
  end process;
process
  Begin
    VetorInterrup <= (others =>'0') after 9ns;
  end process;
hab <= '1';  
rst <= '1';
VetorHabilita <= to_unsigned(33,n);
end estrutural;