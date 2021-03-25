FILE_NAME = project
FLAGS = -fsynopsys -fexplicit

.PHONY: report

all:
	ghdl -a $(FLAGS) $(FILE_NAME).vhd
	ghdl -a $(FLAGS) $(FILE_NAME)_tb.vhd
	ghdl -e $(FLAGS) $(FILE_NAME)_tb
	ghdl -r $(FILE_NAME)_tb

clean:
	rm *.o *.aux *.dvi *.log work-*.cf $(FILE_NAME)_tb

report:
	pdflatex -output-directory=report Relazione.tex
