--
-- Top Entity for a FullNut + 12 kW ROM + 128 W RAM + 14 segment display driver
-- Cyclone IV Target with at least 15 Block RAMs for ROM
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM41C is
   port(
      OutClock      : in std_logic;
      OutClockEn    : in std_logic;
      Reset         : in std_logic;
      Address       : in std_logic_vector(13 downto 0);
      Q             : out std_logic_vector(9 downto 0)
   );
end ROM41C;

architecture logic of ROM41C is

component ROM41C_CIV is
    port (
        address : in std_logic_vector(13 downto 0);
        clock   : in std_logic;
        q       : out std_logic_vector(9 downto 0)
    );
    end component;
    
begin

    rom : ROM41C_CIV
        port map(
            address => Address,
            clock => OutClock,
            q => Q
            );

end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity FUllNut_CIV is
	port(
            clk_in          : in std_logic;                     -- 50 MHz clock PIN 23
            reset_in        : in std_logic;                     -- asserted high reset PIN 24
            key_in          : in std_logic_vector(7 downto 0);  -- last pressed key
            key_scan_o      : out std_logic;                    -- start keyboard scan
            key_ack_o       : out std_logic;                    -- acknowledge keyboard scan
            key_flag_in     : in std_logic;                     -- keyboard scanned flag (S15)
            flags_in        : in std_logic_vector( 7 downto 0); -- input flags
            flags_o         : out std_logic_vector( 7 downto 0);--output flags
            clk_1MHz_o      : out std_logic;                    -- PIN 10
            
            -- LCD Interface
            --commons_o   : inout std_logic_vector(35 downto 0);
            --segments_o  : inout std_logic_vector(5 downto 0)
            disp_cs_n_o : out std_logic;
            disp_res_n_o: out std_logic;
            disp_data_o : out std_logic;
            disp_addr_o : out std_logic;
            disp_sck_o  : out std_logic

			);
end FUllNut_CIV;

architecture logic of FUllNut_CIV is
    component nut_Main is 
        port (
            clk_in          : in std_logic;                     -- sync clock
            reset_in        : in std_logic;                     -- asserted high reset
            use_trace_in    : in std_logic;						-- trace enable
		    key_in          : in std_logic_vector(7 downto 0);  -- last pressed key
            key_scan_o      : out std_logic;                    -- start keyboard scan
            key_ack_o       : out std_logic;                    -- acknowledge keyboard scan
            key_flag_in     : in std_logic;                     -- keyboard scanned flag (S15)
            flags_in        : in std_logic_vector( 7 downto 0); -- input flags
            flags_o         : out std_logic_vector( 7 downto 0);--output flags
            reg_data_in     : in std_logic_vector(55 downto 0);
            reg_data_o      : out std_logic_vector(55 downto 0);
            reg_addr_o      : out std_logic_vector(11 downto 0);
            reg_perif_o     : out std_logic_vector(7 downto 0);
            reg_rd_o        : out std_logic;
            reg_we_o        : out std_logic
        );
        end component;
         
    component nut_LCDDriver is
        port(
            clk_in      : in std_logic;
            cpu_clk_in  : in std_logic;
            reset_in    : in std_logic;                     -- asserted high reset
            addr_in     : in std_logic_vector(3 downto 0); -- only 4 bits are significant 
            data_in     : in std_logic_vector(47 downto 0); -- only 48 bits are significant (12 nibbles)
            data_o      : out std_logic_vector(55 downto 0); -- only 48 bits are significant (12 nibbles)
            perif_in    : in std_logic_vector(7 downto 0);
            rd_in       : in std_logic;
            we_in       : in std_logic;
            ann_we_in   : in std_logic;
            -- LCD Interface
            --commons_o   : inout std_logic_vector(35 downto 0);
            --segments_o  : inout std_logic_vector(5 downto 0)
            disp_cs_n_o : out std_logic;
            disp_res_n_o: out std_logic;
            disp_data_o : out std_logic;
            disp_addr_o : out std_logic;
            disp_sck_o  : out std_logic
        );
         end component;
         
    
    component pll IS
        PORT
        (   
            areset		: IN STD_LOGIC;
            inclk0		: IN STD_LOGIC;
            c0		: OUT STD_LOGIC ;
            c1		: OUT STD_LOGIC ;
            locked		: OUT STD_LOGIC 
        );
    END component;
         
    --signal    clk             : std_logic := '0'; -- clock
    --signal    reset           : std_logic := '0'; -- active high reset
    --signal    key             : std_logic_vector(7 downto 0) := X"00";           -- keyboard column signal
    --signal    key_scan        : std_logic;                    -- keyboard active row
    --signal    key_ack         : std_logic;                    -- keyboard active row
    --signal    key_flag        : std_logic := '0';                    -- keyboard active row
    --signal    flags           : std_logic_vector(7 downto 0) := X"00"; -- input flags
    --signal    flagso          : std_logic_vector(7 downto 0) := X"00"; -- input flags
    signal    reg_data_from_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_data_to_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_addr        : std_logic_vector(11 downto 0); -- Register address
    signal    reg_perif       : std_logic_vector(7 downto 0); -- Peripheral address
    signal    reg_rd          : std_logic;                    -- read strobe
    signal    reg_we          : std_logic;                    -- write strobe
    signal    clk_25MHz       : std_logic;
    signal    clk_1MHz        : std_logic;
    signal    pll_locked      : std_logic;
    signal    reset           : std_logic := '1';
    signal    lcd_rd          : std_logic;                    -- lcd read strobe
    signal    lcd_we          : std_logic;                    -- write strobe
    signal    ann_we          : std_logic;                    -- annunciators write strobe
    signal    cpu_clk         : std_logic := '0';
    signal    clk_div         : integer range 0 to 15 := 0;
    signal    rst_cnt         : integer range 0 to 127 := 0;
