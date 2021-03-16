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
        SAVE_SHIFT_LEVEL,
        WRITE_DATA_READ,
        WRITE_DATA_REQ,
        EQUALIZE_PIXEL_SUBTRACT,
        EQUALIZE_PIXEL_SHIFT,
        WRITE_DATA,
        WRITE_END,
        DONE
    );

    CONSTANT MAX_POSSIBLE_VALUE : INTEGER := 255;
    CONSTANT EMPTY_VECTOR : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
    CONSTANT MAX_DIM : INTEGER := 128;

    SIGNAL min_pixel_value : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;
    SIGNAL max_pixel_value : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL cols : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rows : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dim : INTEGER RANGE 0 TO MAX_DIM * MAX_DIM;

    -- Add two position to manage double shift
    SIGNAL pixel : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tmp_pixel : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL unsigned_tmp_pixel : UNSIGNED (15 DOWNTO 0);
    SIGNAL new_pixel : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL shift_level : INTEGER RANGE 0 TO 8;
    SIGNAL delta_value : INTEGER RANGE 0 TO MAX_POSSIBLE_VALUE;

    SIGNAL count : INTEGER;
    SIGNAL tmp_count : INTEGER;

    SIGNAL state_curr : state;
    SIGNAL state_next : state;
    SIGNAL state_after_count_inc : state;

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
                    o_done <= '0';
                    -- Initialize all values
                    cols <= EMPTY_VECTOR;
                    rows <= EMPTY_VECTOR;
                    pixel <= EMPTY_VECTOR;
                    tmp_pixel <= EMPTY_VECTOR & EMPTY_VECTOR;

                    min_pixel_value <= MAX_POSSIBLE_VALUE;

                    shift_level <= 0;
                    delta_value <= 0;
                    dim <= 0;
                    max_pixel_value <= 0;
                    tmp_count <= 0;
                    count <= 0;
                    new_pixel <= 0;
                    -- Check for start
                    IF i_start = '1' THEN
                        state_next <= READ_COLS_REQ;
                    ELSE
                        state_next <= RESET;
                    END IF;

                WHEN READ_COLS_REQ =>
                    -- Enable memory access
                    o_en <= '1';
                    o_we <= '0';
                    -- First value stored in memory is num columns
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(0, 16));
                    state_next <= READ_COLS;

                WHEN READ_COLS =>
                    -- Save num cols
                    cols <= i_data;
                    state_next <= READ_ROWS_REQ;

                WHEN READ_ROWS_REQ =>
                    -- Enable memory access
                    o_en <= '1';
                    o_we <= '0';
                    -- Second value stored in memory is num rows
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1, 16));
                    state_next <= READ_ROWS;

                WHEN READ_ROWS =>
                    -- Save num rows
                    rows <= i_data;
                    state_next <= READ_DATA_CHECK;

                WHEN READ_DATA_CHECK =>
                    -- Now we have both rows and columns number
                    -- Calculate image dimension
                    dim <= to_integer(unsigned(rows)) * to_integer(unsigned(cols));
                    -- If image is empty there is nothing to do
                    IF rows = EMPTY_VECTOR OR cols = EMPTY_VECTOR THEN
                        state_next <= DONE;
                    ELSE
                        state_next <= READ_DATA_REQ;
                    END IF;

                WHEN READ_DATA_REQ =>
                    -- Enable memory access
                    o_we <= '0';
                    o_en <= '1';
                    state_after_count_inc <= READ_DATA;
                    state_next <= INC_TMP_COUNT;

                WHEN INC_TMP_COUNT =>
                    tmp_count <= count + 1;
                    state_next <= UPDATE_COUNT;

                WHEN UPDATE_COUNT =>
                    count <= tmp_count;
                    state_next <= ADDR_CALC;

                WHEN ADDR_CALC =>
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1 + count, 16));
                    state_next <= state_after_count_inc;

                WHEN READ_DATA =>
                    -- read pixel
                    pixel <= i_data;
                    state_next <= CHECK_FOR_MIN_AND_MAX;

                WHEN CHECK_FOR_MIN_AND_MAX =>
                    -- Check for min
                    IF to_integer(unsigned(pixel)) < min_pixel_value THEN
                        min_pixel_value <= to_integer(unsigned(pixel));
                    END IF;

                    -- Check for max
                    IF to_integer(unsigned(pixel)) > max_pixel_value THEN
                        max_pixel_value <= to_integer(unsigned(pixel));
                    END IF;

                    -- Check if there are remaining pixels
                    IF count < dim THEN
                        state_next <= READ_DATA_REQ;
                    ELSE
                        state_next <= WRITE_START;
                    END IF;

                WHEN WRITE_START =>
                    -- Initialize counter
                    count <= 0;
                    -- DELTA_VALUE = MAX_PIXEL_VALUE - MIN_PIXEL_VALUE
                    delta_value <= max_pixel_value - min_pixel_value;
                    state_next <= SAVE_SHIFT_LEVEL;

                WHEN SAVE_SHIFT_LEVEL =>
                    -- Define shift_level
                    -- shift_level = (8 – FLOOR(LOG2(delta_value + 1)))
                    IF delta_value = 0 THEN
                        shift_level <= 8;
                    ELSIF delta_value > 1 AND delta_value < 3 THEN
                        shift_level <= 7;
                    ELSIF delta_value > 3 AND delta_value < 7 THEN
                        shift_level <= 6;
                    ELSIF delta_value > 7 AND delta_value < 15 THEN
                        shift_level <= 5;
                    ELSIF delta_value > 15 AND delta_value < 31 THEN
                        shift_level <= 4;
                    ELSIF delta_value > 31 AND delta_value < 63 THEN
                        shift_level <= 3;
                    ELSIF delta_value > 63 AND delta_value < 127 THEN
                        shift_level <= 2;
                    ELSE
                        shift_level <= 1;
                    END IF;
                    state_next <= WRITE_DATA_READ;

                WHEN WRITE_DATA_READ =>
                    -- Request to read data
                    o_we <= '0';
                    o_en <= '1';
                    -- Call count increment
                    state_after_count_inc <= WRITE_DATA_REQ;
                    state_next <= INC_TMP_COUNT;

                WHEN WRITE_DATA_REQ =>
                    -- Read pixel requested in WRITE_DATA_READ
                    pixel <= i_data;
                    -- Set writing access
                    o_we <= '1';
                    o_en <= '1';
                    state_next <= EQUALIZE_PIXEL_SUBTRACT;

                WHEN EQUALIZE_PIXEL_SUBTRACT =>
                    -- TEMP_PIXEL = (CURRENT_PIXEL_VALUE - MIN_PIXEL_VALUE) << SHIFT_LEVEL
                    tmp_pixel <= EMPTY_VECTOR & (pixel - STD_LOGIC_VECTOR(to_unsigned(min_pixel_value, 8)));
                    state_next <= EQUALIZE_PIXEL_SHIFT;

                WHEN EQUALIZE_PIXEL_SHIFT =>
                    unsigned_tmp_pixel <= shift_left(unsigned(tmp_pixel), shift_level);
                    state_next <= WRITE_DATA;

                WHEN WRITE_DATA =>
                    -- Check for overflow
                    IF to_integer(unsigned_tmp_pixel) > 255 THEN
                        new_pixel <= 255;
                    ELSE
                        new_pixel <= to_integer(unsigned_tmp_pixel);
                    END IF;

                    -- Write new equalized pixel
                    o_data <= STD_LOGIC_VECTOR(to_unsigned(new_pixel, 8));
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1 + dim + count, 16));

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