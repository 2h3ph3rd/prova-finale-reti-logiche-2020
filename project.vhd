----------------------------------------------------------------------------------
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno accademico 2020/2021
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
    TYPE STATE_TYPE IS (
        RESET,
        READ_NUM_COLS_REQ,
        READ_NUM_COLS,
        READ_NUM_ROWS_REQ,
        READ_NUM_ROWS,
        READ_PIXELS_START,
        READ_NEXT_PIXEL_REQ,
        READ_NEXT_PIXEL,
        CHECK_FOR_MIN_AND_MAX,
        WRITE_START,
        WRITE_NEW_PIXEL,
        DONE
    );

    SIGNAL min_pixel_value : INTEGER RANGE 0 TO 255;
    SIGNAL max_pixel_value : INTEGER RANGE 0 TO 255;

    SIGNAL num_cols : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL num_rows : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL num_pixels : INTEGER RANGE 0 TO 16384;

    SIGNAL pixel_value : INTEGER RANGE 0 TO 255;
    SIGNAL shift_level : INTEGER RANGE 0 TO 8;
    SIGNAL overflow_threshold : INTEGER RANGE 0 TO 255;

    SIGNAL count : INTEGER;
    SIGNAL tmp_count : INTEGER;

    SIGNAL state_curr : STATE_TYPE;
    SIGNAL state_next : STATE_TYPE;
    SIGNAL state_after : STATE_TYPE;

BEGIN
    PROCESS (i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN

            IF (i_rst = '1') THEN
                state_curr <= RESET;
            ELSE
                state_curr <= state_next;
            END IF;

            CASE state_curr IS

                WHEN RESET =>
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '0';
                    IF i_start = '1' THEN
                        state_next <= READ_NUM_COLS_REQ;
                    ELSE
                        state_next <= RESET;
                    END IF;

                WHEN READ_NUM_COLS_REQ =>
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= "0000000000000000";
                    state_next <= READ_NUM_COLS;

                WHEN READ_NUM_COLS =>
                    num_cols <= i_data;
                    state_next <= READ_NUM_ROWS_REQ;

                WHEN READ_NUM_ROWS_REQ =>
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= "0000000000000001";
                    state_next <= READ_NUM_ROWS;

                WHEN READ_NUM_ROWS =>
                    num_rows <= i_data;
                    state_next <= READ_PIXELS_START;

                WHEN READ_PIXELS_START =>
                    count <= 0;
                    min_pixel_value <= 255;
                    max_pixel_value <= 0;
                    num_pixels <= conv_integer(num_rows) * conv_integer(num_cols);
                    -- If image is empty there is nothing to do
                    IF num_pixels = 0 THEN
                        state_next <= DONE;
                    ELSE
                        state_after <= CHECK_FOR_MIN_AND_MAX;
                        state_next <= READ_NEXT_PIXEL_REQ;
                    END IF;

                WHEN READ_NEXT_PIXEL_REQ =>
                    tmp_count <= count + 1;
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(2 + count, 16));
                    state_next <= READ_NEXT_PIXEL;

                WHEN READ_NEXT_PIXEL =>
                    count <= tmp_count;
                    pixel_value <= conv_integer(i_data);
                    state_next <= state_after;

                WHEN CHECK_FOR_MIN_AND_MAX =>
                    IF pixel_value < min_pixel_value THEN
                        min_pixel_value <= pixel_value;
                    ELSIF pixel_value > max_pixel_value THEN
                        max_pixel_value <= pixel_value;
                    END IF;

                    -- Check for remaining pixels
                    IF count < num_pixels THEN
                        state_next <= READ_NEXT_PIXEL_REQ;
                    ELSE
                        state_next <= WRITE_START;
                    END IF;

                WHEN WRITE_START =>
                    count <= 0;
                    -- delta_value = max_pixel_value - min_pixel_value
                    -- shift_level = (8 – FLOOR(LOG2(delta_value + 1)))
                    CASE max_pixel_value - min_pixel_value IS
                        WHEN 0 =>
                            shift_level <= 8;
                            overflow_threshold <= 0;
                        WHEN 1 TO 2 =>
                            shift_level <= 7;
                            overflow_threshold <= 1;
                        WHEN 3 TO 6 =>
                            shift_level <= 6;
                            overflow_threshold <= 3;
                        WHEN 7 TO 14 =>
                            shift_level <= 5;
                            overflow_threshold <= 7;
                        WHEN 15 TO 30 =>
                            shift_level <= 4;
                            overflow_threshold <= 15;
                        WHEN 31 TO 62 =>
                            shift_level <= 3;
                            overflow_threshold <= 31;
                        WHEN 63 TO 126 =>
                            shift_level <= 2;
                            overflow_threshold <= 63;
                        WHEN 127 TO 254 =>
                            shift_level <= 1;
                            overflow_threshold <= 127;
                        WHEN OTHERS =>
                            shift_level <= 0;
                            overflow_threshold <= 255;
                    END CASE;
                    state_after <= WRITE_NEW_PIXEL;
                    state_next <= READ_NEXT_PIXEL_REQ;

                WHEN WRITE_NEW_PIXEL =>
                    o_we <= '1';
                    o_en <= '1';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1 + num_pixels + count, 16));

                    -- Check for overflow
                    IF pixel_value > overflow_threshold THEN
                        o_data <= "11111111";
                    ELSE
                        o_data <= STD_LOGIC_VECTOR(shift_left(to_unsigned(pixel_value - min_pixel_value, 8), shift_level));
                    END IF;

                    -- Check for remaining pixels
                    IF count < num_pixels THEN
                        state_next <= READ_NEXT_PIXEL_REQ;
                    ELSE
                        state_next <= DONE;
                    END IF;

                WHEN DONE =>
                    o_done <= '1';
                    state_next <= RESET;

            END CASE;
        END IF;
    END PROCESS;
END;