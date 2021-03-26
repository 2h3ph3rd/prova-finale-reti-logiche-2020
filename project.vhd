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
    TYPE state_next_TYPE IS (
        RESET,
        MEM_WAIT,
        READ_COLS_REQ,
        READ_COLS,
        READ_ROWS_REQ,
        READ_ROWS,
        READ_PIXELS_START,
        READ_PIXEL_REQ,
        READ_PIXEL,
        CHECK_MIN_MAX,
        WRITE_START,
        EQUALIZE_PIXEL,
        WRITE_NEW_PIXEL,
        DONE
    );

    SIGNAL min_pixel_value : INTEGER RANGE 0 TO 255;
    SIGNAL max_pixel_value : INTEGER RANGE 0 TO 255;

    SIGNAL num_cols : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL num_pixels : INTEGER RANGE 0 TO 13684;

    SIGNAL count : INTEGER RANGE 0 TO 13684;
    SIGNAL tmp_count : INTEGER RANGE 0 TO 13684;

    SIGNAL pixel_value : INTEGER RANGE 0 TO 255;
    SIGNAL new_pixel_value : INTEGER RANGE 0 TO 255;

    SIGNAL shift_level : INTEGER RANGE 0 TO 7;
    SIGNAL overflow_threshold : INTEGER RANGE 0 TO 255;

    SIGNAL state_next : state_next_TYPE;
    SIGNAL state_after_wait : state_next_TYPE;
    SIGNAL state_after_read : state_next_TYPE;

BEGIN
    PROCESS (i_clk)
    BEGIN
        IF (rising_edge(i_clk)) THEN

            IF (i_rst = '1') THEN
                state_next <= RESET;
            END IF;

            CASE state_next IS

                WHEN RESET =>
                    o_en <= '0';
                    o_we <= '0';
                    o_done <= '0';
                    IF i_start = '1' THEN
                        state_next <= READ_COLS_REQ;
                    ELSE
                        state_next <= RESET;
                    END IF;

                WHEN MEM_WAIT =>
                    o_we <= '0';
                    o_en <= '0';
                    state_next <= state_after_wait;

                WHEN READ_COLS_REQ =>
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= "0000000000000000";
                    state_after_wait <= READ_COLS;
                    state_next <= MEM_WAIT;

                WHEN READ_COLS =>
                    num_cols <= i_data;
                    state_next <= READ_ROWS_REQ;

                WHEN READ_ROWS_REQ =>
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= "0000000000000001";
                    state_after_wait <= READ_ROWS;
                    state_next <= MEM_WAIT;

                WHEN READ_ROWS =>
                    num_pixels <= to_integer(unsigned(i_data * num_cols));
                    state_next <= READ_PIXELS_START;

                WHEN READ_PIXELS_START =>
                    count <= 0;
                    min_pixel_value <= 255;
                    max_pixel_value <= 0;
                    -- If the image is empty there is nothing to do
                    IF num_pixels = 0 THEN
                        state_next <= DONE;
                    ELSE
                        state_after_read <= CHECK_MIN_MAX;
                        state_next <= READ_PIXEL_REQ;
                    END IF;

                WHEN READ_PIXEL_REQ =>
                    tmp_count <= count + 1;
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(2 + count, 16));
                    state_after_wait <= READ_PIXEL;
                    state_next <= MEM_WAIT;

                WHEN READ_PIXEL =>
                    count <= tmp_count;
                    pixel_value <= to_integer(unsigned((i_data)));
                    state_next <= state_after_read;

                WHEN CHECK_MIN_MAX =>
                    IF pixel_value < min_pixel_value THEN
                        min_pixel_value <= pixel_value;
                    ELSIF pixel_value > max_pixel_value THEN
                        max_pixel_value <= pixel_value;
                    END IF;

                    -- Check for remaining pixels
                    IF count < num_pixels THEN
                        state_next <= READ_PIXEL_REQ;
                    ELSE
                        state_next <= WRITE_START;
                    END IF;

                WHEN WRITE_START =>
                    count <= 0;
                    -- delta_value = max_pixel_value - min_pixel_value
                    -- shift_level = (8 - FLOOR(LOG2(delta_value + 1)))
                    CASE max_pixel_value - min_pixel_value IS
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
                    state_after_read <= EQUALIZE_PIXEL;
                    state_next <= READ_PIXEL_REQ;

                WHEN EQUALIZE_PIXEL =>
                    -- TEMP_PIXEL = CURRENT_PIXEL_VALUE - MIN_PIXEL_VALUE 
                    new_pixel_value <= pixel_value - min_pixel_value;
                    state_next <= WRITE_NEW_PIXEL;

                WHEN WRITE_NEW_PIXEL =>
                    o_we <= '1';
                    o_en <= '1';
                    o_address <= STD_LOGIC_VECTOR(to_unsigned(1 + num_pixels + count, 16));

                    -- Check for overflow
                    -- NEW_PIXEL_VALUE = MIN(255 , TEMP_PIXEL << SHIFT_LEVEL)
                    IF new_pixel_value > overflow_threshold THEN
                        o_data <= "11111111";
                    ELSE
                        o_data <= STD_LOGIC_VECTOR(shift_left(to_unsigned(new_pixel_value, 8), shift_level));
                    END IF;

                    -- Check for remaining pixels
                    IF count < num_pixels THEN
                        state_next <= READ_PIXEL_REQ;
                    ELSE
                        state_next <= DONE;
                    END IF;

                WHEN DONE =>
                    o_we <= '0';
                    o_en <= '0';
                    o_done <= '1';
                    state_next <= RESET;

            END CASE;
        END IF;
    END PROCESS;
END;