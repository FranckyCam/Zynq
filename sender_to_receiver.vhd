-- LVL_SHIFTER_EN 0xF8000900
-- FPGA0_CLK_CTRL 0xF8000170

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.axi3s_pkg.all;                 -- AXI3 Slave

library UNISIM;
use UNISIM.VComponents.all;

entity sender_to_receiver is
    generic (
        CLK_WORD_PERIOD_IN_NS : real := 40.0  -- don't forget to change
                                              -- create_clock in xdc file !
        );
    port (
        lvds_data_out_p     : out std_logic_vector(3 downto 0);
        lvds_data_out_n     : out std_logic_vector(3 downto 0);
        lvds_clk_word_out_p : out std_logic;
        lvds_clk_word_out_n : out std_logic;
        lvds_data_in_p      : in  std_logic_vector(3 downto 0);
        lvds_data_in_n      : in  std_logic_vector(3 downto 0);
        lvds_clk_word_in_p  : in  std_logic;
        lvds_clk_word_in_n  : in  std_logic
        );
end sender_to_receiver;

architecture RTL of sender_to_receiver is
    constant pattern : std_logic_vector (31 downto 0) := x"A5B6C7D8";

    signal serial_data_out     : std_logic_vector(3 downto 0);
    signal serial_clk_word_out : std_logic;
    signal serial_data_in      : std_logic_vector(3 downto 0);
    signal serial_clk_word_in  : std_logic;
    signal clk_word            : std_logic;
    signal init_done           : std_logic;
    signal data_in             : std_logic_vector (31 downto 0) := pattern;  --test
    signal data_in_delayed     : std_logic_vector (31 downto 0) := x"00000000";
    signal data_out            : std_logic_vector (31 downto 0);
    signal data_enable         : std_logic                      := '0';  --gpio
                                                                         --57
    signal blue_led            : std_logic;
    signal blink               : std_logic;

    signal reset : std_logic := '1';

    signal clk_50000_fclk : std_logic_vector (3 downto 0);  --33.33MHz clock from PS
    signal clk_50000      : std_logic;
    signal clk_bit        : std_logic;  --global clock 100MHz
    signal clk_bit_pll    : std_logic;
    signal pll_fbout      : std_logic;
    signal pll_fbin       : std_logic;
    signal pll_locked     : std_logic := '0';

    signal emio_gpio_i : std_logic_vector (63 downto 0) := (others => '0');
    signal emio_gpio_o : std_logic_vector (63 downto 0) := (others => '0');
    signal data_match  : std_logic_vector(3 downto 0)   := (others => '0');

    signal clk_cfg  : std_logic;
    signal clk_cfgm : std_logic;

    signal s_axi_aclk     : std_logic_vector (3 downto 0);
    signal s_axi_areset_n : std_logic_vector (3 downto 0);

    signal s_axi_ri : axi3s_read_in_a(3 downto 0);
    signal s_axi_ro : axi3s_read_out_a(3 downto 0);
    signal s_axi_wi : axi3s_write_in_a(3 downto 0);
    signal s_axi_wo : axi3s_write_out_a(3 downto 0);

    constant DATA_WIDTH : natural := 64;

    constant ADDR_WIDTH : natural := 32;

    type addr_a is array (natural range <>) of
        std_logic_vector (ADDR_WIDTH - 1 downto 0);

    constant WADDR_MASK : addr_a(0 to 3) :=
        (x"07FFFFFF", x"03FFFFFF", x"000FFFFF", x"000FFFFF");
    constant WADDR_BASE : addr_a(0 to 3) :=
        (x"18000000", x"1C000000", x"1D000000", x"1E000000");

    signal wdata_clk    : std_logic;
    signal wdata_enable : std_logic;
    signal wdata_in     : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');
    signal wdata_empty  : std_logic;

    signal wdata_full : std_logic;

    signal waddr_clk    : std_logic;
    signal waddr_enable : std_logic;
    signal waddr_in     : std_logic_vector (ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal waddr_empty  : std_logic;

    signal waddr_match  : std_logic;
    signal waddr_sel    : std_logic_vector (1 downto 0);
    signal waddr_sel_in : std_logic_vector (1 downto 0);

    signal wbuf_sel : std_logic_vector (1 downto 0);

    signal writer_clk : std_ulogic;

    signal writer_inactive : std_logic_vector (3 downto 0);
    signal writer_error    : std_logic_vector (3 downto 0);

    signal writer_active : std_logic_vector (3 downto 0);
    signal writer_unconf : std_logic_vector (3 downto 0);

    signal waddr_reset  : std_logic;
    signal waddr_load   : std_logic;
    signal waddr_switch : std_logic;
    signal waddr_block  : std_logic;

    signal writer_enable : std_logic_vector (3 downto 0);
    signal write_strobe  : std_logic_vector (7 downto 0);


begin

    div_led_inst : entity work.async_div
        generic map (
            STAGES => 26)
        port map (
            clk_in  => clk_cfgm,
            clk_out => blink);

    STARTUPE2_inst : STARTUPE2
        generic map (
            PROG_USR      => "FALSE",   -- Program event security feature.
            SIM_CCLK_FREQ => 0.0)       -- Configuration Clock Frequency(ns)
        port map (
            CFGCLK    => clk_cfg,  -- 1-bit output: Configuration main clock output
            CFGMCLK   => clk_cfgm,  -- 1-bit output: Configuration internal oscillator clock output
            EOS       => open,  -- 1-bit output: Active high output signal indicating the End Of Startup.
            PREQ      => open,  -- 1-bit output: PROGRAM request to fabric output
            CLK       => '0',  -- 1-bit input: User start-up clock input
            GSR       => '0',  -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
            GTS       => '0',  -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
            KEYCLEARB => '0',  -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
            PACK      => '0',  -- 1-bit input: PROGRAM acknowledge input
            USRCCLKO  => '0',           -- 1-bit input: User CCLK input
            USRCCLKTS => '0',  -- 1-bit input: User CCLK 3-state enable input
            USRDONEO  => '0',  -- 1-bit input: User DONE pin output control
            USRDONETS => blue_led);  -- 1-bit input: User DONE 3-state enable output

    blue_led <= '1' when data_match(0) = '1' else blink;

    BUFG_clk_inst : BUFG
        port map (
            I => clk_50000_fclk(0),
            O => clk_50000);

    ps7_stub_inst : entity work.ps7_stub
        port map (
            ps_fclk         => clk_50000_fclk,
            emio_gpio_i     => emio_gpio_i,
            emio_gpio_o     => emio_gpio_o,
            s_axi0_aclk     => s_axi_aclk(0),
            s_axi0_areset_n => s_axi_areset_n(0),
            --
            s_axi0_arid     => s_axi_ri(0).arid,
            s_axi0_araddr   => s_axi_ri(0).araddr,
            s_axi0_arburst  => s_axi_ri(0).arburst,
            s_axi0_arlen    => s_axi_ri(0).arlen,
            s_axi0_arsize   => s_axi_ri(0).arsize,
            s_axi0_arprot   => s_axi_ri(0).arprot,
            s_axi0_arvalid  => s_axi_ri(0).arvalid,
            s_axi0_arready  => s_axi_ro(0).arready,
            s_axi0_racount  => s_axi_ro(0).racount,
            --
            s_axi0_rid      => s_axi_ro(0).rid,
            s_axi0_rdata    => s_axi_ro(0).rdata,
            s_axi0_rlast    => s_axi_ro(0).rlast,
            s_axi0_rvalid   => s_axi_ro(0).rvalid,
            s_axi0_rready   => s_axi_ri(0).rready,
            s_axi0_rcount   => s_axi_ro(0).rcount,
            --
            s_axi0_awid     => s_axi_wi(0).awid,
            s_axi0_awaddr   => s_axi_wi(0).awaddr,
            s_axi0_awburst  => s_axi_wi(0).awburst,
            s_axi0_awlen    => s_axi_wi(0).awlen,
            s_axi0_awsize   => s_axi_wi(0).awsize,
            s_axi0_awprot   => s_axi_wi(0).awprot,
            s_axi0_awvalid  => s_axi_wi(0).awvalid,
            s_axi0_awready  => s_axi_wo(0).awready,
            s_axi0_wacount  => s_axi_wo(0).wacount,
            --
            s_axi0_wid      => s_axi_wi(0).wid,
            s_axi0_wdata    => s_axi_wi(0).wdata,
            s_axi0_wstrb    => s_axi_wi(0).wstrb,
            s_axi0_wlast    => s_axi_wi(0).wlast,
            s_axi0_wvalid   => s_axi_wi(0).wvalid,
            s_axi0_wready   => s_axi_wo(0).wready,
            s_axi0_wcount   => s_axi_wo(0).wcount,
            --
            s_axi0_bid      => s_axi_wo(0).bid,
            s_axi0_bresp    => s_axi_wo(0).bresp,
            s_axi0_bvalid   => s_axi_wo(0).bvalid,
            s_axi0_bready   => s_axi_wi(0).bready
            );

    axihp_writer_inst : entity work.axihp_writer
        generic map (
            DATA_WIDTH => 64,
            DATA_COUNT => 1,
            ADDR_MASK  => WADDR_MASK(0),
            ADDR_DATA  => WADDR_BASE(0))
        port map (
            m_axi_aclk     => writer_clk,          -- in
            m_axi_areset_n => s_axi_areset_n(0),   -- in
            enable         => writer_enable(0),    -- in
            inactive       => writer_inactive(0),  -- out
            --
            m_axi_wo       => s_axi_wi(0),
            m_axi_wi       => s_axi_wo(0),
            --
            addr_clk       => waddr_clk,           -- out
            addr_enable    => waddr_enable,        -- out
            addr_in        => waddr_in,            -- in
            addr_empty     => waddr_empty,         -- in
            --
            data_clk       => wdata_clk,           -- out
            data_enable    => wdata_enable,        -- out
            data_in        => wdata_in,            -- in
            data_empty     => wdata_empty,         -- in
            --
            write_strobe   => write_strobe,        -- in
            --
            writer_error   => writer_error(0),     -- out
            writer_active  => writer_active,       -- out
            writer_unconf  => writer_unconf);      -- out

    s_axi_aclk(0) <= writer_clk;

    writer_enable(0) <= '1';
    waddr_empty      <= '0';
    wdata_empty      <= '0';
    write_strobe     <= (others => '1');

    writer_clk <= clk_50000_fclk(0);

    ---------------------------------------------------------------------------

    emio_gpio_i(0) <= '0';              -- gpio 54 in linux
    emio_gpio_i(1) <= '1';              -- gpio 55 in linux
    emio_gpio_i(2) <= data_match(0);    -- gpio 56 in linux
    emio_gpio_i(3) <= pll_locked;       -- gpio 57 in linux

    data_enable <= emio_gpio_o(4);      -- gpio 58 in linux
    reset       <= emio_gpio_o(5);      -- gpio 59 in linux

    emio_gpio_i(6) <= data_match(1);    -- gpio 60 in linux
    emio_gpio_i(7) <= data_match(2);    -- gpio 61 in linux
    emio_gpio_i(8) <= data_match(3);    -- gpio 62 in linux

    mmcm_inst : MMCME2_BASE
        generic map (
            CLKIN1_PERIOD    => 20.0,                         --50 MHz
            CLKFBOUT_MULT_F  => 20.0,                         --1000 MHz
            CLKOUT0_DIVIDE_F => CLK_WORD_PERIOD_IN_NS / 8.0,  -- bit clock
            --
            CLKOUT0_PHASE    => 0.0,
            --
            DIVCLK_DIVIDE    => 1)
        port map (
            CLKIN1   => clk_50000,
            CLKFBOUT => pll_fbout,
            CLKFBIN  => pll_fbin,

            CLKOUT0 => clk_bit_pll,
            LOCKED  => pll_locked,
            PWRDWN  => '0',
            RST     => '0');

    pll_fbin <= pll_fbout;

    BUFR_clk_inst : BUFR
        generic map (
            BUFR_DIVIDE => "1")
        port map (
            I   => clk_bit_pll,
            O   => clk_bit,
            CE  => '1',
            CLR => '0');

    BUFR_clk_50000_inst : BUFR
        generic map (
            BUFR_DIVIDE => "8")
        port map (
            I   => clk_bit_pll,
            O   => clk_word,
            CE  => '1',
            CLR => '0');

    OBUFDS_inst : OBUFDS
        generic map (
            IOSTANDARD => "LVDS_25",
            SLEW       => "SLOW")
        port map (
            O  => lvds_clk_word_out_p,
            OB => lvds_clk_word_out_n,
            I  => serial_clk_word_out);

    IBUFDS_inst : IBUFDS
        generic map (
            DIFF_TERM    => true,
            IBUF_LOW_PWR => true,
            IOSTANDARD   => "LVDS_25")
        port map (
            O  => serial_clk_word_in,
            I  => lvds_clk_word_in_p,
            IB => lvds_clk_word_in_n);

    gen_lvds : for I in 3 downto 0 generate
    begin
        OBUFDS_inst : OBUFDS
            generic map (
                IOSTANDARD => "LVDS_25",
                SLEW       => "FAST")
            port map (
                O  => lvds_data_out_p(I),
                OB => lvds_data_out_n(I),
                I  => serial_data_out(I));

        IBUFDS_inst : IBUFDS
            generic map (
                DIFF_TERM    => true,
                IBUF_LOW_PWR => true,
                IOSTANDARD   => "LVDS_25")
            port map (
                O  => serial_data_in(I),
                I  => lvds_data_in_p(I),
                IB => lvds_data_in_n(I));
    end generate;

    sender_32bits_clk_inst : entity work.sender_32bits_clk
        port map (
            par_in       => data_in,
            ser_out      => serial_data_out,
            clk_word_out => serial_clk_word_out,
            clk_bit      => clk_bit,
            clk_word     => clk_word,
            data_enable  => data_enable,
            reset        => reset
            );

    receiver_32bits_clk_inst : entity work.receiver_32bits_clk
        generic map (
            CLK_WORD_PERIOD => CLK_WORD_PERIOD_IN_NS
            )
        port map (
            ser_in       => serial_data_in,
            clk_word_in  => serial_clk_word_in,
            par_out      => data_out,
            reset        => reset,
            init_pattern => pattern,
            init_done    => init_done
            );

    gen_clock_delay_8bits : for I in 3 downto 0 generate
    begin
        clk_delay_inst_I : entity work.clock_delay_8bits
            port map (
                data_in  => data_in(8*I+7 downto 8*I),
                data_out => data_in_delayed(8*I+7 downto 8*I),
                clk      => serial_clk_word_in
                );
    end generate;

    data_match_proc : process (serial_clk_word_in, reset)
    begin  -- process
        if reset = '1' then
            data_match <= (others => '0');
        elsif rising_edge(serial_clk_word_in) then
            if data_enable = '0' then
                data_match <= (others => '0');
            else
                if data_in_delayed(7 downto 0) = data_out(7 downto 0) then
                    data_match(0) <= '1';
                else
                    data_match(0) <= '0';
                end if;

                if data_in_delayed(15 downto 8) = data_out(15 downto 8) then
                    data_match(1) <= '1';
                else
                    data_match(1) <= '0';
                end if;

                if data_in_delayed(23 downto 16) = data_out(23 downto 16) then
                    data_match(2) <= '1';
                else
                    data_match(2) <= '0';
                end if;

                if data_in_delayed(31 downto 24) = data_out(31 downto 24) then
                    data_match(3) <= '1';
                else
                    data_match(3) <= '0';
                end if;
            end if;
        end if;
    end process;

    change_number : process (clk_word, reset)  --prng in fact...
    begin
        if reset = '1' then
            data_in <= pattern;
        elsif rising_edge(clk_word) then
            if init_done = '1' then
                data_in <= data_in(30 downto 0) & (data_in(31) xor data_in(21) xor data_in(1) xor data_in(0));
            end if;
        end if;
    end process;

    write_axihp : process(clk_word, reset, clk_50000)
        variable count_clk       : integer := 0;
        variable count_word      : integer := 0;
        variable word_freq       : integer := 0;
        variable count_error     : integer := 0;
        variable count_word_done : integer := 0;
    begin
        if reset = '1' then
            count_error := 0;
            count_clk   := 0;
            count_word  := 0;
            word_freq   := 0;
        else
            if rising_edge(clk_50000) then
                if count_clk = 50000000 then
                    count_clk       := 0;
                    count_word_done := 1;
                end if;
                count_clk := (count_clk+1);
            end if;
            if rising_edge(clk_word) then
                if count_word_done = 1 then
                    word_freq       := count_word;
                    count_word_done := 0;
                    count_word      := 1;
                else
                    count_word := (count_word + 1);
                end if;

                if data_enable = '1' then
                    if data_match(0) = '0' or data_match(1) = '0' or data_match(2) = '0' or data_match(3) = '0' then
                        count_error := (count_error + 1);
                    end if;
                end if;
            end if;
        end if;
        wdata_in(31 downto 0)  <= std_logic_vector(to_unsigned(word_freq, 32));
        wdata_in(63 downto 32) <= std_logic_vector(to_unsigned(count_error, 32));
    end process;

end RTL;
