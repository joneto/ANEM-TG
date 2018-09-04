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
entity CacheController is
	generic( n	        :natural:=16;
             cachesize	:natural:=16);
	port(clk,rst,we	:in std_logic;
			Endereco	:in std_logic_vector(n-1 downto 0);
			Din		    :in std_logic_vector(n-1 downto 0);
			Dout	    :out std_logic_vector(n-1 downto 0);
			SRAM_CACHE_DQ         :inout std_logic_vector(15 downto 0);  -- dados da SRAM
			SRAM_CACHE_ADDR       :out   std_logic_vector(15 downto 0);  -- endereço da SRAM
			SRAM_CACHE_WE_N       :out   std_logic  -- controles da SRAM
			);
end CacheController;

architecture simples of CacheController is
		signal TriStateDin	:std_logic_vector(n-1 downto 0);
begin
		TriStateDin <= Din when we='1' else (others=>'Z');
		SRAM_CACHE_DQ <= TriStateDin;
		Dout <= SRAM_CACHE_DQ;
		SRAM_CACHE_ADDR <= Endereco;
		SRAM_CACHE_WE_N <= not we;
		
end simples;
