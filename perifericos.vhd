-------------------------------------------------------------------------------
-- Title      : Perifericos
-- Project    : 
-------------------------------------------------------------------------------
-- File       : perifericos.vhd
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
--ram ram
entity perifericos is
    generic(n                      :natural:=16;
            w                      :natural:=32;       -- tamanho do buffer da porta UART
            EndBaixo               :natural:=16#FFD0#; -- primeiro endereco dos perifericos
            EndAltoP               :natural:=16#FFFF#;
            --Interrupcoes
            EndVetorHabInterrupt   :natural:=16#FFD0#; -- 488
            --Portas A, B e C
            EndPortaA              :natural:=16#FFD1#; -- 489
            EndPortaARegZ          :natural:=16#FFD2#; -- 490
            EndPortaARegInt        :natural:=16#FFD3#; -- 491
            EndPortaB              :natural:=16#FFD4#; -- 492
            EndPortaBRegZ          :natural:=16#FFD5#; -- 493
            EndPortaBRegInt        :natural:=16#FFD6#; -- 494
            EndPortaC              :natural:=16#FFD7#; -- 495 --
            EndPortaCRegZ          :natural:=16#FFD8#; -- 496
            EndPortaCRegInt        :natural:=16#FFD9#; -- 497
            --USART
            EndRegTXData           :natural:=16#FFDA#; -- 498
            EndRegRXData           :natural:=16#FFDB#; -- 499
            EndRegUARTCfg          :natural:=16#FFDC#; -- 500
            EndRegUARTBaud         :natural:=16#FFDD#; -- 501
            --LCD
            EndPortaLCD            :natural:=16#FFDE#; -- 502
            --Portas D e E
            EndPortaD              :natural:=16#FFDF#; -- 503 --
            EndPortaDRegZ          :natural:=16#FFE0#; -- 504
            EndPortaDRegInt        :natural:=16#FFE1#; -- 505
            EndPortaE              :natural:=16#FFE2#; -- 506
            EndPortaERegZ          :natural:=16#FFE3#; -- 507
            EndPortaERegInt        :natural:=16#FFE4#; -- 508
            --Timer:
            EndRegConfig           :natural:=16#FFE5#; -- 509
            EndRegParada0          :natural:=16#FFE6#; -- 510
            EndRegParada1          :natural:=16#FFE7#; -- 511
            EndTimer0              :natural:=16#FFE8#; -- 512 --
            EndTimer1              :natural:=16#FFE9#; -- 513
            --Mac
            EndRegMacA0            :natural:=16#FFEA#; -- 514
            EndRegMacA1            :natural:=16#FFEB#; -- 515
            EndRegMacBu            :natural:=16#FFEC#; -- 516
            EndRegMacBs            :natural:=16#FFED#; -- 517
            EndRegMacC             :natural:=16#FFEE#; -- 518
            --FPU
            EndRegFPUStatus        :natural:=16#FFEF#; -- 519
            EndRegFPUSelect        :natural:=16#FFF0#; -- 520
            EndRegCopAddrAddr      :natural:=16#FFF1#; -- 521
            EndRegSRAMAddrAddr     :natural:=16#FFF2#; -- 522
            EndRegMemSyncMode      :natural:=16#FFF3#; -- 523
            --Memory Bank
            EndRegMemoryBank       :natural:=16#FFF4#  -- 524
);
    
    port(    clk,rst,we,read             :in std_logic;
            Endereco                          :in unsigned(n-1 downto 0);
            Din                                :in unsigned(n-1 downto 0);
             Dout                            :out unsigned(n-1 downto 0);
            DesInt,HabInt                 :in std_logic;
            IntEnCo,IntEnOv               :out std_logic;
            ExceptionCarry                :in std_logic;
            ExceptionOvr                  :in std_logic;
            Interrupt                     :out std_logic;
      IntException                  :out std_logic;
            IntEnd                        :out unsigned(n-1 downto 0);
            PortaA                        :in unsigned(n-1 downto 0);
            PortaB,PortaC,PortaD, PortaE  :out unsigned(n-1 downto 0);
            UART_TXD                           :out std_logic;
            UART_RXD                           :in std_logic;
            PortaLCD                      :out unsigned(n-1 downto 0);
      SinalDeTestes                 :out std_logic_vector(n-1 downto 0);
      FPUStatusWe            :out std_logic;
      FPUStatusReg_FPUToAnem :in std_logic_vector(n-1 downto 0);
      FPUStatusReg_AnemToFPU :out std_logic_vector(n-1 downto 0);
      RegFPUAddr                        :out std_logic_vector(n-1 downto 0);
      MemoryBank            :out std_logic_vector(1 downto 0);
      SRAMAddrFromPerif            :out std_logic_vector(n-1 downto 0); -- vem de um registrador periferico do anem que indica um endereco da memoria sram principal (que funciona como ponte de comunicacao entre os fpus
      CopAddrFromPerif            :out std_logic_vector(n-1 downto 0);
      MemSyncMode                :out std_logic_vector(n-1 downto 0);
      FinishedMemSync        :in std_logic;
      MemSyncModeWe            :out std_logic);
end perifericos;

architecture simples of perifericos is
    type Registradores is array (EndAltoP downto EndBaixo) of unsigned(n-1 downto 0);
        signal RegPeriferico  :Registradores;
    
        signal notclk :std_logic;
    
    --sinais da unidade de interrupcoes:
    signal VetorInterrupt :unsigned(n-1 downto 0);
    signal IntWe          :std_logic;
    
    --sinais do barramento digital:
    signal PortaAWe,PortaBWe,PortaCWe,PortaDWe,PortaEWe :std_logic;
    signal PortaLCDWe                 :std_logic;
    signal PAint_taken,PAsend_int     :std_logic;
    signal PAbarIO                    :unsigned(n-1 downto 0);
    signal PAsel                      :unsigned(2 downto 0);
    signal PBint_taken,PBsend_int     :std_logic;
    signal PBbarIO                    :unsigned(n-1 downto 0);
    signal PBsel                      :unsigned(2 downto 0);
    signal PCint_taken,PCsend_int     :std_logic;
    signal PCbarIO                    :unsigned(n-1 downto 0);
    signal PCsel                      :unsigned(2 downto 0);
    
    --sinais da UART:
    signal push,pop,RegCfgWe,BaudRegWe                              :std_logic;
    signal RegTXIn,RegRXOut,RegCfgIn,RegCfgOut,BaudRegIn,BaudRegOut :unsigned(n-1 downto 0);
    signal WRIF,RXIF,TXIF :std_logic := '1';
    
    --sinais do Timer:
    Signal Tconfig                             :unsigned(n-1 downto 0);
        Signal entc                                :std_logic;
        Signal ent0, ent1                          :std_logic;
        Signal timer0, timer1                      :unsigned(n-1 downto 0);
        Signal int_timer0, int_timer1, int_timer32,OcorreuOvCo :std_logic;

    --sinais do MAC:
    signal A0Out,A1Out    :unsigned(n-1 downto 0);
    signal A0WeExt,A1WeExt,BuWe,BsWe,CWe    :std_logic;
    signal MACReady    :std_logic;
    
    -- sinais do memory bank
    signal MemoryBankWe :std_logic;
    signal RegMemoryBank :unsigned(n-1 downto 0);
    
    -- sinais do coprocessador
    signal FPUAddrWe    :std_logic;
                     
    signal SyncModeWe,CopAddrWe,SRAMAddrWe    :std_logic;    
    signal SyncModeOutput                                        :unsigned(n-1 downto 0);


begin


    
    Dout <= RegPeriferico(to_integer(Endereco)) when (to_integer(Endereco) > EndBaixo-1) and (to_integer(Endereco) < EndAltoP) else
                (others=>'Z');
    
    notclk <= not clk;

---
------
---------
------------
---------------
--- Perifericos: ---



--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
----------------------- INTERRUPCOES -----------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--
  
    Interrupcoes: entity work.interrupcoes
            generic map(n) port map(clk,rst,IntWe,DesInt,HabInt,VetorInterrupt,Din,RegPeriferico(EndVetorHabInterrupt),Interrupt,IntEnd,IntEnCo,IntEnOv,OcorreuOvCo);
        VetorInterrupt(0) <= ExceptionOvr;
        VetorInterrupt(1) <= ExceptionCarry;
        VetorInterrupt(2) <= RXIF; 
        VetorInterrupt(3) <= TXIF;
        VetorInterrupt(4) <= WRIF;
        VetorInterrupt(5) <= int_timer0;
    VetorInterrupt(6) <= int_timer1;
    VetorInterrupt(7) <= int_timer32;
        VetorInterrupt(8) <= MACReady;    
       VetorInterrupt(15 downto 9) <= (others=>'0'); 
        IntWe <= we  when Endereco = to_unsigned(EndVetorHabInterrupt,n) else
             '0';
    SinalDeTestes <=  std_logic_vector(VetorInterrupt); 

    IntException <= OcorreuOvCo;


--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
------------------- BARRAMENTO DIGITAL ---------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--
  
    -- PortaA: provisoriamente fixa como entrada
    
    
    RegPeriferico(EndPortaA) <= PortaA;

    -- PortaB: provisoriamente fixa como saida
    
    RegPortaB:  entity work.uregistrador
         generic map(n) port map(clk,rst,PortaBWe,Din,RegPeriferico(EndPortaB));
    PortaBWe <= we when (Endereco = to_unsigned(EndPortaB,n)) else
                '0';
    PortaB <= RegPeriferico(EndPortaB);
                 
    -- PortaC: provisoriamente fixa como saida
   
 
    RegPortaC:  entity work.uregistrador
         generic map(n) port map(clk,rst,PortaCWe,Din,RegPeriferico(EndPortaC));
    PortaCWe <= we when (Endereco = to_unsigned(EndPortaC,n)) else
                '0';
    PortaC <= RegPeriferico(EndPortaC);
     
      -- PortaD: provisoriamente fixa como saida
   
 
    RegPortaD:  entity work.uregistrador
         generic map(n) port map(clk,rst,PortaDWe,Din,RegPeriferico(EndPortaD));
    PortaDWe <= we when (Endereco = to_unsigned(EndPortaD,n)) else
                '0';
    PortaD <= RegPeriferico(EndPortaD);
     
    -- PortaE: provisoriamente fixa como saida
   
 
    RegPortaE:  entity work.uregistrador
         generic map(n) port map(clk,rst,PortaEWe,Din,RegPeriferico(EndPortaE));
    PortaEWe <= we when (Endereco = to_unsigned(EndPortaE,n)) else
                '0';
    PortaE <= RegPeriferico(EndPortaE);
    
     -- PortaLCD: provisoriamente fixa como saida
   
 
    RegPortaLCD:  entity work.uregistrador
         generic map(n) port map(clk,rst,PortaLCDWe,Din,RegPeriferico(EndPortaLCD));
    PortaLCDWe <= we when (Endereco = to_unsigned(EndPortaLCD,n)) else
                '0';
    PortaLCD <= RegPeriferico(EndPortaLCD);
    

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
--------------------- UART EIA 232 -------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--
  
  UART: entity work.UsartRS232
    generic map(n,w) port map(clk,rst,push,pop,Din,RegRXOut,RegCfgWe,Din,RegCfgOut,BaudRegWe,Din,BaudRegOut,UART_TXD,UART_RXD);
  push <= we when (Endereco = to_unsigned(EndRegTXData,n)) else
          '0';
  pop <= read when (Endereco = to_unsigned(EndRegRXData,n)) else
          '0';
  RegCfgWe <= we when (Endereco = to_unsigned(EndRegUARTCfg,n)) else
              '0';
  BaudRegWe <= we when (Endereco = to_unsigned(EndRegUARTBaud,n)) else
              '0';
  RegPeriferico(EndRegUARTCfg) <= RegCfgOut;
  RegPeriferico(EndRegUARTBaud)<= BaudRegOut;
  RegPeriferico(EndRegRXData)  <= RegRXOut;
  WRIF <= RegCfgOut(0);
  TXIF <= RegCfgOut(5);
  RXIF <= RegCfgOut(6);

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
-------------------------- TIMER ---------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--

Temporizador: entity work.timer
    Generic map (n) Port map(clk, rst, Din, entc, Din, Din, ent0, ent1, timer0, timer1,int_timer0, int_timer1, int_timer32); 

  
  entc <= we when (Endereco = to_unsigned(EndRegConfig,n)) else
          '0'; 
  ent0 <= we when (Endereco = to_unsigned(EndRegParada0,n)) else
          '0';
  ent1 <= we when (Endereco = to_unsigned(EndRegParada1,n)) else
          '0'; 
  RegPeriferico(EndTimer0) <= timer0;
  RegPeriferico(EndTimer1) <= timer1;

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
--------------------------- MAC ----------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--

MultiplicaAcumula: entity work.mac
    generic map(n,1) port map(clk,rst,Din,BuWe,BsWe,Din,CWe,Din,Din,A0Out,A1Out,A0WeExt,A1WeExt,MACReady);

    BuWe <= we when (Endereco = to_unsigned(EndRegMacBu,n)) else
                    '0';
    BsWe <= we when (Endereco = to_unsigned(EndRegMacBs,n)) else
                    '0';
    CWe <= we when (Endereco = to_unsigned(EndRegMacC,n)) else
                    '0';
    A0WeExt <= we when (Endereco = to_unsigned(EndRegMacA0,n)) else
                    '0';
    A1WeExt <= we when (Endereco = to_unsigned(EndRegMacA1,n)) else
                    '0';
    RegPeriferico(EndRegMacA0) <= A0Out;
    RegPeriferico(EndRegMacA1) <= A1Out;

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
--------------------- COPROCESSADOR ------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--

    FPUStatusWe <= we when (Endereco = to_unsigned(EndRegFPUStatus,n)) else
                   '0';
  RegPeriferico(EndRegFPUStatus) <= unsigned(FPUStatusReg_FPUToAnem);
  FPUStatusReg_AnemToFPU <= std_logic_vector(Din);

    FPUSelect:  entity work.uregistrador
         generic map(n) port map(clk,rst,FPUAddrWe,Din,RegPeriferico(EndRegFPUSelect));   
    
    FPUAddrWe <= we when (Endereco = to_unsigned(EndRegFPUSelect,n)) else
                                '0';
    RegFPUAddr <= std_logic_vector(RegPeriferico(EndRegFPUSelect));

            
        RegCopAddr:  entity work.uregistrador
         generic map(n) port map(clk,rst,CopAddrWe,Din,RegPeriferico(EndRegCopAddrAddr));
      CopAddrWe <= we when (Endereco = to_unsigned(EndRegCopAddrAddr,n)) else
                                 '0';
        CopAddrFromPerif <= std_logic_vector(RegPeriferico(EndRegCopAddrAddr));
        
        RegSRAMAddr:  entity work.uregistrador
         generic map(n) port map(clk,rst,SRAMAddrWe,Din,RegPeriferico(EndRegSRAMAddrAddr));
      SRAMAddrWe <= we when (Endereco = to_unsigned(EndRegSRAMAddrAddr,n)) else
                                 '0';
        SRAMAddrFromPerif <= std_logic_vector(RegPeriferico(EndRegSRAMAddrAddr));
        
        RegMemSyncMode:  entity work.uregistrador
         generic map(n) port map(clk,rst,SyncModeWe,Din,SyncModeOutput);
      SyncModeWe <= we when (Endereco = to_unsigned(EndRegMemSyncMode,n)) else
                                 '0';
        MemSyncModeWe <= SyncModeWe;
        MemSyncMode <= std_logic_vector(SyncModeOutput);
        RegPeriferico(EndRegMemSyncMode) <= FinishedMemSync & SyncModeOutput(n-2 downto 0);
        

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
---------------------- MEMORYBANK --------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--

    BancoDeMem:  entity work.uregistrador
         generic map(n) port map(clk,rst,MemoryBankWe,Din,RegPeriferico(EndRegMemoryBank));   
    
    MemoryBankWe <= we when (Endereco = to_unsigned(EndRegMemoryBank,n)) else
                    '0';
    RegMemoryBank <= RegPeriferico(EndRegMemoryBank);
    MemoryBank <= std_logic_vector(RegMemoryBank(1 downto 0));

---------------
------------
---------
------
---
      
end simples;
