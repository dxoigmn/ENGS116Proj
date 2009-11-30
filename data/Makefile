plots: ati nvidia both cubeVecho

ati: sha3_times_ati.pdf

nvidia: sha3_times_nvidia.pdf

both: sha3_times_both.pdf

cubeVecho: cube_vs_echo.pdf

%.pdf: %.gnuplot
	gnuplot $< > $@
	
clean:
	rm *.pdf