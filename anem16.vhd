-------------------------------------------------------------------------------
-- Title      : Conexao de todas as entidades do processador
-- Project    : 
-------------------------------------------------------------------------------
-- File       : anem16.vhd
-- Author     : Geraldo Filho / José Neto
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity anem16 is
    generic(    n:natural:=16;
                m:natural:=5;
                EndAltoM     :natural:=16#FFD0#; -- memoria RAM termina em 0FD0 
                EndBaixoP    :natural:=16#FFD0#);-- memoria de perifericos começa em 0FD0);
    port(   clk             :in std_logic;
            rst             :in std_logic;
            inst_end        :out unsigned(n-1 downto 0);
            inst_in         :in unsigned(n-1 downto 0);
            data_end        :out unsigned(n-1 downto 0);
            data_out        :out unsigned(n-1 downto 0);
            data_in         :in unsigned(n-1 downto 0);
            data_w          :out std_logic;
            data_read       :out std_logic;
            DesInt          :out std_logic;
            HabInt          :out std_logic;
            Interrupt       :in std_logic;
            IntException    :in std_logic;
            IntEnd          :in unsigned(n-1 downto 0);
            IntEnCo         :in std_logic;
            IntEnOv         :in std_logic;
            ExceptionCarry  :buffer std_logic;
            ExceptionOvr    :buffer std_logic;
            InstructionOut  :out unsigned(n-1 downto 0);
            PushArithInst   :out std_logic;
            FPUBusy         :in std_logic;
            FPUImediato16   :out unsigned(n-1 downto 0)
         );
end entity anem16;

architecture pipeline of anem16 is

-- Sinais em IF:
    signal PCFuturo,PCValor,PCMais1,PCSalto,SaltoEnd,JREnd,JEnd :unsigned(n-1 downto 0);
    signal InstructionIF                                        :unsigned(n-1 downto 0);
    signal PCOp,Branch,Jump,Jal,JR,BEQ                          :std_logic;
    signal IFFlush,PCEnable,IFIDEnable                          :std_logic;
    
-- Sinais em ID:
    signal Instruction,PCMais1_ID,IntEnd_ID                 :unsigned(n-1 downto 0);
    signal ra_ID,rb_ID,raEnd,rb,ID,Opcode,WRegEnd,func_ID   :unsigned(3 downto 0);
    signal RFOp                                             :unsigned(1 downto 0);
    signal RFEnt8                                           :unsigned(7 downto 0);
    signal RFEnt16,RegA_ID,RegB_ID,Offset_ID                :unsigned(n-1 downto 0);
    signal Controle,DoJAL                                   :unsigned(8 downto 0);
    signal SinaldeControle_ID                               :unsigned(10 downto 0);
--    Obs:    SinaldeControle(1 downto 0) <= RfOp;
--            SinaldeControle(2) <= MemToReg;
--            SinaldeControle(5 downto 3) <= PCOp
--            SinaldeControle(6) <= WriteRam;
--            SinaldeControle(8 downto 7) <= UlaCtrl;
--            SinaldeControle(9) <= HabInt
--            SinaldeControle(10) <= DesInt
        signal PushArithInst_ID,IDEXEnable                                                :std_logic;
    signal StallID,StallEX,Link,Int_ID,Wait_ID,ExceptionJAL_ID:std_logic;
-- Sinais em EX:
    signal SinaldeControle_EX                                                           :unsigned(8 downto 0);
    signal BEQEnd_EX,PCMais1_EX,PCMais1_MEM,RegA_EX,RegB_EX,Offset_EX,UlaOut_EX,UlaA    :unsigned(n-1 downto 0);
    signal FUlaA,FUlaB,IntEnd_EX                                                        :unsigned(n-1 downto 0);
    signal Instruction_EX                                                               :unsigned(n-1 downto 0);
    signal UlaOp                                                                        :unsigned(4 downto 0);
    signal ra_EX,rb_EX                                                                  :unsigned(3 downto 0);
    signal UlaZero_EX,OpXOR,Int_EX,Ula_Cout,Ula_Ovr,Wait_EX,ExceptionJAL_EX             :std_logic;
    signal ForwardUlaA,ForwardUlaB                                                      :unsigned(1 downto 0);
    signal ForwardUpperUlaA,ForwardLowerUlaA,ForwardUpperUlaB,ForwardLowerUlaB          :unsigned(2 downto 0);
        signal PushArithInst_EX                                                                                                                            :std_logic;
    signal ExceptionProgramCounter                                                      :unsigned(n-1 downto 0);
    signal RegisteredFPUBusy                                                            :std_logic;

-- Sinais em MEM:
    signal RegA_MEM,UlaOut_MEM,RamDin_MEM             :unsigned(n-1 downto 0);
    signal SinaldeControle_MEM                        :unsigned(6 downto 0);
    signal Instruction_MEM                            :unsigned(11 downto 0);
    signal ForwardRamDin,ExceptionJAL_MEM              :std_logic;
    signal RFEnt8_MEM                                 :unsigned(7 downto 0);
        
-- Sinais em WB:
    signal WriteBackData,UlaOut_WB,FromRam,PCMais1_WB,RFEnt16_WB   :unsigned(n-1 downto 0);
    signal RFEnt8_WB                                               :unsigned(7 downto 0);
    signal RegEnd_WB                                               :unsigned(3 downto 0);
    signal SinaldeControle_WB                                      :unsigned(5 downto 0);
    signal Instruction_WB                                          :unsigned(11 downto 0);
    signal ExceptionJAL_WB                                         :std_logic; -- sinal necessario para diferenciar um JAL comum de um JAL de excecoes
    

begin

-- Instruction Fetch (IF):
    inst_end <= PCValor;

    PC:  entity work.uregistrador(comum)     
        generic map (n => n) port map (clk,rst,PcEnable,PCFuturo,PCValor); -- registrador PC
    
    with PCOp select
        PCFuturo <= PCMais1 when '0', -- simplesmente soma + 1
                    PCSalto when others; -- BEQ, J, JAL ou JR
    with Branch select
        PCSalto <=  BEQEnd_EX   when '1', -- BEQ verdadeiro
                    SaltoEnd     when others; -- J, JAL ou JR
    with (Jump OR Jal) select
        SaltoEnd <= JREnd   when '0', -- JR
                    JEnd    when others; -- J ou JAL
    
    SOMA1:  entity   work.mips_adder(fast_carry)
        port map (PCValor,to_unsigned(1,n),'0',OPEN,OPEN,PCMais1); -- soma mais 1 em PCValor
    
    with IFFlush select
        InstructionIF <= inst_in        when '0',
                         (others=>'0')  when others; -- representa uma instrucao nop: AND $0,$0
    PcEnable <= (IFFlush nor StallID) or PCOp; -- o pc nao devera estar habilitado nos stalls, exceto no segundo stall devido a um salto, quando ele precisara ser atualizado com o endereco de salto

-- Registrador IF/ID:
   
    IFID:   entity work.RegIFID(comum)
        generic map(n) port map(clk,rst,IFIDEnable,InstructionIF,PCMais1,Instruction,PCMais1_ID);
    IFIDEnable <= not StallID;

-- Instruction Decode (ID):

    ArquivoDeRegistradores: entity work.reg_file(pldp)
        generic map(n,4) port map(clk,rst,ra_ID,rb_ID,WRegEnd,RFOp,RFEnt16,RFEnt8,RegA_ID,RegB_ID);
    
    RFEnt16 <= PCMais1_WB               when (Link = '1') AND (ExceptionJAL_WB = '0') else
               ExceptionProgramCounter  when (Link = '1') AND (ExceptionJAL_WB = '1') else
               RFEnt16_WB;
    RFEnt8 <= RFEnt8_WB;               
    
    ra_ID <= Instruction(11 downto 8);
    rb_ID <= Instruction(7 downto 4);
    func_ID <= Instruction(3 downto 0);
    
    with Link select
        WRegEnd <=  to_unsigned(15,4) when '1',
                    RegEnd_WB         when others;
    
    Offset_ID(3 downto 0) <= func_ID;
    with func_ID(3) select
        Offset_ID(n-1 downto 4) <=  (others=>'0') when '0',
                                    (others=>'1') when others;
    
    UnidadeDeControle:      entity work.controle(pipeline)
        generic map(n) port map(Opcode,SinaldeControle_ID,PushArithInst_ID);

    Opcode <= Instruction(15 downto 12);

    HazardDetection: entity work.hazard_unit(pipeline)
            port map(PushArithInst_EX,RegisteredFPUBusy,ra_ID,rb_ID,Instruction_EX(11 downto 8),Opcode,Int_ID,SinaldeControle_EX(2),SinaldeControle_EX(5),ExceptionCarry,ExceptionOvr,IntEnCo,IntEnOv,Wait_EX,Wait_ID,StallID,IFFlush,StallEX);
            
    --Interrupcoes:
    DesInt <= SinaldeControle_ID(10);
    HabInt <= SinaldeControle_ID(9);
    Int_ID <= Interrupt;
    IntEnd_ID <= IntEnd;
    
    ExceptionJAL_ID <= '1' when Int_ID = '1' and IntException = '1' else
                       '0';

-- Registrador ID/EX:
    IDEXEnable <= not StallEX;
    IDEX:   entity work.RegIDEX(comum)
       generic map(n,9) port map(clk,rst,IDEXEnable,Controle,PCMais1_ID,RegA_ID,RegB_ID,Instruction,Offset_ID,IntEnd_ID,Int_ID,Wait_ID,ExceptionJAL_ID,PushArithInst_ID,
                                 SinaldeControle_EX,PCMais1_EX,RegA_EX,RegB_EX,Instruction_EX,Offset_EX,IntEnd_EX,Int_EX,Wait_EX,ExceptionJAL_EX,PushArithInst_EX);
    Controle <= DoJAL                          when Int_ID='1' else -- controle para fazer um jal
                SinaldeControle_ID(8 downto 0) when StallID='0' else
                (others => '0');               -- insere uma nop via hardware, uma instrucao que nao faz nada.
    DoJAL <= (0=>'1',1=>'1',2=>'0',3=>'0',4=>'1',5=>'1',6=>'0',7=>'0',8=>'0'); -- controles para um jal
    
    process(clk,rst)
    begin
      if(rst='0')then
        RegisteredFPUBusy <= '0';
      elsif rising_edge(clk) then
        RegisteredFPUBusy <= FPUBusy;
      end if;
    end process;
-- Execute:
    
    SOMABEQ:  entity work.mips_adder(fast_carry)
        port map (PCMais1_EX,Offset_EX,'0',OPEN,OPEN,BEQEnd_EX); -- Calcula endereco para branch

    ULA:    entity work.mips_alu(modular)
        generic map(n) port map (UlaA,FUlaB,UlaOp,Instruction_EX(7 downto 4),UlaZero_EX,Ula_Cout,Ula_Ovr,UlaOut_EX);
    
    ExceptionCarry <= Ula_Cout  when SinaldeControle_EX(8 downto 7) = "00" AND (Instruction_EX(3 downto 0) = "0110" OR Instruction_EX(3 downto 0) = "0010") else
                    '0';
    ExceptionOvr <= Ula_Ovr  when SinaldeControle_EX(8 downto 7) = "00" AND (Instruction_EX(3 downto 0) = "0110" OR Instruction_EX(3 downto 0) = "0010") else
                    '0';
                    
    
    EPC:  entity work.uregistrador(comum)     
        generic map (n => n) port map (clk,rst,Wait_ID,PCMais1_EX,ExceptionProgramCounter); -- registrador EPC
      
    with SinaldeControle_EX(8 downto 7) select
        UlaA <= Offset_EX   when "10", -- indica instrucoes SW e LW
                FUlaA       when others;
                
    with SinaldeControle_EX(8 downto 7) select
        UlaOp(4) <= '1'     when "01", -- eh 1 para operacoes do tipo S
                    OpXOR   when others; -- e tambem sera 1 para a operacao XOR (do tipo R)
    OpXOR <= (SinaldeControle_EX(8) NOR SinaldeControle_EX(7)) AND (Instruction_EX(3) AND Instruction_EX(2) AND Instruction_EX(1) AND Instruction_EX(0)); -- indentifica uma operacao XOR: (tipo R) and (func 1111)
    
    with SinaldeControle_EX(8 downto 7) select
        UlaOp(3 downto 0) <=    Instruction_EX(3 downto 0) when "00"|"01", -- tipo R ou tipo S: controle eh o proprio func
                                "0010"                     when "10", -- SW ou LW: ula soma
                                "0110"                     when others; -- BEQ: ula subtrai
    
    FUlaA <=  UlaOut_MEM                            when ForwardUlaA="10"       else
              RFEnt16_WB                            when ForwardUlaA="01"       else
              RFEnt8_MEM & RFEnt8_WB                when ForwardUpperUlaA="011" else -- upper byte em MEM eh mais novo que em EX; lower byte em WB eh mais novo que em EX.
              RFEnt8_MEM & RFEnt16_WB(7 downto 0)   when ForwardUpperUlaA="111" else -- upper byte em MEM eh mais novo que em EX; lower byte em WB eh mais novo que em EX.
              RFEnt8_WB & RFEnt8_MEM                when ForwardLowerUlaA="011" else -- lower byte em MEM eh mais novo que em EX; upper byte em WB eh mais novo que em EX.
              RFEnt16_WB(15 downto 8) & RFEnt8_MEM  when ForwardLowerUlaA="111" else -- lower byte em MEM eh mais novo que em EX; upper byte em WB eh mais novo que em EX.                   
              RFEnt8_WB & RegA_EX(7 downto 0)       when ForwardUpperUlaA="001" else -- upper byte em WB eh mais novo que em EX
              RFEnt8_MEM & RegA_EX(7 downto 0)      when ForwardUpperUlaA="010" else -- upper byte em MEM eh mais novo que em EX
              RegA_EX(15 downto 8) & RFEnt8_WB      when ForwardLowerUlaA="001" else -- lower byte em WB eh mais novo que em EX
              RegA_EX(15 downto 8) & RFEnt8_MEM     when ForwardLowerUlaA="010" else -- lower byte em MEM eh mais novo que em EX
              RegA_EX;
                  
    FUlaB <=  UlaOut_MEM                            when ForwardUlaB="10"       else
              RFEnt16_WB                            when ForwardUlaB="01"       else
              RFEnt8_MEM & RFEnt8_WB                when ForwardUpperUlaB="011" else -- upper byte em MEM eh mais novo que em EX; lower byte em WB eh mais novo que em EX.
              RFEnt8_MEM & RFEnt16_WB(7 downto 0)   when ForwardUpperUlaB="111" else -- upper byte em MEM eh mais novo que em EX; lower byte em WB eh mais novo que em EX.
              RFEnt8_WB & RFEnt8_MEM                when ForwardLowerUlaB="011" else -- lower byte em MEM eh mais novo que em EX; upper byte em WB eh mais novo que em EX.
              RFEnt16_WB(15 downto 8) & RFEnt8_MEM  when ForwardLowerUlaB="111" else -- lower byte em MEM eh mais novo que em EX; upper byte em WB eh mais novo que em EX.                   
              RFEnt8_WB & RegB_EX(7 downto 0)       when ForwardUpperUlaB="001" else -- upper byte em WB eh mais novo que em EX
              RFEnt8_MEM & RegB_EX(7 downto 0)      when ForwardUpperUlaB="010" else -- upper byte em MEM eh mais novo que em EX
              RegB_EX(15 downto 8) & RFEnt8_WB      when ForwardLowerUlaB="001" else -- lower byte em WB eh mais novo que em EX
              RegB_EX(15 downto 8) & RFEnt8_MEM     when ForwardLowerUlaB="010" else -- lower byte em MEM eh mais novo que em EX
              RegB_EX;
                  
                              
    FORWARDING: entity work.forwarding_unit(pipeline)
      port map(Instruction_EX(11 downto 8),Instruction_EX(7 downto 4),Instruction_MEM(11 downto 8),Instruction_WB(11 downto 8),
               SinaldeControle_MEM(1 downto 0),SinaldeControle_WB(1 downto 0),SinaldeControle_MEM(6),SinaldeControle_WB(2),
               ForwardUlaA,ForwardUlaB,ForwardUpperUlaA,ForwardUpperUlaB,ForwardLowerUlaA,ForwardLowerUlaB,ForwardRamDin);                        
    
    with SinaldeControle_EX(5 downto 3) select
          BEQ <= '1' when "100",
                 '0' when others;
    Branch <= UlaZero_EX AND BEQ;                            
    with SinaldeControle_EX(5 downto 3) select
          Jump <= '1' when "101",
                  '0' when others;
    with SinaldeControle_EX(5 downto 3) select
          Jal <= '1' when "110",
                 '0' when others;
    with SinaldeControle_EX(5 downto 3) select
          JR <=  '1' when "111",
                 '0' when others;
    PCOp <= Jump OR Jal OR Branch OR JR;
    
    --JREnd <= RegA_EX;
    JREnd <= FUlaA;
    JEnd <= PCMais1_EX(15 downto 12) & Instruction_EX(11 downto 0) when Int_EX = '0' else  -- Endereco para J ou JAL: PC(15 downto 12)&Instrucao(11 downto 0)    
            IntEnd_Ex;

        -- Coprocessador:
            PushArithInst <= PushArithInst_EX;
            InstructionOut <= Instruction_EX;
            FPUImediato16 <= FUlaB;
    
-- Registrador EX/MEM:
   
    EXMEM:   entity work.RegEXMEM(comum)
        generic map(n,7)  port map(clk,rst,'1',SinaldeControle_EX(6 downto 0),PCMais1_EX, FUlaA,   UlaOut_EX, Instruction_EX(11 downto 0), ExceptionJAL_EX,
                                               SinaldeControle_MEM,           PCMais1_MEM,RegA_MEM,UlaOut_MEM,Instruction_MEM,ExceptionJAL_MEM);
    
-- Memory:
    with ForwardRamDin select
        RamDin_MEM  <=  FromRam   when '1',
                        RegA_MEM  when others;
    RFEnt8_MEM <= Instruction_MEM(7 downto 0);                    
 
    data_out <= RamDin_MEM;
    data_w <= SinaldeControle_MEM(6);
    data_read <= SinaldeControle_MEM(2);
    data_end <= UlaOut_MEM;
    
   
-- Registrador MEM/WB:
        
    MEMWB:   entity work.RegMEMWB(comum)
        generic map(n,6)  port map(clk,rst,'1',SinaldeControle_MEM(5 downto 0),PCMais1_MEM,Instruction_MEM(11 downto 8),UlaOut_MEM,data_in,Instruction_MEM,ExceptionJAL_MEM,
                                               SinaldeControle_WB,             PCMais1_WB, RegEnd_WB,                   UlaOut_WB ,FromRam,Instruction_WB, ExceptionJAL_WB);
       
-- Write Back:

    with SinaldeControle_WB(2) select
        RFEnt16_WB   <=     UlaOut_WB   when '0',
                            FromRam     when others;
    
    with SinaldeControle_WB(5 downto 3) select
          Link <= '1' when "110", -- Jump and Link - indica que chegou a hora de "linkar"
                 '0' when others;
                            
    RFOp <= SinaldeControle_WB(1 downto 0);
    
    RFEnt8_WB <= Instruction_WB(7 downto 0);                            
                                                
end pipeline;
