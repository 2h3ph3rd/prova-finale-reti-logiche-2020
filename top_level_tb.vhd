LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY top_level_tb IS
END top_level_tb;

ARCHITECTURE Behavioral OF top_level_tb IS

    COMPONENT top_level IS
        PORT (
            A : IN STD_LOGIC;
            B : IN STD_LOGIC;
            C : IN STD_LOGIC;
            D : IN STD_LOGIC;
            O : OUT STD_LOGIC
        );
    END COMPONENT top_level;

    SIGNAL V : STD_LOGIC_VECTOR (3 DOWNTO 0);
    SIGNAL O : STD_LOGIC;
    CONSTANT clk_period : TIME := 10 ns;

    CONSTANT pattern_array : ARRAY(STD_LOGIC_VECTOR(3 DOWNTO 0)) :=
    (
    0 <= "0000",
    1 <= "0001",
    OTHERS <= 0
    );

BEGIN
    UUT : top_level
    PORT MAP(
        A => V(0),
        B => V(1),
        C => V(2),
        D => V(3),
        O => O
    );

    PROCESS
    BEGIN
        FOR i IN 0 TO 16 LOOP
            V <= "0000";
            WAIT FOR clk_period;
        END LOOP;
        ASSERT false REPORT "end of test" SEVERITY note;
        WAIT;
    END PROCESS;

END Behavioral;