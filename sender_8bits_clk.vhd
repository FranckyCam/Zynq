library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity sender_8bits_clk is
    port (
        par_in       : in  std_logic_vector (7 downto 0);
        ser_out      : out std_logic;
        clk_word_out : out std_logic;
        clk_100000   : in  std_logic := '1';
        clk_12500    : in  std_logic := '0';
        data_enable  : in  std_logic := '0';
        reset        : in  std_logic := '1'
        );
end sender_8bits_clk;

architecture RTL of sender_8bits_clk is

begin
    sender_8bits_word_clk : entity work.sender_8bit
        port map (
            reset       => reset,
            data_in     => x"0F",       --send the word clock
            clk_100000  => clk_100000,
            clk_12500   => clk_12500,
            data_out    => clk_word_out,
            data_enable => data_enable
            );

    sender_8bits_data : entity work.sender_8bit
        port map (
            reset       => reset,
            data_in     => par_in,
            clk_100000  => clk_100000,
            clk_12500   => clk_12500,
            data_out    => ser_out,
            data_enable => data_enable
            );
end RTL;
