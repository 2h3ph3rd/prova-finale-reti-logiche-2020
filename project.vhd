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
        CHECK_MIN_MAX,
        WRITE_START,
        EQUALIZE_PIXEL,
        WRITE_NEW_PIXEL,
        DONE
    );

    CONSTANT EMPTY_BYTE : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";

    SIGNAL min_pixel_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL max_pixel_value : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL num_cols : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL num_pixels : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL count : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tmp_count : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL pixel_value : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL new_pixel_value : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL shift_level : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL overflow_threshold : STD_LOGIC_VECTOR(7 DOWNTO 0);

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
                    num_pixels <= num_cols * i_data;
                    state_next <= READ_PIXELS_START;

                WHEN READ_PIXELS_START =>
                    count <= "0000000000000000";
                    min_pixel_value <= "11111111";
                    max_pixel_value <= "00000000";
                    -- If image is empty there is nothing to do
                    IF num_pixels = "00000000000000000" THEN
                        state_next <= DONE;
                    ELSE
                        state_after <= CHECK_MIN_MAX;
                        state_next <= READ_NEXT_PIXEL_REQ;
                    END IF;

                WHEN READ_NEXT_PIXEL_REQ =>
                    tmp_count <= count + 1;
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= 2 + count;
                    state_next <= READ_NEXT_PIXEL;

                WHEN READ_NEXT_PIXEL =>
                    count <= tmp_count;
                    pixel_value <= i_data;
                    state_next <= state_after;

                WHEN CHECK_MIN_MAX =>
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
                    count <= "0000000000000000";
                    -- delta_value = max_pixel_value - min_pixel_value
                    -- shift_level = (8 - FLOOR(LOG2(delta_value + 1)))
                    CASE to_integer(unsigned(max_pixel_value - min_pixel_value)) IS
                        WHEN 1 TO 2 =>
                            shift_level <= "111";
                            overflow_threshold <= "00000001";
                        WHEN 3 TO 6 =>
                            shift_level <= "110";
                            overflow_threshold <= "00000011";
                        WHEN 7 TO 14 =>
                            shift_level <= "101";
                            overflow_threshold <= "00000111";
                        WHEN 15 TO 30 =>
                            shift_level <= "100";
                            overflow_threshold <= "00001111";
                        WHEN 31 TO 62 =>
                            shift_level <= "011";
                            overflow_threshold <= "00011111";
                        WHEN 63 TO 126 =>
                            shift_level <= "010";
                            overflow_threshold <= "00111111";
                        WHEN 127 TO 254 =>
                            shift_level <= "001";
                            overflow_threshold <= "01111111";
                        WHEN OTHERS =>
                            shift_level <= "000";
                            overflow_threshold <= "11111111";
                    END CASE;
                    state_after <= EQUALIZE_PIXEL;
                    state_next <= READ_NEXT_PIXEL_REQ;

                WHEN EQUALIZE_PIXEL =>
                    new_pixel_value <= pixel_value - min_pixel_value;
                    state_next <= WRITE_NEW_PIXEL;

                WHEN WRITE_NEW_PIXEL =>
                    o_we <= '1';
                    o_en <= '1';
                    o_address <= 1 + num_pixels + count;

                    -- Check for overflow
                    IF new_pixel_value > overflow_threshold THEN
                        o_data <= "11111111";
                    ELSE
                        CASE shift_level IS
                            WHEN "001" =>
                                o_data <= new_pixel_value(6 DOWNTO 0) & "0";
                            WHEN "010" =>
                                o_data <= new_pixel_value(5 DOWNTO 0) & "00";
                            WHEN "011" =>
                                o_data <= new_pixel_value(4 DOWNTO 0) & "000";
                            WHEN "100" =>
                                o_data <= new_pixel_value(3 DOWNTO 0) & "0000";
                            WHEN "101" =>
                                o_data <= new_pixel_value(2 DOWNTO 0) & "00000";
                            WHEN "110" =>
                                o_data <= new_pixel_value(1 DOWNTO 0) & "000000";
                            WHEN "111" =>
                                o_data <= new_pixel_value(0) & "0000000";
                            WHEN OTHERS =>
                                o_data <= pixel_value;
                        END CASE;
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