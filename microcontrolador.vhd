-------------------------------------------------------------------------------
-- Title      : Microcontrolador de 16 bits
-- Project    : 
-------------------------------------------------------------------------------
-- File       : microcontrolador.vhd
-- Author     : Geraldo Filho / José Neto
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Top level
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity microcontrolador is
generic(  n         :natural:=16; -- numero de bits em uma palavra
          w         :natural:=256; -- tamanho do buffer da UART
          m         :natural:=16; -- numero de bits para enderecar a ram
          r         :natural:=13; -- numero de bits para enderecar a rom
          baudreg   :natural:=4167; --(para 40Mhz) ou 5208; (para 50Mhz) -- 9600 bps para o programador
          clk_freq  :natural:=40;
          ser_freq  :natural:=9600;
          cachesize :natural:=2048; -- tamanho da memoria cache disponivel para cada coprocessador
          EndAltoM  :natural:=16#FFCF#;
          EndBaixoP :natural:=16#FFD0#;
          floatnf   :natural:=4; -- qtd de coprocessadores em paralelo, cada processador e endereçado por um bit
          floatr    :natural:=8; -- qtd de bits para enderecar os registradores no stack dos coprocessadores
          floatrqtd :natural:=256; -- qtd de registradores no stack dos coprocessadores
          floatm    :natural:=64); -- largura dos barramentos de ponto flutuante);
port(
    CLOCK_27,CLOCK_50,EXT_CLOCK               :in std_logic;  -- clocks
    KEY                                       :in std_logic_vector(3 downto 0);   -- botões
    SW                                        :in std_logic_vector(17 downto 0);  -- chaves
    HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7   :out std_logic_vector(6 downto 0);  -- display hexa 7
    LEDG                                      :out std_logic_vector(8 downto 0);  -- leds verdes
    LEDR                                      :out std_logic_vector(17 downto 0);  -- leds vermelhos
    UART_TXD                                  :out std_logic;
    UART_RXD                                  :in std_logic;
    FL_DQ                                     :inout std_logic_vector(7 downto 0);  -- dados da memória flash
    FL_ADDR                                   :out std_logic_vector(21 downto 0);  -- endereço da memória flash
    FL_WE_N,FL_Rst_N,FL_OE_N,FL_CE_N          :out std_logic;  -- controles da memória flash
    SRAM_DQ                                   :inout std_logic_vector(15 downto 0);  -- dados da SRAM
    SRAM_ADDR                                 :out   std_logic_vector(17 downto 0);  -- endereço da SRAM
    SRAM_UB_N, SRAM_LB_N, SRAM_WE_N, SRAM_CE_N, SRAM_OE_N :out   std_logic;  -- controles da SRAM
    LCD_DATA                                              :inout std_logic_vector(7 downto 0);  -- dados do módulo LCD
    LCD_ON, LCD_BLON, LCD_RW, LCD_RS, LCD_EN              :out   std_logic;  -- controles do módulo LCD
    GPIO_0, GPIO_1                                        :inout std_logic_vector(35 downto 0)  -- GPIO
);
end entity microcontrolador;

