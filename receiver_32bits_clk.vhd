library IEEE;
use IEEE.STD_LOGIC_1164.all;

--Uncomment the following library declaration if using
--arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

--Uncomment the following library declaration if instantiating
--any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

library unisim;
use unisim.vcomponents.all;

entity receiver_32bits_clk is
    generic (
        CLK_WORD_PERIOD : real
        );
    port (ser_in       : in  std_logic_vector (3 downto 0);
          clk_word_in  : in  std_logic;
          par_out      : out std_logic_vector (31 downto 0);
          reset        : in  std_logic;
          init_pattern : in  std_logic_vector (31 downto 0);
          init_done    : out std_logic);
end receiver_32bits_clk;

architecture rtl of receiver_32bits_clk is
    signal pll_clk          : std_logic;
     signal pll_clk_word          : std_logic;
    signal clk              : std_logic;
    signal clk_word_delayed : std_logic;
    signal pll_fbout        : std_logic;
    signal pll_fbin         : std_logic;
    signal pll_locked       : std_logic;
    signal bit_slip         : std_logic := '0';
    signal training_done    : std_logic := '0';
    signal wait_signal      : std_logic := '0';
    signal par_data         : std_logic_vector (31 downto 0);
begin

    mmcm_clk_inst : MMCME2_BASE
        generic map (
            CLKIN1_PERIOD    => CLK_WORD_PERIOD,
            CLKFBOUT_MULT_F  => CLK_WORD_PERIOD,  --1000MHz
            CLKOUT0_DIVIDE_F => CLK_WORD_PERIOD / 8.0,  -- bit clk
            CLKOUT1_DIVIDE => integer(CLK_WORD_PERIOD),
            --
            CLKOUT0_PHASE    => 0.0,
            CLKOUT1_PHASE => 0.0,
            --
            DIVCLK_DIVIDE    => 1)
        port map (
            CLKIN1   => clk_word_in,
            CLKFBOUT => pll_fbout,
            CLKFBIN  => pll_fbin,

            CLKOUT0 => pll_clk,
            CLKOUT1 => pll_clk_word,

            LOCKED => pll_locked,
            PWRDWN => '0',
            RST    => reset);

    pll_fbin  <= pll_fbout;
    init_done <= training_done;

    BUFG_clk_inst : BUFG
        port map (
            I => pll_clk,
            O => clk);

    BUFG_clk_word_inst : BUFG
        port map (
            I => pll_clk_word,
            O => clk_word_delayed);

    -- BUFR_clk_word_inst : BUFR
    --     generic map (
    --         BUFR_DIVIDE => "8")
    --     port map (
    --         I   => clk,
    --         O   => clk_word_delayed,
    --         CE  => '1',
    --         CLR => '0');


    gen_receiver_8bits : for I in 3 downto 0 generate

    begin
        iserdes_master_inst_i : iserdese2
            generic map (
                DATA_RATE           => "SDR",
                DATA_WIDTH          => 8,
                INTERFACE_TYPE      => "NETWORKING",
                IOBDELAY            => "NONE",
                OFB_USED            => "FALSE",
                SERDES_MODE         => "MASTER",
                IS_CLK_INVERTED     => '0',
                IS_CLKB_INVERTED    => '1',
                IS_CLKDIV_INVERTED  => '0',
                IS_CLKDIVP_INVERTED => '1',
                NUM_CE              => 1)
            port map (
                Q1           => par_data(8*I+7),
                Q2           => par_data(8*I+6),
                Q3           => par_data(8*I+5),
                Q4           => par_data(8*I+4),
                Q5           => par_data(8*I+3),
                Q6           => par_data(8*I+2),
                Q7           => par_data(8*I+1),
                Q8           => par_data(8*I+0),
                BITSLIP      => bit_slip,
                CE1          => pll_locked,
                CE2          => '0',
                CLK          => clk,
                CLKB         => clk,
                CLKDIV       => clk_word_delayed,
                CLKDIVP      => clk_word_delayed,
                D            => ser_in(I),
                DDLY         => '0',
                DYNCLKDIVSEL => '0',
                DYNCLKSEL    => '0',
                OCLK         => '0',
                OCLKB        => '0',
                OFB          => '0',
                RST          => reset,
                SHIFTIN1     => '0',
                SHIFTIN2     => '0');
    end generate;

    par_out <= par_data;

    bit_slip_process : process(clk_word_in, reset)
        variable count : integer := 0;
    begin
        if reset = '1' then
            training_done <= '0';
        elsif rising_edge(clk_word_in) then
            if training_done = '0' then
                if pll_locked = '1' then
                    if bit_slip = '1' then
                        bit_slip <= '0';
                    else
                        if wait_signal = '1' then
                            if count > 2 then
                                count       := 0;
                                wait_signal <= '0';
                            end if;
                            count := (count + 1);
                        else
                            if par_data = init_pattern then
                                training_done <= '1';
                            else
                                bit_slip    <= '1';
                                wait_signal <= '1';
                                count       := 0;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end rtl;
