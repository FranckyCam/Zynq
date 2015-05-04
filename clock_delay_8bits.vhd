library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_delay_8bits is
    Port ( data_in : in STD_LOGIC_VECTOR (7 downto 0);
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           clk : in STD_LOGIC);
end clock_delay_8bits;

architecture RTL of clock_delay_8bits is
    signal data_1 : std_logic_vector (7 downto 0) := x"00";
    signal data_2 : std_logic_vector (7 downto 0) := x"00";
    signal data_3 : std_logic_vector (7 downto 0) := x"00";
begin

    delay : process (clk) is
    begin  -- process
        if falling_edge(clk) then
            data_out <= data_3;
            data_3 <= data_2;
            data_2 <= data_1;
            data_1 <= data_in;
        end if;
    end process;

end RTL;
