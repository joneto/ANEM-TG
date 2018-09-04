library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sete is
  
  port (
    data_in        : in  unsigned(3 downto 0);
    sete_segmentos : out std_logic_vector(6 downto 0));

end sete;

architecture combinacional of sete is

begin  -- combinacional

  process(data_in)
    begin
  case data_in is
    when "0000" => sete_segmentos <= "1000000";
    when "0001" => sete_segmentos <= "1111001";
    when "0010" => sete_segmentos <= "0100100";
    when "0011" => sete_segmentos <= "0110000";
    when "0100" => sete_segmentos <= "0011001";
    when "0101" => sete_segmentos <= "0010010";
    when "0110" => sete_segmentos <= "0000010";
    when "0111" => sete_segmentos <= "1111000";
    when "1000" => sete_segmentos <= "0000000";
    when "1001" => sete_segmentos <= "0010000";
    when "1010" => sete_segmentos <= "0001000";
    when "1011" => sete_segmentos <= "0000011";
    when "1100" => sete_segmentos <= "1000110";
    when "1101" => sete_segmentos <= "0100001";
    when "1110" => sete_segmentos <= "0000110";
    when "1111" => sete_segmentos <= "0001110";
    when others => sete_segmentos <= "1111111";
  end case;
end process;
end combinacional;
