--------------------------------------------------------------------------------
-- Title      : Multiplexador do PC para MIPS
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mux.vhd
-- Author     : Renan Porto
-- Company    : 
-- Created    : 2010-04-14
-- Last update: 2010-04-14
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: PC para implementação do MIPS 
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY mux IS
	GENERIC	(n: INTEGER := 16);
	PORT	( 	
	       mux_0, mux_1  :IN UNSIGNED (n-1 DOWNTO 0);
				 mux_control   :IN STD_LOGIC;
				 mux_out       :OUT UNSIGNED (n-1 DOWNTO 0)
	     	);
END mux;

ARCHITECTURE func OF mux IS
	
BEGIN
		WITH mux_control SELECT	
			
				mux_out <=  	mux_0 WHEN '0', 
							       mux_1 WHEN '1', 
				            (OTHERS => 'X') WHEN OTHERS;
			
END func;


