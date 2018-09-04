-------------------------------------------------------------------------------
-- Title      : Controle do pipeline
-- Project    : 
-------------------------------------------------------------------------------
-- File       : controle.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87			
-------------------------------------------------------------------------------
-- Description: Simplesmente um circuito combinacional para gerar os sinais de controle
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controle is
    generic (n	:natural:=16);
    port(   Opcode          :in   unsigned(3 downto 0);
            SinaldeControle :out  unsigned(10 downto 0);
						PushArithInst		:out 	std_logic);    
end controle;

architecture pipeline of controle is
    signal WriteRam, MemToReg, UlaSel, HabInt, DesInt   :std_logic;
    signal UlaCtrl, RfOp                                :unsigned(1 downto 0);
    signal PCOp                                         :unsigned(2 downto 0);
begin
    SinaldeControle(1 downto 0) <= RfOp;
    SinaldeControle(2) <= MemToReg;
    SinaldeControle(6) <= WriteRam;
    SinaldeControle(5 downto 3) <= PCOp;
    SinaldeControle(8 downto 7) <= UlaCtrl;
    SinaldeControle(9) <= HabInt;
    SinaldeControle(10) <= DesInt;
--  Descricao dos sinais de controle:
--    PCOp(2)   => 0 (soma1), 1 (op de saltos)
--    PCOp(1:0) => 00 (beq), 01 (jump), 10 (jal), 11 (jr)
--    WriteRam => indica que um dado sera escrito na RAM
--    MemToReq => indica que o arquivo de registradores ira receber um dado da memoria RAM
--    UlaCtrl => 00 (tipo R), 01 (tipo S), 10 (sw ou lw), 11 (beq)
--    RfOp => 00 (faz nada), 01 (lil), 10, (liu), 11 (escrever 16 bits)
--    HabInt => Indica que interrupcoes podem ser tratadas
--    DesInt => Bloqueia tratamento de interrupcoes
combinacional: process (Opcode)
    begin
        case Opcode is
            when "0000" => -- instrucoes do tipo R
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "00";
                RfOp <= "11";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "0001" => -- instrucoes do tipo S
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01";
                RfOp <= "11";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "1000" => -- J
                PCOp  <= "101";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "1001" => -- JAL
                PCOp  <= "110";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "11";
                HabInt <= '0';
                DesInt <= '1';
								PushArithInst <= '0';
            when "0110" => -- BEQ
                PCOp  <= "100";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "11";
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "0111" => -- JR
                PCOp  <= "111";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';           
								PushArithInst <= '0';
            when "0100" => -- SW
                PCOp  <= "000";
                WriteRam <= '1';
                MemToReg <= '0';
                UlaCtrl <= "10";
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "0101" => -- LW
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '1';
                UlaCtrl <= "10";
                RfOp <= "11";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "1100" => -- LIU
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "10";
                HabInt <= '0';
                DesInt <= '0';
								PushArithInst <= '0';
            when "1101" => -- LIL
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "01";
                HabInt <= '0';
                DesInt <= '0';
				PushArithInst <= '0';
            when "1111" => -- HAB
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "00";
                HabInt <= '1';
                DesInt <= '0';                  
				PushArithInst <= '0';
            when "0010"|"0011"|"1011"|"1110" => -- Instrucoes destinadas a um coprocessador externo ao anem16
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';                  
				        PushArithInst <= '1';
            when others => -- No Operation
                PCOp  <= "000";
                WriteRam <= '0';
                MemToReg <= '0';
                UlaCtrl <= "01"; -- n eh dont care pq nao pode ser 00 (por causa das excecoes)
                RfOp <= "00";
                HabInt <= '0';
                DesInt <= '0';
				PushArithInst <= '0';
        end case;
    end process combinacional;
end pipeline;
			
