-------------------------------------------------------------------------------
-- Title      : Multiplier and Accumulator
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mac.vhd
-- Author     : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Arquivo ainda em construcao
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac is
    generic(    n:natural:=16;
				NCiclos:natural:=1);
    port(  clk         	:in std_logic;
           rst         	:in std_logic;
           BIn		:in unsigned(n-1 downto 0);
	   	   BuWe,BsWe	:in std_logic;
	       CIn		:in unsigned(n-1 downto 0);
	       CWe		:in std_logic;
	       A0In,A1In	:in unsigned(n-1 downto 0);
	       A0Out,A1Out	:out unsigned(n-1 downto 0);
	       A0WeExt,A1WeExt	:in std_logic;
	       Ready	:out std_logic);
end entity mac;

architecture simples of mac is
	type estado is (Inicio,MUnsigned,MSigned,ASigned,AUnsigned,Fim);	
	signal B,C,A0,A1,A0Novo,A1Novo,A0RegIn,A1RegIn	:unsigned(n-1 downto 0);
	signal AWeInterno,A0We,A1We,BWe,Ctrl,ResultWe	:std_logic;
	signal Result,RegResult		:unsigned(2*n-1 downto 0);
	signal EstadoAtual,EstadoFuturo	:estado:=Inicio;
	signal Counter :integer range 0 to NCiclos;
	signal A,Acc	:unsigned(2*n-1 downto 0);
begin

	BReg:	entity work.uregistrador
		generic map(n) port map(clk,rst,BWe,BIn,B);
	CReg:	entity work.uregistrador
		generic map(n) port map(clk,rst,CWe,CIn,C);
	A0Reg:	entity work.uregistrador
		generic map(n) port map(clk,rst,A0We,A0RegIn,A0);
	A1Reg:	entity work.uregistrador
		generic map(n) port map(clk,rst,A1We,A1RegIn,A1);
	A1We <= AWeInterno OR A1WeExt;
	A0We <= AWeInterno OR A0WeExt;
	BWe <= BuWe OR BsWe;
	Acc <= A1&A0;
	A0RegIn <= A(n-1 downto 0) when AWeInterno='1' else
			   A0In;
	A1RegIn <= A(2*n-1 downto n) when AWeInterno='1' else
			   A1In;

	Result <= unsigned(B*C) when Ctrl='0' else
			  unsigned(signed(B)*signed(C));
	
	ResultReg:	entity work.uregistrador
		generic map(2*n) port map(clk,rst,ResultWe,Result,RegResult);
	ResultWe <= '1' when Counter=NCiclos else
				'0'; 
	
		
	A <= unsigned(Acc+RegResult) when Ctrl='0' else
		 unsigned(signed(Acc)+signed(RegResult));
	AWeInterno <= '1' when (EstadoAtual=AUnsigned) OR (EstadoAtual=ASigned) else
				  '0';
	

	process(clk,rst)
	begin
		if(rst='0')then
			EstadoAtual <= Inicio;
		elsif(rising_edge(clk))then
			EstadoAtual <= EstadoFuturo;
		end if;		
	end process;
	
	process(EstadoAtual,BuWe,BsWe,Counter)
	begin
		case EstadoAtual is
			when Inicio =>
					if(BuWe='1')then
						EstadoFuturo <= MUnsigned;
					elsif(BsWe='1')then
						EstadoFuturo <= MSigned;
					else
						EstadoFuturo <= Inicio;
					end if;
			when MUnsigned =>
					if(Counter=Nciclos)then
						EstadoFuturo <= AUnsigned;
					else
						EstadoFuturo <= MUnsigned;
					end if;
			when MSigned =>
					if(Counter=Nciclos)then
						EstadoFuturo <= ASigned;
					else
						EstadoFuturo <= MSigned;
					end if;
			when AUnsigned =>
					EstadoFuturo <= Fim;
			when ASigned =>
					EstadoFuturo <= Fim;
			when Fim =>
					EstadoFuturo <= Inicio;
		end case;		
	end process;
	
	process(clk,rst)
	begin
		if rst='0' then
			Counter<=0;
		elsif rising_edge(clk) then
			if (EstadoAtual=Inicio)OR(EstadoAtual=Fim)OR(EstadoAtual=ASigned)OR(EstadoAtual=AUnsigned) then
				Counter<=0;
			else
				if Counter<NCiclos then
					Counter <= Counter+1;
				else
					Counter <= 0;
				end if;
			end if;
		end if;
	end process;

	Ctrl <= '0' when (EstadoAtual=MUnsigned) OR (EstadoAtual=AUnsigned) else
			'1';

	Ready <= '1' when EstadoAtual=Fim else
			 '0';
	A0Out <= A0;
	A1Out <= A1;
end simples;
