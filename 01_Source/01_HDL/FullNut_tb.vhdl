
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FUllNut_tb is

end FUllNut_tb;

architecture logic of FUllNut_tb is
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
            reset_in    : in std_logic;   -- active high async reset
            addr_in     : in std_logic_vector(3 downto 0); -- only 4 bits are significant 
            data_in     : in std_logic_vector(47 downto 0); -- only 48 bits are significant (12 nibbles)
            data_o      : out std_logic_vector(55 downto 0); -- only 48 bits are significant (12 nibbles)
            perif_in    : in std_logic_vector(7 downto 0);
            rd_in       : in std_logic;
            we_in       : in std_logic;
            ann_we_in   : in std_logic;
            -- LCD Interface
            --commons_o   : out std_logic_vector(35 downto 0);
            --segments_o  : inout std_logic_vector(5 downto 0)
            disp_cs_n_o : out std_logic;
            disp_res_n_o: out std_logic;
            disp_data_o : out std_logic;
            disp_addr_o : out std_logic;
            disp_sck_o  : out std_logic
        );
         end component;
    signal    clk             : std_logic := '0'; -- clock
    signal    reset           : std_logic := '0'; -- active high reset
    signal    key             : std_logic_vector(7 downto 0) := X"00";           -- keyboard column signal
    signal    key_scan        : std_logic;                    -- keyboard active row
    signal    key_ack         : std_logic;                    -- keyboard active row
    signal    key_flag        : std_logic := '0';                    -- keyboard active row
    signal    flags           : std_logic_vector(7 downto 0) := X"00"; -- input flags
    signal    flagso          : std_logic_vector(7 downto 0) := X"00"; -- input flags
    signal    reg_data_from_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_data_to_periph        : std_logic_vector(55 downto 0); -- reg_data_to_periph
    signal    reg_addr        : std_logic_vector(11 downto 0); -- Register address
    signal    reg_perif       : std_logic_vector(7 downto 0); -- Peripheral address
    signal    reg_rd          : std_logic;                    -- read strobe
    signal    reg_we          : std_logic;                    -- write strobe
    signal    lcd_rd          : std_logic;                    -- lcd read strobe
    signal    lcd_we          : std_logic;                    -- write strobe
    signal    ann_we          : std_logic;                    -- annunciators write strobe
    
begin

    
    nut : nut_Main port map(
        clk_in          => clk,          
        reset_in        => reset,
        use_trace_in    => '1',						-- trace enable
		key_in          => key,        
        key_scan_o      => key_scan,          
        key_ack_o       => key_ack,          
        key_flag_in     => key_flag,          
        flags_in        => flags,          
        flags_o         => flagso,          
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
        clk_in          => clk,          
        cpu_clk_in      => clk,          
        reset_in        => reset,       
        data_in         => reg_data_to_periph(47 downto 0),
        data_o          => reg_data_from_periph,
        addr_in         => reg_addr(3 downto 0),
        perif_in        => reg_perif,
        rd_in           => lcd_rd,
        we_in           => lcd_we,
        ann_we_in       => ann_we
    );
    
    process 
        begin
            clk        <= '0';
            wait for 1000 ns;
            clk        <= '1';
            wait for 1000 ns;
        end process;
    
    process 
        begin
            reset        <= '1';
            wait for 2000 ns;
            reset        <= '0';
            wait;
        end process;
        

end architecture logic;




