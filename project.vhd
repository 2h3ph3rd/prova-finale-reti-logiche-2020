----------------------------------------------------------------------------------
-- Progetto di reti logiche 2021
-- Prof. Gianluca Palermo
-- 
--
-- Codice sviluppato da Francesco Pastore
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY project_reti_logiche IS
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst : IN STD_LOGIC;
        i_start : IN STD_LOGIC;
        i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        o_done : OUT STD_LOGIC;
        o_en : OUT STD_LOGIC;
        o_we : OUT STD_LOGIC;
        o_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END project_reti_logiche;

ARCHITECTURE Behavioral OF project_reti_logiche IS

BEGIN
    o_done <= '1';
END Behavioral;