-------------------------------------------------------------------------------
-- Title      : Forwading unit
-- Project    : 
-------------------------------------------------------------------------------
-- File       : forwarding_unit.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87			
-------------------------------------------------------------------------------
-- Description: Evita alguns tipos de data hazards criando novos caminhos para a informacao
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_unit is
    port(   ra_EX,rb_EX,ra_MEM,ra_WB          :in unsigned(3 downto 0);
            RFOp_MEM,RFOp_WB                  :in unsigned(1 downto 0);
            WriteRam_MEM, RamToReg_WB         :in std_logic;
            ForwardUlaA,ForwardUlaB           :out unsigned(1 downto 0);
            SForwardUpperUlaA,SForwardUpperUlaB :out unsigned(2 downto 0);
            SForwardLowerUlaA,SForwardLowerUlaB :out unsigned(2 downto 0);
            ForwardRamDin                     :out std_logic);    
end forwarding_unit;

architecture pipeline of forwarding_unit is
begin
combinacional: process (ra_EX,rb_EX,ra_MEM,ra_WB,RFOp_MEM,RFOp_WB,WriteRam_MEM,RamToReg_WB)
    variable ForwardUpperUlaA,ForwardUpperUlaB : unsigned(2 downto 0);
    variable ForwardLowerUlaA,ForwardLowerUlaB : unsigned(2 downto 0);
    begin   
         if not(ra_EX="0000") then 
                if (ra_EX = ra_MEM) and (RFOp_MEM="10") then
                    if (ra_EX = ra_WB) and (RFOp_WB = "01") then
                        ForwardUpperUlaA := "011";
                    elsif (ra_EX = ra_WB) and (RFOp_WB = "11") then
                        ForwardUpperUlaA := "111";
                    else
                        ForwardUpperUlaA := "010";
                    end if;
                elsif (ra_EX = ra_WB) and (RFOp_WB="10") then
                    ForwardUpperUlaA := "001";
                else
                    ForwardUpperUlaA := "000";
                end if;
         else
                ForwardUpperUlaA := "000";
         end if;
         if not(rb_EX="0000") then 
                if (rb_EX = ra_MEM) and (RFOp_MEM="10") then
                    if (rb_EX = ra_WB) and (RFOp_WB = "01") then
                        ForwardUpperUlaB := "011";
                    elsif (rb_EX = ra_WB) and (RFOp_WB = "11") then
                        ForwardUpperUlaB := "111";
                    else
                        ForwardUpperUlaB := "010";
                    end if;
                elsif (rb_EX = ra_WB) and (RFOp_WB="10") then
                    ForwardUpperUlaB := "001";
                else
                    ForwardUpperUlaB := "000";
                end if;
         else
                ForwardUpperUlaB := "000";
         end if;
         
         if not(ra_EX="0000") then 
                if (ra_EX = ra_MEM) and (RFOp_MEM="01") then
                    if (ra_EX = ra_WB) and (RFOp_WB = "10") then
                        ForwardLowerUlaA := "011";
                    elsif (ra_EX = ra_WB) and (RFOp_WB = "11") then
                        ForwardLowerUlaA := "111";
                    else
                        ForwardLowerUlaA := "010";
                    end if;
                elsif (ra_EX = ra_WB) and (RFOp_WB="01") then
                    ForwardLowerUlaA := "001";
                else
                    ForwardLowerUlaA := "000";
                end if;
         else
                ForwardLowerUlaA := "000";
         end if;
         if not(rb_EX="0000") then 
                if (rb_EX = ra_MEM) and (RFOp_MEM="01") then
                    if (rb_EX = ra_WB) and (RFOp_WB = "10") then
                        ForwardLowerUlaB := "011";
                    elsif (rb_EX = ra_WB) and (RFOp_WB = "11") then
                        ForwardLowerUlaB := "111";
                    else
                        ForwardLowerUlaB := "010";
                    end if;
                elsif (rb_EX = ra_WB) and (RFOp_WB="01") then
                    ForwardLowerUlaB := "001";
                else
                    ForwardLowerUlaB := "000";
                end if;
         else
                ForwardLowerUlaB := "000";
         end if;
         
         
         if not(ra_EX="0000") then 
                if (ra_EX = ra_MEM) and (RFOp_MEM="11") then
                    ForwardUlaA <= "10";
                elsif (ra_EX = ra_WB) and (RFOp_WB="11") and (ForwardUpperUlaA="000") and (ForwardLowerUlaA="000") then
                    ForwardUlaA <= "01";
                else
                    ForwardUlaA <= "00";
                end if;
         else
                ForwardUlaA <= "00";
         end if;
         if not(rb_EX="0000") then     
                if (rb_EX = ra_MEM) and (RFOp_MEM="11") then
                    ForwardUlaB <= "10";
                elsif (rb_EX = ra_WB) and (RFOp_WB="11") and (ForwardUpperUlaB="000") and (ForwardLowerUlaB="000") then
                    ForwardUlaB <= "01";
                else
                    ForwardUlaB <= "00";
                end if;
         else
                ForwardUlaB <="00";
         end if;
                           
         if (ra_MEM = ra_WB) and (WriteRam_MEM='1') and (RamToReg_WB='1') then
                ForwardRamDin <= '1';
         else
                ForwardRamDin <= '0';
         end if;
         
         SForwardUpperUlaA <= ForwardUpperUlaA;
         SForwardUpperUlaB <= ForwardUpperUlaB;
         SForwardLowerUlaA <= ForwardLowerUlaA;
         SForwardLowerUlaB <= ForwardLowerUlaB;
         
    end process combinacional;
end pipeline;
