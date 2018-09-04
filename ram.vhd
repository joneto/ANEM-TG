-------------------------------------------------------------------------------
-- Title      : MemÃ³ria Ram
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ram.vhd
-- Author     : Arthur / Geraldo
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
entity ram is
	generic( n	        :natural:=16;
           EndAlto    :natural:=16#FFCF#);
	port(clk,rst,we	:in std_logic;
			Endereco	:in unsigned(n-1 downto 0);
			Din		    :in unsigned(n-1 downto 0);
			Dout	    :out unsigned(n-1 downto 0);
			SRAM_CACHE_DQ         :inout std_logic_vector(15 downto 0);  -- dados da SRAM
			SRAM_CACHE_ADDR       :out   std_logic_vector(15 downto 0);  -- endereço da SRAM
			SRAM_CACHE_WE_N       :out   std_logic  -- controles da SRAM
			);
end ram;

architecture simples of ram is
		
		signal TriStateDin	:std_logic_vector(n-1 downto 0);
begin
		TriStateDin <= std_logic_vector(Din) when we='1' else (others=>'Z');
		SRAM_CACHE_DQ <= TriStateDin;
		Dout <= unsigned(SRAM_CACHE_DQ);
		SRAM_CACHE_ADDR <= std_logic_vector(Endereco);
		SRAM_CACHE_WE_N <= not we;
		
end simples;
