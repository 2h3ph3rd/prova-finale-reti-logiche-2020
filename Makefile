all:
	ghdl -a -fsynopsys -fexplicit project_tb.vhd
	ghdl -e -fsynopsys -fexplicit project_tb
	ghdl -r -fsynopsys -fexplicit project_tb

clean:
	rm project_tb.o
	rm work-*.cf
	rm e~project_tb.o
	rm project_tb