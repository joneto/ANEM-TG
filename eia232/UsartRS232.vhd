library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UsartRS232 is
  generic(n :natural:=16;
          w :natural:=256); -- tamanho do buffer
  port(clk        :in std_logic;
       rst        :in std_logic;
       push       :in std_logic; -- buffer do transmissor
       pop        :in std_logic; -- buffer do receptor
       RegTXIn    :in unsigned(n-1 downto 0); -- buffer do transmissor
       RegRXOut   :out unsigned(n-1 downto 0); -- buffer do receptor
       RegCfgWe   :in std_logic;
       RegCfgIn   :in unsigned(n-1 downto 0);
       RegCfgOut  :out unsigned(n-1 downto 0);
       BaudRegWe  :in std_logic;
       BaudRegIn  :in unsigned(n-1 downto 0);
       BaudRegOut :out unsigned(n-1 downto 0); 
       UART_TXD   :out std_logic;
       UART_RXD   :in std_logic);
end UsartRS232;

architecture eia232 of UsartRS232 is
  signal    baudenable     :std_logic; -- clock da usart = clock / baudreg = baudrate
  signal    RSR9bit  :std_logic;
  signal    TXEN,SREN,CREN,SPEN :std_logic;
  signal    TX9,RX9  :std_logic;
  signal    PBEN     :std_logic;
  signal    TBufEmpty,RBufEmpty :std_logic;
  signal    TBufFull,RBufFull  :std_logic;
  signal    TBufPop,RBufPush   :std_logic;
  signal    BitSel   :unsigned(1 downto 0);
  signal    TBufOut  :std_logic_vector(n/2 downto 0);
  signal    RSROut   :unsigned(n/2 downto 0);
  signal    TXIF,RXIF,OERR,FERR,WRIF :std_logic;
  signal    TSRLoad  :std_logic;
  signal    TSRShift,RSRShift :std_logic;
  signal    TXParity :std_logic;
  signal    DataOut  :std_logic;
  signal    DataIn   :std_logic;
  signal    DivConst :unsigned(n-1 downto 0);
  signal    RegCfgPartial :unsigned(n-1 downto 0);
  signal    RegCfgComplete:unsigned(n-1 downto 0);
  signal	RegRXOutStd	:std_logic_vector(8 downto 0);
  signal notrst:std_logic;
  constant Low : unsigned := "00";
  constant Data : unsigned := "01";
  constant High : unsigned := "11";

begin
  notrst <= not rst;
--   Bloco comum a recepcao e transmissao:
  BaudRateGenerator: entity work.BaudRateGen
	generic map(n)  port map(clk,rst,DivConst,baudenable);
  RegBaudRateGenerator: entity work.uregistrador
	generic map(n)	 port map(clk,rst,BaudRegWe,BaudRegIn,DivConst);
  BaudRegOut <= DivConst;
  
    		
  ConfigRegister:   entity work.uregistrador
	  generic map(n)	 port map(clk,rst,RegCfgWe,RegCfgIn,RegCfgPartial);
  RegCfgComplete(15 downto 12) <= RegCfgPartial(15 downto 12);
  RegCfgComplete(11) <= SREN;
  RegCfgComplete(10 downto 9) <= RegCfgPartial(10 downto 9);
  RegCfgComplete(8) <= OERR;
  RegCfgComplete(7) <= FERR;
  RegCfgComplete(6) <= RXIF;
  RegCfgComplete(5) <= TXIF;
  RegCfgComplete(4) <= TBufFull;
  RegCfgComplete(3) <= TBufEmpty;
  RegCfgComplete(2) <= RBufFull;
  RegCfgComplete(1) <= RBufEmpty;
  RegCfgComplete(0) <= WRIF;

  RegCfgOut <= RegCfgComplete;
  SPEN <= RegCfgComplete(15);
  TX9 <= RegCfgComplete(14);
  RX9 <= RegCfgComplete(13);
  TXEN <= RegCfgComplete(12);
--SREN            -> Gerado pelo controle de recepcao
  CREN <= RegCfgComplete(10);
  PBEN <= RegCfgComplete(9);
--OERR            -> Gerado pelo controle de recepcao sempre que o Buffer de Recepcao e esta cheio e a recepcao esta habilitada, circuito de recepcao fica travado ate correcao disto
--FERR            -> Gerado pelo controle de recepcao sempre que ocorre um erro de framming (stop bit = 0), se recepcao estiver habilitada, ira continuar a transmissao (e a informacao neste bit ira se perder)
--RXIF            -> Gerado pelo controle de recepcao sempre que ocorre qualquer erro de recepcao (OERR,FERR).
--TXIF            -> Gerado pelo controle de transmissao sempre que o Buffer de Transmissao esta vazio e a transmissao esta habilitada (TXEN='1')
--TBF (TBufFull)  -> Gerado pelo Buffer de Transmissao
--TBE (TBufEmpty) -> Gerado pelo Buffer de Transmissao
--RBF (RBufFull)  -> Gerado pelo Buffer de Recepcao
--RBE (RBufEmpty) -> Gerado pelo Buffer de Recepcao
--WRIF 		  -> Gerado pelo Buffer de Recepcao sempre que uma nova palavra eh adicionada (Word Received Interruption Flag)
	 
	-- Circuito de transmissao: 
  ControledeTransmissao: entity work.TXControl
    port map(clk,baudenable,rst,TXEN,TX9,PBEN,TBufEmpty,TBufPop,BitSel,TXIF,TSRLoad,TSRShift);
  BufferdeTransmissao: ENTITY work.AltFifoBuffer
		PORT MAP(notrst,clk,std_logic_vector(RegTXIn(8 downto 0)),TBufPop,push,TBufEmpty,TBufFull,TBufOut);
  RegDeslocdeTransmissao: entity work.TSRegister
    port map(clk,baudenable,rst,TSRShift,TSRLoad,unsigned(TBufOut),TXParity,DataOut);
  with BitSel select
    UART_TXD <= '0'      when Low,
                '1'      when High,
                DataOut  when Data,
                TXParity when others;

  -- Circuito de Recepcao:
  CircuitodeEntrada: entity work.votomajoritario
    generic map(n)  port map(clk,baudenable,rst,UART_RXD,DataIn);
  ControledeRecepcao: entity work.RXControl
    port map(clk,baudenable,rst,DataIn,RegCfgWe,SREN,RegCfgIn(11),CREN,RX9,RBufFull,RBufPush,RXIF,OERR,FERR,RSR9bit,RSRShift);
  RegDeslocdeRecepcao: entity work.RSRegister
    port map(clk,baudenable,rst,RSR9bit,RSRShift,RSROut,DataIn);
  RegRXOut(8 downto 0) <= unsigned(RegRXOutStd);
  RegRXOut(n-1 downto n/2+1)<=(others=>'0');
  BufferdeRecepcao: ENTITY work.AltFifoBuffer
	PORT MAP(notrst,clk,std_logic_vector(RSROut),pop,RBufPush,RBufEmpty,RBufFull,RegRXOutStd);
  
  interrupcoes: process(clk,rst)
  begin
	if rst='0' then
		WRIF<='0';
	elsif rising_edge(clk) then
		if RBufPush='1' then
			WRIF <= '1';
		elsif RegCfgIn(0)='0' and RegCfgWe='1' then
			WRIF <= '0';
		end if;
	end if;
  end process;

end eia232;
