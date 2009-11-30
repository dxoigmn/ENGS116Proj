plots: ati nvidia

ati: sha3_times_ati.pdf

nvidia: sha3_times_nvidia.pdf

%.pdf: %.gnuplot
	gnuplot $< > $@
	
clean:
	rm *.pdf