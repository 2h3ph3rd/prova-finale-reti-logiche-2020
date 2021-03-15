LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY top_level_tb IS
END top_level_tb;

ARCHITECTURE Behavioral OF top_level_tb IS

    CONSTANT clk_period : TIME := 2 ns;
    SIGNAL V : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL A, B, C, D, O : STD_LOGIC;

BEGIN
    UUT : ENTITY work.top_level
        PORT MAP(
            A => V(3),
            B => V(2),
            C => V(1),
            D => V(1),
            O => O
        );
    PROCESS
    BEGIN
        FOR i IN 0 TO 15 LOOP

            V <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            WAIT FOR clk_period;

            -- ASSERT (O = '0') REPORT INTEGER'image(count) & STRING'(") PASSATO") SEVERITY note;
            IF i = 14 OR i = 15 THEN
                ASSERT O = '1' REPORT
                STRING'("i = ")
                & INTEGER'image(i) & (", O = ") & STD_LOGIC'image(O) & (", V = ")
                & STD_LOGIC'image(V(3))
                & STD_LOGIC'image(V(2))
                & STD_LOGIC'image(V(1))
                & STD_LOGIC'image(V(0))
                & STRING'(" - NON PASSATO")
                SEVERITY error;
                ELSE
                ASSERT O = '0' REPORT
                STRING'("i = ")
                & INTEGER'image(i) & (", O = ") & STD_LOGIC'image(O) & (", V = ")
                & STD_LOGIC'image(V(3))
                & STD_LOGIC'image(V(2))
                & STD_LOGIC'image(V(1))
                & STD_LOGIC'image(V(0))
                & STRING'(" - NON PASSATO")
                SEVERITY error;
            END IF;

        END LOOP;
        ASSERT false REPORT "end of test" SEVERITY note;
        WAIT;
    END PROCESS;

END Behavioral;