LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY project_tb IS
END project_tb;

ARCHITECTURE projecttb OF project_tb IS
    CONSTANT c_CLOCK_PERIOD : TIME := 15 ns;
    SIGNAL tb_done : STD_LOGIC;
    SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_rst : STD_LOGIC := '0';
    SIGNAL tb_start : STD_LOGIC := '0';
    SIGNAL tb_clk : STD_LOGIC := '0';
    SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
    SIGNAL enable_wire : STD_LOGIC;
    SIGNAL mem_we : STD_LOGIC;

    TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL RAM : ram_type := (0 => STD_LOGIC_VECTOR(to_unsigned(2, 8)),
    1 => STD_LOGIC_VECTOR(to_unsigned(2, 8)),
    2 => STD_LOGIC_VECTOR(to_unsigned(46, 8)),
    3 => STD_LOGIC_VECTOR(to_unsigned(131, 8)),
    4 => STD_LOGIC_VECTOR(to_unsigned(62, 8)),
    5 => STD_LOGIC_VECTOR(to_unsigned(89, 8)),
    OTHERS => (OTHERS => '0'));
    -- Expected Output  6 -> 0                         
    -- Expected Output  7 -> 255                         
    -- Expected Output  8 -> 64                         
    -- Expected Output  9 -> 172                         

    COMPONENT project_reti_logiche IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_start : IN STD_LOGIC;
            i_rst : IN STD_LOGIC;
            i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            o_done : OUT STD_LOGIC;
            o_en : OUT STD_LOGIC;
            o_we : OUT STD_LOGIC;
            o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT project_reti_logiche;
BEGIN
    UUT : project_reti_logiche
    PORT MAP(
        i_clk => tb_clk,
        i_start => tb_start,
        i_rst => tb_rst,
        i_data => mem_o_data,
        o_address => mem_address,
        o_done => tb_done,
        o_en => enable_wire,
        o_we => mem_we,
        o_data => mem_i_data
    );

    p_CLK_GEN : PROCESS IS
    BEGIN
        WAIT FOR c_CLOCK_PERIOD/2;
        tb_clk <= NOT tb_clk;
    END PROCESS p_CLK_GEN;
    MEM : PROCESS (tb_clk)
    BEGIN
        IF tb_clk'event AND tb_clk = '1' THEN
            IF enable_wire = '1' THEN
                IF mem_we = '1' THEN
                    RAM(conv_integer(mem_address)) <= mem_i_data;
                    mem_o_data <= mem_i_data AFTER 1 ns;
                ELSE
                    mem_o_data <= RAM(conv_integer(mem_address)) AFTER 1 ns;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    test : PROCESS IS
    BEGIN
        WAIT FOR 100 ns;
        WAIT FOR c_CLOCK_PERIOD;
        tb_rst <= '1';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT FOR 100 ns;
        tb_rst <= '0';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT FOR 100 ns;
        tb_start <= '1';
        WAIT FOR c_CLOCK_PERIOD;
        WAIT UNTIL tb_done = '1';
        WAIT FOR c_CLOCK_PERIOD;
        tb_start <= '0';
        WAIT UNTIL tb_done = '0';
        WAIT FOR 100 ns;

        -- Immagine originale =  [46, 131, 62, 89]  
        -- Immagine di output =  [0, 255, 64, 172]

        ASSERT RAM(6) = STD_LOGIC_VECTOR(to_unsigned(0, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  0  found " & INTEGER'image(to_integer(unsigned(RAM(6)))) SEVERITY failure;
        ASSERT RAM(7) = STD_LOGIC_VECTOR(to_unsigned(255, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  255  found " & INTEGER'image(to_integer(unsigned(RAM(7)))) SEVERITY failure;
        ASSERT RAM(8) = STD_LOGIC_VECTOR(to_unsigned(64, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  64  found " & INTEGER'image(to_integer(unsigned(RAM(8)))) SEVERITY failure;
        ASSERT RAM(9) = STD_LOGIC_VECTOR(to_unsigned(172, 8)) REPORT "TEST FALLITO (WORKING ZONE). Expected  172  found " & INTEGER'image(to_integer(unsigned(RAM(9)))) SEVERITY failure;

        ASSERT false REPORT "Simulation Ended! TEST PASSATO" SEVERITY failure;
    END PROCESS test;

END projecttb;