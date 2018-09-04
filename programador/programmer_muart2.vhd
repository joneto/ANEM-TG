library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AnemProgrammerMuart2 is
  generic(n       :natural:=16;
          baudreg :natural:=5208; -- 9600 bps
          clk_freq:natural:=40;
          ser_freq:natural:=9600;
          r       :natural:=13);
  port(clk        :in std_logic;
       rst        :in std_logic;
       Prog       :in std_logic;
       address    :IN STD_LOGIC_VECTOR (r-1 DOWNTO 0);
       q          :OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
       progaddr   :buffer unsigned(r-1 downto 0);
       progdata   :buffer unsigned(n-1 downto 0);
       RegCfgOut  :buffer unsigned(n-1 downto 0);
       Counter    :buffer integer range 0 to 3;
       UART_TXD   :out std_logic;
       UART_RXD   :in std_logic
       );
end AnemProgrammerMuart2;
    
architecture rs232 of AnemProgrammerMuart2 is
    type state is (waitword,sendback,waitcommand,decide,escreve);
    signal currentstate,nextstate :state;
    signal ramdata                        :std_logic_vector(n-1 downto 0);
    signal ramaddr                        :std_logic_vector(r-1 downto 0);
    signal notclk,pawelsb,pawemsb,pdwelsb,pdwemsb,ramwe,progwe   :std_logic;
    signal progaddrmsb,progaddrlsb,progdatamsb,progdatalsb,Command1,Command2,Command3    :unsigned(7 downto 0);
    signal RegRXOut   :std_logic_vector(7 downto 0);
    signal RegTXIn    :std_logic_vector(7 downto 0);
  signal MuxCtrl        :std_logic_vector(1 downto 0);
    signal CommandWe    :std_logic_vector(2 downto 0);
    signal CommandSaysOk1,CommandSaysOk2,CommandSaysOk3    :std_logic;
    signal CommandSaysOk    :std_logic;
    signal QtdOneU1,QtdOneL1:integer range 0 to 4;
    signal QtdOneU2,QtdOneL2:integer range 0 to 4;
    signal QtdOneU3,QtdOneL3:integer range 0 to 4;
    signal QtdOne1,QtdOne2,QtdOne3:integer range 0 to 8;
    signal IncrCounter    :std_logic;
    signal CmdCounter    :integer range 0 to 2;
    signal IncrCmd        :std_logic;
    
    
    
    signal  EOC,EOC1:std_logic;
    signal  EOT            :std_logic;
    signal  READY   :std_logic;
    signal  TXWe        :std_logic;
          
