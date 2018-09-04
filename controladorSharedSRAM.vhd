-------------------------------------------------------------------------------
-- Title      : Controlador de Cache para Permitir o uso do Coprocessador
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ram.vhd
-- Author     : Geraldo
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.std_logic_textio.all;
use STD.textio.all;
--ram ram
entity SRAMController is
  generic( n          :natural:=16);
  port(clk                 :in  std_logic;
       rst                 :in  std_logic;
       RamWe_AnemToSRAM    :in  std_logic;
       RamRd_AnemToSRAM    :in  std_logic;
       RamAddr_AnemToSRAM  :in  std_logic_vector(n-1 downto 0);
       RamD_AnemToSRAM     :in  std_logic_vector(n-1 downto 0);
       RamD_SRAMToAnem     :out std_logic_vector(n-1 downto 0);
       RamWe_FPUToSRAM     :in  std_logic;
       RamRd_FPUToSRAM     :in  std_logic;
       RamAddr_FPUToSRAM   :in  std_logic_vector(n-1 downto 0);
       RamD_FPUToSRAM      :in  std_logic_vector(n-1 downto 0);
       RamD_SRAMToFPU      :out std_logic_vector(n-1 downto 0);
       SRAM_IsBusyWithAnem :out std_logic; -- pode ser encarado como um "cache miss" para o coprocessador
       SRAM_DQ             :inout   std_logic_vector(15 downto 0);  -- dados da SRAM
       SRAM_ADDR           :buffer  std_logic_vector(15 downto 0);  -- endereço da SRAM
       SRAM_WE_N           :buffer  std_logic  -- controles da SRAM
      );
end SRAMController;

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
---------- SRAM SENDO UTILIZADA PELO ANEM E FPU ------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/-- 

architecture compartilhada of SRAMController is
    signal WhoIsControlling               :std_logic; -- '0' = Anem | '1' = FPU
    signal AddressBusIsStable             :std_logic; -- '0' = Nao  | '1' = Sim (o endereco esta sendo fornecido pela unidade controladora)
    signal AddrBusWithAnem,AddrBusWithFPU :std_logic; -- '0' = Nao  | '1' = Sim
    signal RamD_Multiplexed,RamD_TriState                  :std_logic_vector(n-1 downto 0);
begin
    WhoIsControlling <= '1' when ((RamWe_FPUToSRAM='1')or(RamRd_FPUToSRAM='1'))and((RamWe_AnemToSRAM='0')and(RamRd_AnemToSRAM='0')) else -- a SRAM so pode ser controlada pela FPU quando o anem nao esta solicitando nenhuma operacao na mesma.
                        '0'; -- em todos os outros casos o controle eh do anem
    SRAM_IsBusyWithAnem <= RamWe_AnemToSRAM or RamRd_AnemToSRAM;
    RamD_Multiplexed <= RamD_AnemToSRAM when WhoIsControlling = '0' else
												RamD_FPUToSRAM;
    RamD_TriState <= RamD_Multiplexed when SRAM_WE_N='0' else
                     (others=>'Z');
    RamD_SRAMToAnem <= SRAM_DQ;
    RamD_SRAMToFPU <= SRAM_DQ;
 
    SRAM_DQ <= RamD_TriState;

    SRAM_ADDR <= RamAddr_AnemToSRAM when WhoIsControlling = '0' else
                 RamAddr_FPUToSRAM;
    AddrBusWithAnem <= '1' when SRAM_ADDR = RamAddr_AnemToSRAM else -- indica que as linhas de endereco da SRAM ja estao iguais as do anem
                       '0';
    AddrBusWithFPU  <= '1' when SRAM_ADDR = RamAddr_FPUToSRAM else -- indica que as linhas de endereco da SRAM ja estao iguais as do FPU
                       '0';

    SRAM_WE_N <= not RamWe_AnemToSRAM when ((WhoIsControlling = '0') and (AddrBusWithAnem='1')) else
                 not RamWe_FPUToSRAM  when ((WhoIsControlling = '1') and (AddrBusWithFPU='1')) else
                 '1'; -- nao altera os valores da SRAM as linhas de endereco nao estiverem ainda estaveis
    
end compartilhada;

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
---------- SRAM SENDO UTILIZADA APENAS PELO ANEM -----------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/-- 

--architecture simples of SRAMController is
--    signal RamD_AnemToSRAM_TriState  :std_logic_vector(n-1 downto 0);
--begin
--    RamD_AnemToSRAM_TriState <= RamD_AnemToSRAM when RamWe_AnemToSRAM='1' else
--                                (others=>'Z');
--    RamD_SRAMToAnem <= SRAM_DQ;
-- 
--    SRAM_DQ <= RamD_AnemToSRAM_TriState;
--
--    SRAM_ADDR <= RamAddr_AnemToSRAM;
--    
--    SRAM_WE_N <= not RamWe_AnemToSRAM;
--	
--end simples;

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
---------- DUAS RAMS INTERNAS REPARADAS P SIMULACAO --------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--

--architecture simulacao of SRAMController is
--   type ram_type is array(511 downto 0) of std_logic_vector(15 downto 0);
--   signal RAM : ram_type;
-- 
--begin
--   process (RamD_AnemToSRAM,RamAddr_AnemToSRAM,RamWe_AnemToSRAM)
--   begin
--      if (RamWe_AnemToSRAM='1') then
--        RAM(to_integer(unsigned(RamAddr_AnemToSRAM(8 downto 0)))) <= RamD_AnemToSRAM;
--      end if;
--   end process;
--   RamD_SRAMToAnem <= RAM(to_integer(unsigned(RamAddr_AnemToSRAM(8 downto 0))));
--
--		
--end simulacao;