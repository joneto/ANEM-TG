-------------------------------------------------------------------------------
-- Title      : Memoria Ram
-- Project    : 
-------------------------------------------------------------------------------
-- File       : controladorRAM.vhd
-- Author     : Geraldo Filho / José Neto
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.std_logic_textio.all;
use STD.textio.all;


entity RamPerifController is
    generic(   n             :natural:=16;
               w             :natural:=32;
               EndAltoM      :natural:=16#FFCF#; -- memoria ram termina em FFCF
               EndBaixoP     :natural:=16#FFD0#); -- memoria de perifericos começa em FFD0
    port(    clk                    :in std_logic;
             rst                    :in std_logic;
             we                     :in std_logic;
             rd                     :in std_logic;
             Endereco               :in unsigned(n-1 downto 0);
             Din                    :in unsigned(n-1 downto 0);
             Dout                   :out unsigned(n-1 downto 0);
             DesInt                 :in std_logic;
             HabInt                 :in std_logic;
             Interrupt              :out std_logic;
             IntException           :out std_logic;
             IntEnd                 :out unsigned(n-1 downto 0);
             IntEnCo                :out std_logic;
             IntEnOv                :out std_logic;
             ExceptionCarry         :in std_logic;
             ExceptionOvr           :in std_logic;
             PortaA                 :in unsigned(n-1 downto 0);
             PortaB                 :out unsigned(n-1 downto 0);
             PortaC                 :out unsigned(n-1 downto 0);
             PortaD                 :out unsigned(n-1 downto 0);
             PortaE                 :out unsigned(n-1 downto 0);
             DAnemToSRAM            :out std_logic_vector(15 downto 0);  -- dados para SRAM
             DAnemFromSRAM          :in  std_logic_vector(15 downto 0);  -- dados da SRAM
             DAnemSRAMAddr          :out std_logic_vector(15 downto 0);  -- endereco da SRAM
             AnemSRAMWe             :out   std_logic;  -- controles da SRAM
             UART_TXD               :out std_logic;
             UART_RXD               :in  std_logic;
             PortaLCD               :out unsigned(n-1 downto 0);
             SinalDeTestes          :out std_logic_vector(n-1 downto 0);
             FPUStatusWe            :out std_logic;
             FPUStatusReg_FPUToAnem :in std_logic_vector(n-1 downto 0);
             FPUStatusReg_AnemToFPU :out std_logic_vector(n-1 downto 0);
             RegFPUAddr             :out std_logic_vector(n-1 downto 0);
             MemoryBank             :out std_logic_vector(1 downto 0);
             SRAMAddrFromPerif      :out std_logic_vector(n-1 downto 0); -- vem de um registrador periferico do anem que indica um endereco da memoria sram principal (que funciona como ponte de comunicacao entre os fpus
             CopAddrFromPerif       :out std_logic_vector(n-1 downto 0);
             MemSyncMode            :out std_logic_vector(n-1 downto 0);
             FinishedMemSync        :in std_logic;
             MemSyncModeWe          :out std_logic);
end RamPerifController;

architecture pldp of RamPerifController is

signal    RamWe,PerWe   :std_logic;
signal    RamDout,PerDout       :unsigned(n-1 downto 0);    

begin
    
 
    
    PERIFERICOS: entity work.perifericos(simples)
            generic map(n,w,EndBaixoP,16#FFFF#) port map(clk,rst,PerWe,rd,Endereco,Din,PerDout,DesInt,HabInt,IntEnCo,
                                                IntEnOv,ExceptionCarry,ExceptionOvr,Interrupt,IntException,IntEnd,PortaA,
                                                PortaB,PortaC,PortaD,PortaE,UART_TXD,UART_RXD,PortaLCD,SinalDeTestes,                                    
                                                FPUStatusWe,FPUStatusReg_FPUToAnem,FPUStatusReg_AnemToFPU,RegFPUAddr,MemoryBank,
                                                SRAMAddrFromPerif,CopAddrFromPerif,MemSyncMode,FinishedMemSync,MemSyncModeWe);
    
    AnemSRAMWe <= RamWe;
    DAnemToSRAM <= std_logic_vector(Din);
    DAnemSRAMAddr <= std_logic_vector(Endereco);
    
    process(Endereco,we,RamDout,PerDout,DAnemFromSRAM)
    begin
        if to_integer(Endereco) < EndAltoM+1 then 
            RamWe <= we;
            Dout <= unsigned(DAnemFromSRAM);
            PerWe <= '0';
        elsif to_integer(Endereco) > EndBaixoP-1 then
            RamWe <= '0';
            Dout <= PerDout;
            PerWe <= we;
      else
            RamWe <= '0';
            PerWe <= '0';
            Dout <= (others=>'0');
        end if;
    end process;
    
end pldp;
