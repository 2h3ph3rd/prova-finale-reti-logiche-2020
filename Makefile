FILE_NAME = top_level_tb

all:
	ghdl -a -fsynopsys -fexplicit $(FILE_NAME).vhd
	ghdl -e -fsynopsys -fexplicit $(FILE_NAME)
	ghdl -r -fsynopsys -fexplicit $(FILE_NAME)

clean:
	rm *.o
	rm work-*.cf
	rm project_tb