architecture modelo of microcontrolador is
    signal RomAddr                :unsigned(n-1 downto 0);
    signal Instruction            :std_logic_vector(n-1 downto 0);
    signal RamAddr_AnemToControl  :unsigned(n-1 downto 0);
    signal RamD_ControlToAnem     :unsigned(n-1 downto 0);
    signal RamD_AnemToControl     :unsigned(n-1 downto 0);
    signal RamWe_AnemToControl,RamRd_AnemToControl,RomClk,Clk,Rst :std_logic;
    signal DesInt,HabInt       :std_logic;
    signal Interrupt           :std_logic;
    signal IntEnd              :unsigned(n-1 downto 0);
    signal ExceptionCarry      :std_logic;
    signal ExceptionOvr        :std_logic;
    signal IntEnCo,IntEnOv     :std_logic;
    signal ArithInstruction    :unsigned(n-1 downto 0);
    signal PushArithInst       :std_logic;
    signal RamWe_FPUToSRAM     :std_logic;
    signal RamRd_FPUToSRAM     :std_logic;
    signal RamAddr_FPUToSRAM   :std_logic_vector(n-1 downto 0);
    signal RamD_FPUToSRAM      :std_logic_vector(n-1 downto 0);
    signal RamD_SRAMToFPU      :std_logic_vector(n-1 downto 0);
    signal SRAM_IsBusyWithAnem :std_logic; -- pode ser encarado como um "cache miss" para o coprocessador
    signal FPUStatusWe         :std_logic;
    signal FPUStatusReg_FPUToAnem :std_logic_vector(n-1 downto 0);
    signal FPUStatusReg_AnemToFPU :std_logic_vector(n-1 downto 0);
    signal MemoryBank        :std_logic_vector(1 downto 0);
    signal FPUBusy           :std_logic;
    signal FPUImediato16     :unsigned(n-1 downto 0);
    signal PortaA,PortaB,PortaC,PortaD,PortaE   :unsigned(n-1 downto 0);
    signal PortaLCD          :unsigned(n-1 downto 0);
    signal notRst,notProg    :std_logic;
    signal RamD_AnemToSRAM   :std_logic_vector(n-1 downto 0);  -- dados para SRAM
    signal RamD_SRAMToAnem   :std_logic_vector(n-1 downto 0);  -- dados da SRAM
    signal RamAddr_AnemToSRAM:std_logic_vector(n-1 downto 0);  -- endereco da SRAM
    signal RamWe_AnemToSRAM  :std_logic;  -- controles da SRAM
    signal RamRd_AnemToSRAM  :std_logic;
    signal SinalDeTestes     :std_logic_vector(n-1 downto 0):=(others=>'0');
    signal RegSinalDeTestes,EntradaDoReg :std_logic_vector(n-1 downto 0);
    signal IntException      :std_logic;
    signal ProcessorRst,Prog :std_logic;
    
    signal progaddr           :unsigned(r-1 downto 0);
    signal progdata           :unsigned(n-1 downto 0);
    signal ProgRegCfgOut      :unsigned(n-1 downto 0);
    signal HexDisplayAData    :unsigned(n-1 downto 0);
    signal HexDisplayBData    :unsigned(n-1 downto 0);
    signal UART_TXD_Anem,UART_TXD_Prog :std_logic;
    signal Counter            :integer range 0 to 3;    
    signal uCounter           :unsigned (1 downto 0);
    
    signal RegFPUAddr         :std_logic_vector(n-1 downto 0);
    
    signal SRAMAddrFromPerif  :std_logic_vector(n-1 downto 0):=(others=>'0'); -- vem de um registrador periferico do anem que indica um endereco da memoria sram principal (que funciona como ponte de comunicacao entre os fpus
    signal CopAddrFromPerif   :std_logic_vector(n-1 downto 0):=(others=>'0');
    signal MemSyncMode        :std_logic_vector(n-1 downto 0);
    signal MemSyncModeWe      :std_logic;
    signal FinishedMemSync    :std_logic;
        
        
begin
    
    --PhaseLockedLoop: entity work.PLL50_40
    --                port map(inclk0 => CLOCK_50,
    --                         c0     => Clk);

    Clk <= CLOCK_50;
    
    Rst  <= SW(17);
    Prog <= SW(16);
    notProg <= NOT Prog;
    notRst <= NOT Rst;
    ProcessorRst <= Rst and (not Prog);        
    
    
    PROCESSADOR: entity work.anem16(pipeline)
        generic map(n         => n,
                    m         => m,
                    EndAltoM  => EndAltoM,
                    EndBaixoP => EndBaixoP) 
        port map(clk             => Clk,
                 rst             => ProcessorRst,
                 inst_end        => RomAddr,
                 inst_in         => unsigned(Instruction),
                 data_end        => RamAddr_AnemToControl,
                 data_out        => RamD_AnemToControl,
                 data_in         => RamD_ControlToAnem,
                 data_w          => RamWe_AnemToControl,
                 data_read       => RamRd_AnemToControl,
                 DesInt          => DesInt,
                 HabInt          => HabInt,
                 Interrupt       => Interrupt,
                 IntException    => IntException,
                 IntEnd          => IntEnd,
                 IntEnCo         => IntEnCo,
                 IntEnOv         => IntEnOv,
                 ExceptionCarry  => ExceptionCarry,
                 ExceptionOvr    => ExceptionOvr,
                 InstructionOut  => ArithInstruction,
                 PushArithInst   => PushArithInst,
                 FPUBusy         => FPUBusy,
                 FPUImediato16   => FPUImediato16);
       
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
--------------------- PORTAS DE I/O ------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/-- 
    
    PortaA(15 downto 4)  <= unsigned(SW(15 downto 4));
    PortaA(3 downto 0)   <= not (unsigned(KEY));
    
    with Prog select
        HexDisplayAData <= PortaB when '0',
                           progdata when others;                                                   
    with Prog select
        HexDisplayBData <= PortaC when '0',
                           '0'&uCounter&progaddr when others;
                                                
    
    sete0: entity work.sete
        port map(HexDisplayAData(3 downto 0),HEX0);
    sete1: entity work.sete
        port map(HexDisplayAData(7 downto 4),HEX1);
    sete2: entity work.sete
        port map(HexDisplayAData(11 downto 8),HEX2);
    sete3: entity work.sete
        port map(HexDisplayAData(15 downto 12),HEX3);
    
    sete4: entity work.sete
        port map(HexDisplayBData(3 downto 0),HEX4);
    sete5: entity work.sete
        port map(HexDisplayBData(7 downto 4),HEX5);
    sete6: entity work.sete
        port map(HexDisplayBData(11 downto 8),HEX6);
    sete7: entity work.sete
        port map(HexDisplayBData(15 downto 12),HEX7);

    LEDR(15 downto 0) <= std_logic_vector(PortaD) when Prog='0' else
                         std_logic_vector(ProgRegCfgOut);

    PortaE(3 downto 0) <= not (unsigned(KEY));
    PortaE(15 downto 4) <= (others=>'0'); 
    
    UART_TXD <= UART_TXD_Anem when Prog = '0' else
                                UART_TXD_Prog;
    

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
------------------ MEMORIA DE PROGRAMA ---------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    

    RomClk <= not Clk;    
    
    romprogramavel: entity work.AnemProgrammerMuart2
        generic map(n       => n,
                    baudreg => baudreg,
                    clk_freq =>  clk_freq,
                    ser_freq =>  ser_freq,
                    r       => r)
        port map( clk         => Clk,
                  rst         => Prog,
                  Prog        => Prog,
                  address     => std_logic_vector(RomAddr(r-1 downto 0)),
                  q           => Instruction,
                  progaddr    => progaddr,
                  progdata    => progdata,
                  RegCfgOut   => ProgRegCfgOut,
                  Counter     => Counter,
                  UART_TXD    => UART_TXD_Prog,
                  UART_RXD    => UART_RXD);
    
    uCounter <= "00" when Counter=0 else
                "01" when Counter=1 else
                "10" when Counter=2 else
                "11";

--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
------------------ MEMORIA DE DADOS ------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
    
    ControladorDeMemoriaEPerifericos:   entity work.RamPerifController(pldp)
        generic map(n         => n,
                    w         => w,
                    EndAltoM  => EndAltoM,
                    EndBaixoP => EndBaixoP)
        port map ( clk                     => Clk,
                   rst                     => Rst,
                   we                      => RamWe_AnemToControl,
                   rd                      => RamRd_AnemToControl,
                   Endereco                => RamAddr_AnemToControl,
                   Din                     => RamD_AnemToControl,
                   Dout                    => RamD_ControlToAnem,
                   DesInt                  => DesInt,
                   HabInt                  => HabInt,
                   Interrupt               => Interrupt,
                   IntException            => IntException,
                   IntEnd                  => IntEnd,
                   IntEnCo                 => IntEnCo,
                   IntEnOv                 => IntEnOv,
                   ExceptionCarry          => ExceptionCarry,
                   ExceptionOvr            => ExceptionOvr,
                   PortaA                  => PortaA,
                   PortaB                  => PortaB,
                   PortaC                  => PortaC,
                   PortaD                  => PortaD,
                   PortaE                  => PortaE,
                   DAnemToSRAM             => RamD_AnemToSRAM,
                   DAnemFromSRAM           => RamD_SRAMToAnem,
                   DAnemSRAMAddr           => RamAddr_AnemToSRAM,
                   AnemSRAMWe              => RamWe_AnemToSRAM,
                   UART_TXD                => UART_TXD_Anem,
                   UART_RXD                => UART_RXD,
                   PortaLCD                => PortaLCD,
                   SinalDeTestes           => SinalDeTestes,
                   FPUStatusWe             => FPUStatusWe,
                   FPUStatusReg_FPUToAnem  => FPUStatusReg_FPUToAnem,
                   FPUStatusReg_AnemToFPU  => FPUStatusReg_AnemToFPU,
                   RegFPUAddr              => RegFPUAddr,
                   MemoryBank              => MemoryBank,
                   SRAMAddrFromPerif       => SRAMAddrFromPerif,
                   CopAddrFromPerif        => CopAddrFromPerif,
                   MemSyncMode             => MemSyncMode,
                   FinishedMemSync         => FinishedMemSync,
                   MemSyncModeWe           => MemSyncModeWe);
    
    ControladorDeSRAM: entity work.SRAMController
        generic map(n => n)
        port map( clk                 => Clk,
                  rst                 => Rst,
                  RamWe_AnemToSRAM    => RamWe_AnemToSRAM,
                  RamRd_AnemToSRAM    => RamRd_AnemToSRAM,
                  RamAddr_AnemToSRAM  => RamAddr_AnemToSRAM,
                  RamD_AnemToSRAM     => RamD_AnemToSRAM,
                  RamD_SRAMToAnem     => RamD_SRAMToAnem,
                  RamWe_FPUToSRAM     => RamWe_FPUToSRAM,
                  RamRd_FPUToSRAM     => RamRd_FPUToSRAM,
                  RamAddr_FPUToSRAM   => RamAddr_FPUToSRAM,
                  RamD_FPUToSRAM      => RamD_FPUToSRAM,
                  RamD_SRAMToFPU      => RamD_SRAMToFPU,
                  SRAM_IsBusyWithAnem => SRAM_IsBusyWithAnem,
                  SRAM_DQ             => SRAM_DQ,
                  SRAM_ADDR           => SRAM_ADDR(15 downto 0),
                  SRAM_WE_N           => SRAM_WE_N);
                    
    RamRd_AnemToSRAM <= RamRd_AnemToControl;
    
    SRAM_UB_N <= '0';
    SRAM_LB_N <= '0';
    SRAM_CE_N <= '0';
    SRAM_OE_N <= '0';
    SRAM_ADDR(17 downto 16) <= MemoryBank;

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
-------------------- DISPLAY LCD ---------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    

    LCDDriver: entity work.LCDDriver
      generic map(tickNum  => 500) port map(Clk,notRst,std_logic_vector(PortaLCD(7 downto 0)),std_logic_vector(PortaLCD(13 downto 8)),
                                            PortaLCD(14),LCD_DATA,LCD_RS,LCD_RW,LCD_EN);
    LCD_ON <= '1';
    LCD_BLON <= '0';
    
--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
--------------- COPROCESSADOR ARITMETICO -------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    
    
--    FPU: entity work.Coprocessador
--      port map(Clk,ProcessorRst,std_logic_vector(ArithInstruction),PushArithInst,std_logic_vector(FPUImediato16),RamD_SRAMToFPU,RamD_FPUToSRAM,RamAddr_FPUToSRAM,
--               RamWe_FPUToSRAM,RamRd_FPUToSRAM,SRAM_IsBusyWithAnem,FPUStatusReg_FPUToAnem);
    FPUBusy <= '0';
    RamWe_FPUToSRAM <= '0';
    RamRd_FPUToSRAM <= '0';
    FinishedMemSync <= '0';
--    FPUController: entity work.ParalellFPUController
--            generic map(n     => n,
--                        nf    => floatnf,
--                        r     => floatr,
--                        rqtd  => floatrqtd,
--                        asize => 11,
--                        m     => floatm)
--            port map( clk                 => Clk,
--                      rst                 => ProcessorRst,
--                      fpuselect           => RegFPUAddr(floatnf-1 downto 0),
--                      instruction         => std_logic_vector(ArithInstruction),
--                      pushinst            => PushArithInst,
--                      imediato16          => std_logic_vector(FPUImediato16),
--                      datain              => RamD_SRAMToFPU,
--                      dataout             => RamD_FPUToSRAM,
--                      ramaddr             => RamAddr_FPUToSRAM,
--                      ramwe               => RamWe_FPUToSRAM,
--                      ramrd               => RamRd_FPUToSRAM,
--                      cachemiss           => SRAM_IsBusyWithAnem,
--                      status              => FPUStatusReg_FPUToAnem,
--                      FPUBusy             => FPUBusy,
--                      SRAMAddrFromPerif   => SRAMAddrFromPerif,
--                      CopAddrFromPerif    => CopAddrFromPerif,
--                      MemSyncMode         => MemSyncMode,
--                      FinishedMemSync     => FinishedMemSync,
--                      MemSnifferWe        => RamWe_AnemToSRAM,
--                      MemSnifferData      => std_logic_vector(RamD_AnemToSRAM),
--                      MemSnifferAddress   => std_logic_vector(RamAddr_AnemToSRAM),
--                      MemSyncModeWe       => MemSyncModeWe);
                                

--/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\--
----------------- DEBUG DO HARDWARE ------------------------
--\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/--    

    -- Para testar alguns sinais internos dos perifericos e processador (pode ser comentado na versao final):
    EntradaDoReg(15)<= Interrupt when Prog='0' else
                       ProgRegCfgOut(8);
    EntradaDoReg(13 downto 0) <= std_logic_vector(SinalDeTestes(13 downto 0));
    EntradaDoReg(14)<=HabInt when Prog='0' else
                      ProgRegCfgOut(7);
    flipflops: process(clk,KEY(0))
    begin
        if(KEY(0)='0')then
            RegSinalDeTestes<=(others=>'0');
        elsif rising_edge(clk) then
            laco: for i in 0 to 15 loop
                if(RegSinalDeTestes(i)='0')then
                    RegSinalDeTestes(i)<=EntradaDoReg(i);
                end if;
            end loop laco;
        end if;
    end process flipflops;
    
    LEDG <= RegSinalDeTestes(8 downto 0);
    LEDR(17) <= RegSinalDeTestes(15);
    LEDR(16) <= RegSinalDeTestes(14);
    
  
end modelo;