begin    
    notclk <= not clk;
    MemoriadePrograma: ENTITY work.memoriaprogramavel
        PORT MAP(ramaddr,notclk,ramdata,ramwe,q);
    
    
    --Receptor: entity work.Minimal_UART_CORE
    --        port map(clk,EOC,RegRXOut,UART_RXD,UART_TXD,EOT,RegTXIn,READY,TXWe);
    Receptor: entity work.uart
        generic map(CLK_FREQ => clk_freq, SER_FREQ => ser_freq)
        port map(clk,rst,UART_RXD,UART_TXD,'0',TXWe,EOT,RegTXIn,EOC,RegRXOut);
    READY <= not EOT;

    process(clk,rst)
    begin
        if rst='0' then
            EOC1<='0';
        elsif rising_edge(clk) then
            EOC1<=EOC;
        end if;
    end process;
    
    with MuxCtrl select
        RegTXIn        <=     std_logic_vector(progaddrmsb) when "00",
                                    std_logic_vector(progaddrlsb) when "01",
                                    std_logic_vector(progdatamsb) when "10",
                                    std_logic_vector(progdatalsb) when others;
   
    
    RegCommand1: entity work.uregistrador
        generic map(8)    port map(clk,rst,CommandWe(0),unsigned(RegRXOut),Command1);
    with Command1(3 downto 0) select
        QtdOneL1 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    with Command1(7 downto 4) select
        QtdOneU1 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    QtdOne1 <= QtdOneU1 + QtdOneL1;
    CommandSaysOk1 <= '1' when QtdOne1>4 else
                                        '0';
    
    RegCommand2: entity work.uregistrador
        generic map(8)    port map(clk,rst,CommandWe(1),unsigned(RegRXOut),Command2);
    with Command2(3 downto 0) select
        QtdOneL2 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    with Command2(7 downto 4) select
        QtdOneU2 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    QtdOne2 <= QtdOneU2 + QtdOneL2;
    CommandSaysOk2 <= '1' when QtdOne2>4 else
                                        '0';
                                     
    RegCommand3: entity work.uregistrador
        generic map(8)    port map(clk,rst,CommandWe(2),unsigned(RegRXOut),Command3);
        with Command3(3 downto 0) select
        QtdOneL3 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    with Command3(7 downto 4) select
        QtdOneU3 <= 4 when "1111",
                                3 when "0111"|"1011"|"1101"|"1110",
                                2 when "0011"|"0101"|"0110"|"1001"|"1010"|"1100",
                                1 when "1000"|"0100"|"0010"|"0001",
                                0 when others;
    QtdOne3 <= QtdOneU3 + QtdOneL3;
    CommandSaysOk3 <= '1' when QtdOne3>4 else
                                        '0';
                                     
    CommandSaysOk <= '1' when (CommandSaysOk1='1' and CommandSaysOk2='1') or (CommandSaysOk1='1' and CommandSaysOk3='1') or (CommandSaysOk2='1' and CommandSaysOk3='1') else
                                     '0';

    RegProgAddrMSB: entity work.uregistrador
        generic map(8)    port map(clk,rst,pawemsb,unsigned(RegRXOut),progaddrmsb);
    RegProgAddrLSB: entity work.uregistrador
        generic map(8)    port map(clk,rst,pawelsb,unsigned(RegRXOut),progaddrlsb);
    progaddr(11 downto 8) <= progaddrmsb(3 downto 0);
    progaddr(7 downto 0) <= progaddrlsb;
    
    RegProgDataMSB: entity work.uregistrador
        generic map(8)    port map(clk,rst,pdwemsb,unsigned(RegRXOut),progdatamsb);
    RegProgDataLSB: entity work.uregistrador
        generic map(8)    port map(clk,rst,pdwelsb,unsigned(RegRXOut),progdatalsb);
    progdata(15 downto 8) <= progdatamsb;
    progdata(7 downto 0) <= progdatalsb;
    
    with Prog select
        ramaddr <= address     when '0',
                 std_logic_vector(progaddr) when others;
    ramdata <= std_logic_vector(progdata);
    ramwe <= progwe;               
    
        P0: process(clk,rst)
        begin
            if rst = '0' then
                Counter <= 0;
            elsif rising_edge(clk) then
                if IncrCounter='1' then
                    if Counter = 3 then
                        Counter <= 0;
                    else
                        Counter <= Counter + 1;
                    end if;
                end if;
            end if;
            if rst = '0' then
                CmdCounter <= 0;
            elsif rising_edge(clk) then
                if IncrCmd='1' then
                    if CmdCounter = 2 then
                        CmdCounter <= 0;
                    else
                        CmdCounter <= CmdCounter + 1;
                    end if;
                end if;
            end if;
        end process P0;
    
    
      P1: process(clk,rst)
      begin
          if rst = '0' then
            currentstate <= waitword;
          elsif rising_edge(clk) then
            currentstate <= nextstate;
          end if;
      end process P1;

      P2: process(currentstate,EOT,EOC,READY,Prog,CommandSaysOk,Counter,CmdCounter)
      begin
            case currentstate is
                when waitword =>
                    if EOC='1' and EOC1='0' and Prog = '1' then -- na subida de EOC e quando o programador estiver habilitado
                        nextstate <= sendback;
                        case Counter is
                            when 0 =>
                                    pawemsb <= '1';
                                    pawelsb <= '0';
                                    pdwemsb <= '0';
                                    pdwelsb <= '0';
                            when 1 =>
                                    pawemsb <= '0';
                                    pawelsb <= '1';
                                    pdwemsb <= '0';
                                    pdwelsb <= '0';
                            when 2 =>
                                    pawemsb <= '0';
                                    pawelsb <= '0';
                                    pdwemsb <= '1';
                                    pdwelsb <= '0';
                            when 3 =>
                                    pawemsb <= '0';
                                    pawelsb <= '0';
                                    pdwemsb <= '0';
                                    pdwelsb <= '1';
                        end case;
                    else
                        nextstate <= waitword;
                        pawemsb <= '0';
                        pawelsb <= '0';
                        pdwemsb <= '0';
                        pdwelsb <= '0';
                        
                    end if;
                    progwe <= '0';
                    case Counter is
                        when 0 => MuxCtrl <= "00";
                        when 1 => MuxCtrl <= "01";
                        when 2 => MuxCtrl <= "10";
                        when 3 => MuxCtrl <= "11";
                    end case;
                    CommandWe <= "000";
                    IncrCounter <= '0';
                    IncrCmd <= '0';
                    TXWe <= '0';
                    
                when sendback =>
                    if READY='0' then
                        nextstate <= waitcommand;
                        TXWe <= '0';
                    else
                        nextstate <= sendback;
                        TXWe <= '1';
                    end if;
                    case Counter is
                        when 0 => MuxCtrl <= "00";
                        when 1 => MuxCtrl <= "01";
                        when 2 => MuxCtrl <= "10";
                        when 3 => MuxCtrl <= "11";
                    end case;
                    pdwemsb <= '0';
                    pdwelsb <= '0';
                    pawemsb <= '0';
                    pawelsb <= '0';
                    progwe <= '0';
                    CommandWe <= "000";
                    IncrCounter <= '0';
                    IncrCmd <= '0';
                                    
                when waitcommand =>
                    if EOC='1' and EOC1='0' and Prog = '1' then -- na subida de EOC e quando o programador estiver habilitado
                        case CmdCounter is
                            when 0 => CommandWe <= "100";
                            when 1 => CommandWe <= "010";
                            when 2 => CommandWe <= "001";
                        end case;
                        if CmdCounter=2 then
                            nextstate <= decide;
                        else
                            nextstate <= waitcommand;
                        end if;
                        IncrCmd <= '1';
                    else
                        nextstate <= waitcommand;
                      CommandWe <= "000";
                        IncrCmd <= '0';
                    end if;
                    pdwemsb <= '0';
                    pdwelsb <= '0';
                    pawelsb <= '0';
                    pawemsb <= '0';
                    progwe <= '0';
                    MuxCtrl <= "--";
                    IncrCounter <= '0';
                    TXWe <= '0';
                
                when decide =>
                    if(CommandSaysOk='1') then 
                        if Counter=3 then
                            nextstate <= escreve;
                        else
                            nextstate <= waitword;
                        end if;
                        IncrCounter <= '1';
                    else
                        nextstate <= waitword;
                        IncrCounter <= '0';
                  end if;
                    MuxCtrl <= "--";
                    pdwemsb <= '0';
                    pdwelsb <= '0';
                    pawemsb <= '0';
                    pawelsb <= '0';
                    progwe <= '0';    
                    CommandWe <= "000";
                    TXWe <= '0';
                    IncrCmd <= '0';
            
                when escreve =>
                    nextstate <= waitword;
                    pdwelsb <= '0';
                    pdwemsb <= '0';
                    pawelsb <= '0';
                    pawemsb <= '0';
                    MuxCtrl <= "--";
                    progwe <= '1';
                    CommandWe <= "000";
                    IncrCounter <= '0';
                    IncrCmd <= '0';
                    TXWe <= '0';
                    
            end case;
      end process P2;      

end rs232;