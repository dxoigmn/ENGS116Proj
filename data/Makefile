plots: ati nvidia both

ati: sha3_times_ati.pdf

nvidia: sha3_times_nvidia.pdf

both: sha3_times_both.pdf

%.pdf: %.gnuplot
	gnuplot $< > $@
	
clean:
	rm *.pdf