-- LCD Driver Module for driving HD44780 Controller
-- A. Greensted, June 2007

-- Information source:
-- http://www.repairfaq.org/filipg/LINK/F_Tech_LCD.html

-- Generic tickNum must be set such that:
-- tickNum = 10us / Period clk
-- This provides an internal tick every 10us
-- Clk: 100 MHz, tickNum: 1000
-- Clk: 32 MHz, tickNum: 320
-- Clk: 10 MHz, tickNum: 100

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCDDriver is
	generic ( tickNum	: positive := 500);
	port (	clk		: in		std_logic;
		reset		: in		std_logic;
		dIn			: in		std_logic_vector(7 downto 0);
		charNum		: in		std_logic_vector(5 downto 0);
		wEn			: in		std_logic;
   		-- LCD Interface
		lcdData		: out		std_logic_vector(7 downto 0);
		lcdRS		: out		std_logic;
		lcdRW		: out		std_logic;
		lcdE		: out		std_logic);
end LCDDriver;

architecture Structural of LCDDriver is

	-- LCD interface constants
	constant LCD_READ		: std_logic := '1';
	constant LCD_WRITE		: std_logic := '0';
	constant DATA_CODE		: std_logic := '1';
	constant INSN_CODE		: std_logic := '0';

	-- Tick Generation
	subtype TICK_COUNTER_TYPE is integer range 0 to tickNum;
	signal tick					: std_logic;

	constant WARMUP_DELAY	: integer := 2000;	-- 2000: 20ms
	constant INIT_DELAY		: integer := 500;		-- 500:	5ms
	constant CHAR_DELAY		: integer := 10;		-- 10:	100us

	subtype DELAY_TYPE is integer range 0 to WARMUP_DELAY;
	signal timer				: DELAY_TYPE;

	type INIT_ROM_TYPE is array (0 to 6) of std_logic_vector(7 downto 0);
	constant initROM			: INIT_ROM_TYPE := (	b"0011_0000",	-- Init
														b"0011_0000",	-- Init
														b"0011_0000",	-- Init
														b"0011_1000",	-- Function Set: 8 bit, 2 lines, 5x7 characters
														b"0000_1100",	-- Display On/Off Control: Display on, Cursor off, Blink off
														b"0000_0001",	-- Clear Display: Move cursor to home
														b"0000_0110");	-- Entry Mode Set: Auto increment cursor, don't shift display

	type CHAR_RAM_TYPE is array(0 to 39) of std_logic_vector(7 downto 0);
	signal charRAM				: CHAR_RAM_TYPE := (	--0=>x"41", 1=>x"6E", 2=>x"65", 3=>x"6D", 4=>x"31", 5=>x"36",
																--20=>x"46", 21=>x"61", 22=>x"74", 23=>x"6F", 24=>x"72", 25=>x"69", 26=>x"61", 27=>x"6C",
																others=>x"A0");

	signal setLine				: std_logic;
	signal lineNum				: integer range 0 to 1;
	signal initialising		    : std_logic;

	signal initROMPointer	: integer range 0 to INIT_ROM_TYPE'high;
	signal charRAMPointer	: integer range 0 to CHAR_RAM_TYPE'high;

	type STATE_TYPE is (WARMUP, STAGE1, STAGE2, STAGE3, DELAY);
	signal state				: STATE_TYPE;

begin

lcdRW	<= LCD_WRITE;

TickGen : process(clk)
	variable tickCounter : TICK_COUNTER_TYPE;
begin
	if (clk'event and clk='1') then
		if (tickCounter = 0) then
			tickCounter := TICK_COUNTER_TYPE'high-1;
			tick <= '1';
		else
			tickCounter := tickCounter - 1;
			tick <= '0';
		end if;
	end if;
end process;

CharRAMWrite : process(clk,reset)
	variable add : integer range 0 to 39;
begin
	if (reset='1') then
		charRAM <= (others=>x"A0");
	elsif (clk'event and clk='1') then
		if (wEn='1') then
			add := to_integer(unsigned(charNum));
			charRAM(add) <= dIn;
		end if;
	end if;
end process;

Controller : process (clk)
begin
	if (clk'event and clk='1') then

		if (reset='1') then
			timer				<= WARMUP_DELAY;
			initROMPointer <= 0;
			charRAMPointer <= 0;

			lcdRS			<= INSN_CODE;
			lcdE			<= '0';
			lcdData			<= (others => '0');

			initialising	<= '1';
			setLine			<= '0';
			lineNum			<= 0;
			state			<= WARMUP;

		elsif (tick='1') then

			case state is 

				-- Perform initial long warmup delay
				when WARMUP =>
					if (timer=0) then
						state <= STAGE1;
					else
						timer <= timer - 1;
					end if;

				-- Set the LCD data
				-- Set the LCD RS
				-- Initialise the timer with the required delay
				when STAGE1 =>
					if (initialising='1') then
						timer		<= INIT_DELAY;
						lcdRS		<= INSN_CODE;
						lcdData		<= initROM(initROMPointer);

					elsif (setLine='1') then
						timer		<= CHAR_DELAY;
						lcdRS		<= INSN_CODE;
						case lineNum is
							when 0 => lcdData	<= b"1000_0000";	-- x00
							when 1 => lcdData	<= b"1100_0000";	-- x40
						end case;

					else
						timer		<= CHAR_DELAY;
						lcdRS		<= DATA_CODE;
						lcdData		<= charRAM(charRAMPointer);

					end if;

					state	<= STAGE2;

				-- Set lcdE (latching RS and RW)
				when STAGE2 =>
					if (initialising='1') then
						if (initROMPointer=INIT_ROM_TYPE'high) then
							initialising <= '0';
						else
							initROMPointer	<= initROMPointer + 1;
						end if;
					elsif (setLine='1') then
						setLine <= '0';
					else
						if (charRAMPointer=19) then
							setLine <= '1';
							lineNum <= 1;
						elsif (charRAMPointer=39) then
							setLine <= '1';
							lineNum <= 0;
						end if;
						if (charRAMPointer=CHAR_RAM_TYPE'high) then
							charRAMPointer <= 0;
						else
							charRAMPointer <= charRAMPointer + 1;
						end if;
					end if;

					lcdE	<= '1';
					state	<= STAGE3;

				-- Clear lcdE (latching data)
				when STAGE3 =>
					lcdE	<= '0';
					state	<= DELAY;

				-- Provide delay to allow instruciton to execute
				when DELAY =>
					if (timer=0) then
						state <= STAGE1;
					else
						timer <= timer - 1;
					end if;
			end case;
		end if;
	end if;
end process;

end Structural;
