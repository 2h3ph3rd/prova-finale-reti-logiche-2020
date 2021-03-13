LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY top_level IS
    PORT (
        A : IN STD_LOGIC;
        B : IN STD_LOGIC;
        C : IN STD_LOGIC;
        D : IN STD_LOGIC;
        O : OUT STD_LOGIC);
END top_level;

ARCHITECTURE Behavioral OF top_level IS
    SIGNAL AND_1_out_sig : STD_LOGIC;
    SIGNAL OR_out_sig : STD_LOGIC;
BEGIN
    AND_1_out_sig <= A AND B;
    OR_out_sig <= C OR D;
    O <= AND_1_out_sig AND OR_out_sig;
END Behavioral;