-------------------------------------------------------------------------------
-- Title      : Ula de 16 bits para o anem16
-- Project    : 
-------------------------------------------------------------------------------
-- File       : mips_alu.vhd
-- Author     : Geraldo Travassos
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_alu is
	generic(n			:natural:=16);
	port (	ula_a,ula_b	:in unsigned(n-1 downto 0); -- os dois valores de entrada
			ula_op		:in unsigned(4 downto 0); -- controle da ULA
			ula_shamt	:in unsigned (3 downto 0);
			ula_zero	:out std_logic; -- indica se o valor da soma foi zero
			CarryOut	:out std_logic;
			Overflow	:out std_logic;
			ula_out		:out unsigned(n-1 downto 0));
end mips_alu;
---------------------------------------------------------------
----------- descricao em baixo nivel incluindo Carry Lookahead-
----------- Carry Lookahead com dois niveis de abstracao ------
---------------------------------------------------------------
architecture modular of mips_alu is
	signal Ainvert,Bnegate			:std_logic;
	signal Operation				:unsigned(1 downto 0);
	signal Sum,Less,a_prep,b_prep	:unsigned(n-1 downto 0);
	signal Result,RShifted			:unsigned(n-1 downto 0);
	signal adder_cout      :std_logic;
begin
	ALU_control:	block -- decodificacao do sinal de entrada apenas para tornar o codigo mais claro
	begin
		Ainvert <= ula_op(3); -- comando para inverter os bits da entrada a
		Bnegate <= ula_op(2); -- comando para tomar o complemento a 2 de b
		Operation <= ula_op(1 downto 0); -- comando que indica a operacao que a ULA realizara
	end block ALU_control;
	
	with Ainvert select
		a_prep	<=	ula_a			when '0',
					NOT ula_a		when '1',
					(others=>'X') 	when others;
	with Bnegate select -- observe que aqui apenas invertemos os bits de b, posteriormente sera somado Bnegate a b, finalizando o complemento a 2
		b_prep	<=	ula_b			when '0',
					NOT ula_b		when '1',
					(others=>'X')	when others;
	with Operation select -- dependendo da operacao, o resultado asume cada um dos possiveis valores
		Result 	<=	a_prep AND b_prep 	when "00",
					a_prep OR b_prep	when "01",
					Sum					when "10",
					Less				when "11", -- o bit menos significativo de Less eh 1 se a < b.
					(others=>'X') 		when others;
								
-- para determinar se a eh menor do que b, faz-se a-b, se o resultado eh negativo entao a<b.
	with Sum(n-1) select -- o bit mais significativo da soma indica justamente o sinal e, entao, define Less.
		Less <= to_unsigned(1,n) 	when '1',
				to_unsigned(0,n) 	when '0',
				(others=>'X') 		when others;
	
	MIPS_adder: entity work.mips_adder(fast_carry) -- componente responsavel por somar a_prep e b_prep, guardando o resultado em Sum
			port map (a_prep,b_prep,Bnegate,adder_cout,Overflow,Sum);
  with ula_op select
      CarryOut <= '0' when "00110",--(0=>'0',1=>'1',2=>'1',3=>'0',4=>'0'),
                  adder_cout when others;      
			
	Zero_detector: block -- bloco responsavel por verificar se a soma eh nula (faz um NOR de todos os bits)
		signal or_op	:std_logic_vector(n downto 0); -- vetor auxiliar para descrever um OR de n bits.
	begin
		or_op(n)<='0';
		esquema:	for i in n-1 downto 0 generate
			or_op(i)<=Sum(i) OR or_op(i+1);
		end generate esquema;
		ula_zero <= NOT or_op(0); -- inverte o OR de n bits, obtendo o sinal Zero.
	end block Zero_detector;
	
	ShifterCircuitry: block -- bloco para realizar as operacoes de shift. OBS: tb realiza a operação XOR
	begin
		with ula_op(3 downto 0) select
			RShifted <= shift_right(ula_a,to_integer(ula_shamt))					when "0001",
					  shift_left(ula_a,to_integer(ula_shamt))						when "0010",
						unsigned(shift_right(signed(ula_a),to_integer(ula_shamt))) 	when "0000", 
						rotate_right(ula_a,to_integer(ula_shamt))					when "0100",
						rotate_left(ula_a,to_integer(ula_shamt))					when "1000",
						ula_a XOR ula_b												when "1111",
						to_unsigned(0,n)											when others;
	end block ShifterCircuitry;
	
	with ula_op(4) select -- define se eh uma operacao normal da ula ou uma operacao de deslocamento	
		ula_out <= 	Result 			when '0',
					RShifted 		when '1',
					(others=>'X')	when others;
				
end modular;
