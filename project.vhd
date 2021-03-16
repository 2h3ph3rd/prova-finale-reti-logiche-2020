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
        READ_DATA_CHECK,
        READ_DATA_REQ,
        READ_DATA,
        INC_TMP_COUNT,
        UPDATE_COUNT,
        ADDR_CALC,
        CHECK_FOR_MIN_AND_MAX,
        WRITE_START,
        WRITE_DATA_READ,
        WRITE_DATA_REQ,
        WRITE_DATA,
        WRITE_END,
        DONE
    );

    CONSTANT MAX_POSSIBLE_VALUE : INTEGER := 255;
    CONSTANT MAX_DIM : INTEGER := 128;

    SIGNAL min : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;
    SIGNAL max : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL cols : INTEGER RANGE 0 TO MAX_DIM;
    SIGNAL rows : INTEGER RANGE 0 TO MAX_DIM;
    SIGNAL dim : INTEGER RANGE 0 TO MAX_DIM * MAX_DIM;

    -- Add two position to manage double shift
    SIGNAL byte : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL pixel : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL shift_level : INTEGER RANGE 0 TO 8;
    SIGNAL delta_value : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL count : INTEGER;
    SIGNAL tmp_count : INTEGER;

    SIGNAL state_curr : state;
    SIGNAL state_next : state;

BEGIN
    main : PROCESS (i_clk)
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
                    tmp_count <= 0;
                    count <= 0;
                    cols <= 0;
                    rows <= 0;
                    byte <= "00000000";
                    pixel <= 0;
                    shift_level <= 0;
                    delta_value <= 0;
                    dim <= 0;
                    -- Check for start
                    IF i_start = '1' THEN
                        o_done <= '0';
                        state_next <= READ_START;
                    ELSE
                        state_next <= RESET;
                    END IF;

                WHEN READ_START =>
                    -- Enable memory access
                    o_we <= '0';
                    o_en <= '1';

                    state_next <= READ_COLS_REQ;

                WHEN READ_COLS_REQ =>
                    -- First value stored in memory is num columns
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(0, 16));

                    state_next <= READ_COLS;

                WHEN READ_COLS =>
                    -- Save num columns
                    cols <= to_integer(unsigned(i_data));

                    state_next <= READ_ROWS_REQ;

                WHEN READ_ROWS_REQ =>
                    -- Second value stored in memory is num rows
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1, 16));

                    state_next <= READ_ROWS;

                WHEN READ_ROWS =>
                    -- Save num rows
                    rows <= to_integer(unsigned(i_data));

                    state_next <= READ_DATA_CHECK;

                WHEN READ_DATA_CHECK =>
                    -- Now we have both rows and columns number
                    -- Calculate image dimension
                    dim <= rows * cols;
                    -- If image is empty there is nothing to do
                    IF dim = 0 THEN
                        state_next <= DONE;
                    ELSE
                        state_next <= READ_DATA_REQ;
                    END IF;

                WHEN READ_DATA_REQ =>
                    -- Enable memory access
                    o_we <= '0';
                    o_en <= '1';
                    state_next <= INC_TMP_COUNT;

                WHEN INC_TMP_COUNT =>
                    tmp_count <= count + 1;
                    state_next <= UPDATE_COUNT;

                WHEN UPDATE_COUNT =>
                    count <= tmp_count;
                    state_next <= ADDR_CALC;

                WHEN ADDR_CALC =>
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(count + 2, 16));
                    state_next <= READ_DATA;

                WHEN READ_DATA =>
                    -- read pixel
                    pixel <= to_integer(unsigned(i_data));
                    state_next <= CHECK_FOR_MIN_AND_MAX;

                WHEN CHECK_FOR_MIN_AND_MAX =>
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
                    state_next <= READ_DATA_REQ;

                WHEN WRITE_START =>
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

                    state_next <= WRITE_DATA_READ;

                WHEN WRITE_DATA_READ =>
                    -- Request to read data
                    o_we <= '0';
                    o_en <= '1';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(count, 16));

                    state_next <= WRITE_DATA_REQ;

                WHEN WRITE_DATA_REQ =>
                    -- Read pixel requested in WRITE_DATA_READ
                    byte <= i_data;

                    -- Set we and enable to 1 to allow writing on memory
                    o_we <= '1';
                    o_en <= '1';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(2 + dim + count, 16));
                    count <= count + 1;

                    state_next <= WRITE_DATA;

                WHEN WRITE_DATA =>
                    -- Check for overflow
                    -- TODO: da sistemare
                    IF byte(7) = '1' OR byte(6) = '1' THEN
                        pixel <= 255;
                    ELSE
                        pixel <= to_integer(unsigned(byte & "00"));
                    END IF;

                    o_data <= STD_LOGIC_VECTOR(to_unsigned(pixel, 8));

                    -- Check if there are remaining pixels
                    IF count < dim THEN
                        state_next <= WRITE_DATA_READ;
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