set terminal pdf font "Times-Roman,10" size 6in, 3in
set autoscale
set logscale y
set title "SHA-3 Candidates on an NVIDIA Graphics Card and Intel 'Nehalem' CPU"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"
set key outside
set xr [0:8192]

plot	"./nvidia/echo_64_GPU_1run.dat" using 1:2 title 'ECHO (GPU-NVIDIA)', \
	"./nvidia/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-NVIDIA)', \
	"./nvidia/skein_64_GPU_1run.dat" using 1:2 title 'Skein (GPU-NVIDIA)', \
	"./nvidia/echo_64_CPU_10runs.dat" using 1:2 title 'ECHO (CPU)', \
	"./nvidia/cube_64_CPU_5runs_16per32.dat" using 1:2 title 'CubeHash (CPU)', \
	"./nvidia/skein_64_CPU_10runs.dat" using 1:2 title 'Skein (CPU)'

