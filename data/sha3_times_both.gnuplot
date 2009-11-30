set terminal pdf font "Times-Roman,10" size 6in, 3in
set autoscale
set logscale y
set title "SHA-3 Candidates on ATI and NVIDIA Graphics Cards"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"
set key outside
set xr [0:8192]

plot  "./nvidia/echo_64_GPU_1run.dat" using 1:2 title 'ECHO (GPU-NVIDIA)', \
	  "./ati/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-ATI)', \
	  "./nvidia/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-NVIDIA)', \
      "./ati/skein_64_GPU_10runs.dat" using 1:2 title 'Skein (GPU-ATI)', \
      "./nvidia/skein_64_GPU_1run.dat" using 1:2 title 'Skein (GPU-NVIDIA)', \
      "./ati/sha_64_GPU_10runs.dat" using 1:2 title 'SHA-1 (GPU-ATI)', \
      "./ati/echo_64_GPU_10runs.dat" using 1:2 title 'ECHO (GPU-ATI)'

