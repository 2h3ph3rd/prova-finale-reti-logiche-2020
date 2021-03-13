FILE_NAME = top_level_tb

all:
	ghdl -a -fsynopsys -fexplicit $(FILE_NAME).vhd
	ghdl -e -fsynopsys -fexplicit $(FILE_NAME)
	ghdl -r $(FILE_NAME) --wave=wave.ghw

waves:
	gtkwave wave.ghw

clean:
	rm *.o
	rm work-*.cf
	rm project_tb
	rm *.ghw