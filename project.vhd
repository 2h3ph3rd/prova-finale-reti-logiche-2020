----------------------------------------------------------------------------------
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno 2020/2021
-- 
--
-- Francesco Pastore (Codice persona 10629332)
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
    TYPE state IS (
        RESET,
        READ_START,
        READ_COLS_REQ,
        READ_COLS,
        READ_ROWS_REQ,
        READ_ROWS,
        READ_DATA_REQ,
        READ_DATA,
        WRITE_START,
        WRITE_DATA_REQ,
        WRITE_DATA,
        WRITE_END,
        DONE
    );

    CONSTANT MAX_POSSIBLE_VALUE : INTEGER := 255;
    CONSTANT MAX_DIM : INTEGER := 128;

    SIGNAL min : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;
    SIGNAL max : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL columns : INTEGER RANGE 0 TO MAX_DIM;
    SIGNAL rows : INTEGER RANGE 0 TO MAX_DIM;
    SIGNAL dim : INTEGER RANGE 0 TO MAX_DIM * MAX_DIM;

    -- Add two position to manage double shift
    SIGNAL temp_pixel : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pixel : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL shift_level : INTEGER RANGE 0 TO 8;
    SIGNAL delta_value : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL count : INTEGER;

    SIGNAL state_curr : state;
    SIGNAL state_next : state;

BEGIN
    main : PROCESS (i_clk, i_rst)
    BEGIN

        IF (rising_edge(i_clk)) THEN

            IF (i_rst = '1') THEN
                state_curr <= RESET;
            ELSE
                state_curr <= state_next;
            END IF;

            CASE state_curr IS

                WHEN RESET =>
                    -- Initialize all values
                    min <= MAX_POSSIBLE_VALUE;
                    max <= 0;
                    count <= 0;
                    columns <= 0;
                    rows <= 0;
                    -- Check start
                    IF (i_start = '1') THEN
                        o_done <= '0';
                        state_next <= READ_START;
                    ELSE
                        state_next <= RESET;
                    END IF;

                WHEN READ_START =>
                    -- Enable memory access
                    o_en <= '1';
                    state_next <= READ_COLS_REQ;

                WHEN READ_COLS_REQ =>
                    -- First value stored in memory is num columns
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(0, 16));
                    state_next <= READ_COLS;

                WHEN READ_COLS =>
                    -- Save num columns
                    columns <= to_integer(unsigned(i_data));
                    state_next <= READ_ROWS_REQ;

                WHEN READ_ROWS_REQ =>
                    -- Second value stored in memory is num rows
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1, 16));
                    state_next <= READ_ROWS;

                WHEN READ_ROWS =>
                    -- Save num rows
                    rows <= to_integer(unsigned(i_data));
                    -- Now we have both rows and columns number
                    -- Calculate image dimension
                    dim <= rows * columns;
                    -- If image is empty there is nothing to do
                    IF dim = 0 THEN
                        state_next <= DONE;
                    ELSE
                        state_next <= READ_DATA_REQ;
                    END IF;

                WHEN READ_DATA_REQ =>
                    -- Request for image pixel
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(count, 16));
                    count <= count + 1;
                    state_next <= READ_DATA;

                WHEN READ_DATA =>
                    pixel <= to_integer(unsigned(i_data));
                    -- Check for min
                    IF pixel < min THEN
                        min <= pixel;
                    END IF;
                    -- Check for max
                    IF pixel > max THEN
                        max <= pixel;
                    END IF;
                    -- Check if there are remaining pixels
                    IF count < dim THEN
                        state_next <= READ_DATA_REQ;
                    ELSE
                        state_next <= WRITE_START;
                    END IF;

                WHEN WRITE_START =>
                    o_we <= '1';
                    -- shift_level = max - min
                    delta_value <= max - min;
                    count <= 0;

                    -- Define shift_level
                    -- shift_level = (8 – FLOOR(LOG2(delta_value + 1)))
                    IF delta_value = 0 THEN
                        shift_level <= 8;
                    ELSIF delta_value > 1 OR delta_value < 3 THEN
                        shift_level <= 7;
                    ELSIF delta_value > 3 OR delta_value < 7 THEN
                        shift_level <= 6;
                    ELSIF delta_value > 7 OR delta_value < 15 THEN
                        shift_level <= 5;
                    ELSIF delta_value > 15 OR delta_value < 31 THEN
                        shift_level <= 4;
                    ELSIF delta_value > 31 OR delta_value < 63 THEN
                        shift_level <= 3;
                    ELSIF delta_value > 63 OR delta_value < 127 THEN
                        shift_level <= 2;
                    ELSE
                        shift_level <= 1;
                    END IF;
                    state_next <= WRITE_DATA_REQ;

                WHEN WRITE_DATA_REQ =>
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(count, 16));
                    count <= count + 1;
                    state_next <= WRITE_END;

                WHEN WRITE_DATA =>
                    temp_pixel <= i_data;
                    pixel <= to_integer(unsigned(temp_pixel & "00"));

                    -- Check for overflow
                    -- TODO: da sistemare
                    IF pixel < to_integer(unsigned(temp_pixel)) THEN
                        pixel <= 255;
                    END IF;

                    o_data <= STD_LOGIC_VECTOR(to_unsigned(pixel, 8));

                    -- Check if there are remaining pixels
                    IF count < dim THEN
                        state_next <= WRITE_DATA_REQ;
                    ELSE
                        state_next <= WRITE_END;
                    END IF;

                WHEN WRITE_END =>
                    o_en <= '0';
                    o_we <= '0';
                    state_next <= DONE;

                WHEN DONE =>
                    o_done <= '1';
                    state_next <= RESET;
            END CASE;
        END IF;
    END PROCESS;
END Behavioral;