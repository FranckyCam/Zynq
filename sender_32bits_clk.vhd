library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity sender_32bits_clk is
    port (
        par_in       : in  std_logic_vector (31 downto 0);
        ser_out      : out std_logic_vector (3 downto 0);
        clk_word_out : out std_logic;
        clk_bit      : in  std_logic := '1';  --100MHz
        clk_word     : in  std_logic := '0';  --clk/8
        data_enable  : in  std_logic := '0';
        reset        : in  std_logic := '1'
        );
end sender_32bits_clk;

architecture RTL of sender_32bits_clk is
begin
    sender_8bits_clk : entity work.sender_8bit
        port map (
            reset       => reset,
            data_in     => x"0F",       --send the word clock
            clk_bit     => clk_bit,
            clk_word    => clk_word,
            data_out    => clk_word_out,
            data_enable => data_enable
            );

    gen_sender_8bits : for I in 3 downto 0 generate
    begin
        sender_8bits_I : entity work.sender_8bit
            port map (
                reset       => reset,
                data_in     => par_in((8*I)+7 downto 8*I),
                clk_bit     => clk_bit,
                clk_word    => clk_word,
                data_out    => ser_out(I),
                data_enable => data_enable
                );
    end generate;

end RTL;
