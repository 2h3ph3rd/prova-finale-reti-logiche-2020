LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY adder IS
    PORT (
        i0, i1 : IN BIT;
        ci : IN BIT;
        s : OUT BIT;
        co : OUT BIT
    );
END adder;

ARCHITECTURE rtl OF adder IS
BEGIN
    s <= i0 XOR i1 XOR ci;
    co <= (i0 AND i1) OR (i0 AND ci) OR (i1 AND ci);
END rtl;