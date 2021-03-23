-- Change paths at lines 65, 100, 101 -

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE ieee.std_logic_textio.ALL;
USE STD.textio.ALL;

ENTITY project_tb IS
END project_tb;

ARCHITECTURE projecttb OF project_tb IS
  CONSTANT c_CLOCK_PERIOD : TIME := 100 ns;
  SIGNAL tb_done : STD_LOGIC;
  SIGNAL mem_address : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL tb_rst : STD_LOGIC := '0';
  SIGNAL tb_start : STD_LOGIC := '0';
  SIGNAL tb_clk : STD_LOGIC := '0';
  SIGNAL mem_o_data, mem_i_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
  SIGNAL enable_wire : STD_LOGIC;
  SIGNAL mem_we : STD_LOGIC;

  TYPE ram_type IS ARRAY (65535 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL RAM : ram_type;
  SIGNAL s_read_done : BOOLEAN := false;
  SIGNAL s_read : BOOLEAN := false;
  SHARED VARIABLE pix_num : INTEGER;

  COMPONENT project_reti_logiche IS
    PORT (
      i_clk : IN STD_LOGIC;
      i_start : IN STD_LOGIC;
      i_rst : IN STD_LOGIC;
      i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      o_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      o_done : OUT STD_LOGIC;
      o_en : OUT STD_LOGIC;
      o_we : OUT STD_LOGIC;
      o_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  END COMPONENT project_reti_logiche;
BEGIN
  UUT : project_reti_logiche
  PORT MAP(
    i_clk => tb_clk,
    i_start => tb_start,
    i_rst => tb_rst,
    i_data => mem_o_data,
    o_address => mem_address,
    o_done => tb_done,
    o_en => enable_wire,
    o_we => mem_we,
    o_data => mem_i_data
  );

  p_CLK_GEN : PROCESS IS
  BEGIN
    WAIT FOR c_CLOCK_PERIOD/2;
    tb_clk <= NOT tb_clk;
  END PROCESS p_CLK_GEN;

  MEM : PROCESS (tb_clk)
    FILE read_file : text OPEN read_mode IS "./ram_content.txt"; --<<<<<<<<<<<<<<<<--------------------------------- QUI DA CAMBIARE
    VARIABLE read_line : line;
    VARIABLE R : ram_type;
    VARIABLE handler : INTEGER;

  BEGIN
    IF tb_clk'event AND tb_clk = '1' THEN
      IF s_read THEN
        readline(read_file, read_line);
        read(read_line, pix_num);
        FOR i IN 0 TO (pix_num + 1) LOOP
          readline(read_file, read_line);
          read(read_line, handler);
          RAM(i) <= STD_LOGIC_VECTOR(to_unsigned(handler, 8));
        END LOOP;
        FOR i IN pix_num + 2 TO (2 * pix_num + 1) LOOP
          readline(read_file, read_line);
          read(read_line, handler);
          RAM(i + pix_num) <= STD_LOGIC_VECTOR(to_unsigned(handler, 8));
        END LOOP;
        IF endfile(read_file) THEN
          s_read_done <= true;
        END IF;
      ELSIF enable_wire = '1' THEN
        IF mem_we = '1' THEN
          RAM(conv_integer(mem_address)) <= mem_i_data;
          mem_o_data <= mem_i_data AFTER 1 ns;
        ELSE
          mem_o_data <= RAM(conv_integer(mem_address)) AFTER 1 ns;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  test : PROCESS IS
    FILE write_file : text OPEN write_mode IS "./passati.txt"; --<<<<<<<<<<<<<<<<--------------------------------- QUI DA CAMBIARE
    FILE err_write_file : text OPEN write_mode IS "./non_passati.txt"; --<<<<<<<<<<<<<<<<--------------------------------- QUI DA CAMBIARE
    VARIABLE write_line, err_write_line : line;
    VARIABLE count : INTEGER := 0;
    VARIABLE passed : BOOLEAN := true;
    VARIABLE errors : BOOLEAN := false;
  BEGIN
    WAIT FOR 100 ns;
    LOOP

      count := count + 1;

      IF (s_read_done) THEN
        EXIT;
      END IF;

      s_read <= true; -- richiesta di modifica valori ram
      WAIT FOR c_CLOCK_PERIOD;
      s_read <= false;
      WAIT FOR c_CLOCK_PERIOD;
      tb_rst <= '1';
      WAIT FOR c_CLOCK_PERIOD;
      tb_rst <= '0';
      WAIT FOR c_CLOCK_PERIOD;
      tb_start <= '1';
      WAIT FOR c_CLOCK_PERIOD;
      WAIT UNTIL tb_done = '1';
      WAIT FOR c_CLOCK_PERIOD;
      tb_start <= '0';
      WAIT UNTIL tb_done = '0';
      WAIT FOR c_CLOCK_PERIOD;

      FOR i IN 2 + pix_num TO 2 * pix_num + 1 LOOP
        IF (RAM(i) /= RAM(i + pix_num)) THEN
          passed := false;
          EXIT;
        END IF;
      END LOOP;

      IF (passed) THEN
        write(write_line, INTEGER'image(count) & STRING'(") PASSATO")); --- passati.txt
        writeline(write_file, write_line);
      ELSE
        write(err_write_line, INTEGER'image(count) & STRING'(") NON PASSATO")); --- non_passati.txt
        writeline(err_write_file, err_write_line);
        errors := true;
      END IF;

      passed := true;
      ---------- fine casi di test ---------- 
    END LOOP;

    IF (NOT errors) THEN
      write(err_write_line, STRING'("Tutti i test sono stati passati"));
      writeline(err_write_file, err_write_line);
    END IF;

    file_close(write_file);
    file_close(err_write_file);
    std.env.finish;

  END PROCESS test;

END projecttb;