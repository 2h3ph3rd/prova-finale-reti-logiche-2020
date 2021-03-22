FILE_NAME = project
FLAGS = -fsynopsys -fexplicit

all:
	ghdl -a $(FLAGS) $(FILE_NAME).vhd
	ghdl -a $(FLAGS) $(FILE_NAME)_tb.vhd
	ghdl -e $(FLAGS) $(FILE_NAME)_tb
	ghdl -r $(FILE_NAME)_tb

clean:
	rm *.o *.aux *.dvi *.log work-*.cf $(FILE_NAME)_tb
