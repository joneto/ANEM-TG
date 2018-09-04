-------------------------------------------------------------------------------
-- Title      : Controle das Interrupcoes
-- Project    : 
-------------------------------------------------------------------------------
-- File       : interrupcoes.vhd
-- Author     : Jose Rodrigues
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity interrupcoes is
 Generic (n :natural := 16);
 Port(
      clk             :in std_logic;
      rst             :in std_logic;
      we              :in std_logic;
      jal             :in std_logic;                  -- ocorreu um jal;
      hab             :in std_logic;                  -- habilita as interrupcoes;   
      VetorInterrup   :in unsigned(n-1 downto 0);     -- OBS1;
      VetorHabilita   :in unsigned(n-1 downto 0);     -- OBS2;
      RegHab          :inout unsigned(n-1 downto 0);  -- indica as interrupcoes que estao habilitadas no programa utilizado;
      pulo            :buffer std_logic;                 -- manda o processador fazer um jal;
      InstrucInterrup :buffer unsigned(n-1 downto 0);    -- instrucao a ser mandada no para o pipeline;
      IntEnCo, IntEnOv,OcorreuOvCo:out std_logic                  -- mandam ao controle a indicacao que overflow e carryout estao habilitados ou nao
     );
end entity;

--OBS1:Vetor indicando que interrupcao foi gerada:
--     VetorInterrupcao(0) : overflow
--     VetorInterrupcao(1) : carry out
--     VetorInterrupcao(2) : RXIF; 
--     VetorInterrupcao(3) : TXIF;
--     VetorInterrupcao(4) : WRIF;
--     VetorInterrupcao(5) : timer0;
--     VetorInterrupcao(6) : timer1;
--     VetorInterrupcao(7) : timer32;
--     VetorInterrupcao(8) :
--     VetorInterrupcao(9) :
--     VetorInterrupcao(10):
--     VetorInterrupcao(11):
--     VetorInterrupcao(12):
--     VetorInterrupcao(13):
--     VetorInterrupcao(14):
--     VetorInterrupcao(15):
--OBS2:Vetor pra carregar em RegHab que indica que interrupcoes estao habilitadas;

Architecture estrutura of interrupcoes is

Signal RegAtual,int_and_hab   :unsigned(n-1 downto 0); -- indica as interrupcoes que estao no momento setadas; 
Signal ocorreu   :std_logic;              -- indica que ocorreu uma interrupcao que sera tratada;
Signal EndBanco,EndBanco2, EndBanco3,p  :natural range 0 to n-1 ;-- indica o endereco do banco onde esta o pulo para a dada interrupcao;
Signal HabBanco   :std_logic;              -- habilita do banco;
Type state is (Habilitado, Pular, Desabilitado);
Signal estado     :state;
Signal ene,en1,en2 :std_logic := '0';
Begin
  
 RegInterrup:
 entity work.int_reg
   generic map (n) port map (clk,rst,ene, int_and_hab,p,RegAtual);

 with estado select  
 en1 <= '1' when Pular,
        '0' when Habilitado|Desabilitado;
 p <= EndBanco3;
   
 RegHabilita:
 entity work.uregistrador
   generic map (n) port map (clk,rst,we,VetorHabilita,RegHab); 
 
 BancoDeInterrupcoes:
 entity work.BancoInterrup
 generic map (n) port map (HabBanco,EndBanco2,InstrucInterrup);

atrasaEndBanco: process(clk,rst)
begin
    if rst='0' then
      EndBanco2 <= 0;
      EndBanco3 <= 0;
    elsif rising_edge(clk) then
      EndBanco3 <= EndBanco2;
		EndBanco2 <= EndBanco;
		ene <= en2;
		en2 <= en1;
    end if;
end process atrasaEndBanco;


 int_and_hab <= RegHab AND VetorInterrup; --Vetor indicando que interrupcoes que ocorreram e estao habilitadas
 EndBanco	<= 0 when RegAtual(0) = '1' else
             1 when RegAtual(1) = '1' else
             2 when RegAtual(2) = '1' else
             3 when RegAtual(3) = '1' else
             4 when RegAtual(4) = '1' else
             5 when RegAtual(5) = '1' else
             6 when RegAtual(6) = '1' else
             7 when RegAtual(7) = '1' else
             8 when RegAtual(8) = '1' else
             9 when RegAtual(9) = '1' else
             10 when RegAtual(10) = '1' else
             11 when RegAtual(11) = '1' else
             12 when RegAtual(12) = '1' else
             13 when RegAtual(13) = '1' else
             14 when RegAtual(14) = '1' else
             15;
ocorreu <= '1' when EndBanco /= 15 or RegAtual(15) = '1' else '0';
 
--Combinacional: Process(RegAtual,RegHab)
--        Variable Interrup    :unsigned(n-1 downto 0) :=(others=>'0');
--        Variable temp        :std_logic;                             
--Begin
--               Interrup := RegHab AND RegAtual; --Vetor indicando que interrupcoes que ocorreram
--                                                --e estao habilitadas;
--               temp := '0';
--               prioridade: for i in 0 to n-1 loop
--                           if Interrup(i) = '1' then
--                             temp := '1';
--                             EndBanco <= i;
--                             EXIT;
--                           end if; 
--               end loop prioridade;
--               ocorreu <= temp;
--end process Combinacional;

MaquinaDeEstados: Process(clk,rst)
Begin
          if rst = '1' then
            if rising_edge(clk) then
             Case estado is
              when Habilitado => if jal = '1' then
                                   estado <= Desabilitado;
                                 elsif ocorreu = '1' then
                                   estado <= Pular;
                                 end if;  
                                         
              when Pular =>  estado <= Desabilitado; 
                                      
              when Desabilitado => if Hab = '1' then
                                     estado <= Habilitado;
                                   end if;
             end Case;                      
            end if;
            
          else -- rst ='0';
            estado <= Habilitado;
          end if;
end process MaquinaDeEstados;

--Definindo sinais nos estados:       
with estado select
  HabBanco <= '1' when Pular,
              '0' when Habilitado|Desabilitado;
with estado select
  pulo <= '1' when Pular,
          '0' when Habilitado|Desabilitado;
  OcorreuOvCo <= '1' when pulo = '1' AND ((InstrucInterrup(3 downto 0)="0000") OR (InstrucInterrup(3 downto 0)="0001")) else
                 '0';

IntEnOv <= RegHab(0);
IntEnCo <= RegHab(1);
end estrutura;