begin
    ipll : pll
    port map (
        areset => '0',
        inclk0 => clk_in,
        c0     => clk_25MHz,
        c1     => clk_1MHz,
        locked => pll_locked
    );
    clk_1MHz_o <= clk_1MHz;
   
    
    process (clk_1MHz)
    begin
        if rising_edge(clk_1MHz) then
            if clk_div = 15 then
                cpu_clk <= not cpu_clk;
                clk_div <= 0;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;
 
    process (cpu_clk)
    begin
        if rising_edge(cpu_clk) then
            if pll_locked = '1' then
                if reset_in = '0' then
                    rst_cnt <= 1;
                elsif (rst_cnt /= 126) and (rst_cnt /= 0) then
                    rst_cnt <= rst_cnt + 1;
                end if;
            end if;
        
        
            if rst_cnt /= 126 then 
                reset <= '1';
            else
                reset <= '0';
            end if;
        end if;    
    end process;
 
    
    nut : nut_Main port map(
        clk_in          => clk_1MHz,--cpu_clk,          
        reset_in        => reset,       
        use_trace_in    => '0',						-- trace enable
		key_in          => key_in,        
        key_scan_o      => key_scan_o,          
        key_ack_o       => key_ack_o,          
        key_flag_in     => key_flag_in,          
        flags_in        => flags_in,          
        flags_o         => flags_o,          
        reg_data_in     => reg_data_from_periph,
        reg_data_o      => reg_data_to_periph,
        reg_addr_o      => reg_addr,
        reg_perif_o     => reg_perif,
        reg_rd_o        => reg_rd,
        reg_we_o        => reg_we
    );
    ann_we <= '1' when (reg_addr = X"FFF") and (reg_we = '1') and (reg_perif = X"FD") else '0';
    lcd_we <= '1' when (reg_addr /= X"FFF") and (reg_we = '1') and (reg_perif = X"FD") else '0';
    lcd_rd <= '1' when (reg_addr /= X"FFF") and (reg_rd = '1') and (reg_perif = X"FD") else '0';
    
    disp : nut_LCDDriver port map(
        clk_in      => clk_1MHz,          
        cpu_clk_in  => clk_1MHz,--cpu_clk,
        reset_in    => reset,       
        addr_in     => reg_addr(3 downto 0),
        data_in     => reg_data_to_periph(47 downto 0),
        data_o      => reg_data_from_periph,
        perif_in    => reg_perif,
        rd_in       => lcd_rd,
        we_in       => lcd_we,
        ann_we_in   => ann_we,
        --commons_o   => commons_o,
        --segments_o  => segments_o
        disp_cs_n_o => disp_cs_n_o,
        disp_res_n_o=> disp_res_n_o,
        disp_data_o => disp_data_o,
        disp_addr_o => disp_addr_o,
        disp_sck_o  => disp_sck_o
    );  

end architecture logic;




