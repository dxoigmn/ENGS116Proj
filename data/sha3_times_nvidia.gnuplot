set terminal pdf font "Times-Roman,10" size 5in, 2in
set autoscale
set logscale y
set title "SHA-3 Candidates on an ATI Graphics Card"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"
set key outside
set xr [0:8192]

plot "./nvidia/cube_64_CPU_5runs_16per32.dat" using 1:2 title 'CubeHash (CPU)', \
     "./nvidia/echo_64_CPU_10runs.dat" using 1:2 title 'ECHO (CPU)', \
     "./nvidia/skein_64_CPU_10runs.dat" using 1:2 title 'Skein (CPU)', \
     "./nvidia/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-ATI)', \
     "./nvidia/echo_64_GPU_10runs.dat" using 1:2 title 'ECHO (GPU-ATI)', \
     "./nvidia/skein_64_GPU_10runs.dat" using 1:2 title 'Skein (GPU-ATI)'

