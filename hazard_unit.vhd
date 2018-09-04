-------------------------------------------------------------------------------
-- Title      : Hazard Unit
-- Project    : 
-------------------------------------------------------------------------------
-- File       : hazard_unit.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87			
-------------------------------------------------------------------------------
-- Description: Trata dos data hazards e control hazards que precisam de stalls
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
    port(   PushArithInst,FPUBusy							:in std_logic;
						ra_ID,rb_ID,ra_EX,opcode_ID       :in unsigned(3 downto 0);
            Int_ID,RamToReg_EX,PCSalto_EX     :in std_logic;
            CarryOut,Overflow,IntEnCo,IntEnOv :in std_logic;
            Wait_EX                           :in std_logic;            
            Wait_ID                           :out std_logic;
            StallID_Out,IFFlush,StallEX       :buffer std_logic);    
end hazard_unit;

architecture pipeline of hazard_unit is
    signal StallIF,StallID  :std_logic;
begin

bubbles: process (ra_ID,rb_ID,ra_EX,opcode_ID,RamtoReg_EX,Int_ID,PCSalto_EX,Wait_EX,CarryOut,Overflow,IntEnCo,IntEnOv,PushArithInst,FPUBusy)
begin
		if (PushArithInst='1' and FPUBusy='1') then
				StallEX <= '1';
		else
				StallEX <= '0';
		end if;
	
    if (CarryOut='1' and IntEnCo='1') or (Overflow='1' and IntEnOv='1') then
        StallID <= '1';
        Wait_ID <= '1';
    elsif Wait_EX = '1' then
        StallID <= '1';
        Wait_ID <= '0';    
    elsif RamToReg_EX = '1' then
        if (opcode_ID = "0000") or (opcode_ID = "0001") or (opcode_ID = "0110") or (opcode_ID = "0111") then  -- tipo R, tipo S, BEQ, JR
            if (ra_ID = ra_EX) or (rb_ID = ra_EX) then
                StallID <= '1';
                Wait_ID <= '0';
            else
                StallID <= '0';
                Wait_ID <= '0';
            end if;
        else
            StallID <= '0';
            Wait_ID <= '0';
        end if;
    else
        StallID <= '0';
        Wait_ID <= '0';
    end if;
    
    if (opcode_ID = "0110") or (opcode_ID = "0111") or (opcode_ID = "1000") or (opcode_ID = "1001") or (Int_ID = '1') then -- se alguma instrucao de salto em ID ou interrupcao
        StallIF <= '1';
    elsif (PCSalto_EX = '1') then -- se alguma instrucao de salto em EX
        StallIF <= '1';
    else
        StallIF <= '0';
    end if;
  
end process bubbles;

    IFFlush <= StallIF and (not StallID); -- StallID tem prioridade sobre StallIF;
		StallID_Out <= StallID or StallEX; -- StallEX tambem precisa que StallID esteja habilitado;

end pipeline;

