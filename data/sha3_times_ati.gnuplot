set terminal pdf font "Times-Roman,10" size 6in, 3in
set autoscale
set logscale y
set title "SHA-3 Candidates on ATI Graphics Card"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"
set key outside
set xr [0:8192]

plot  "./ati/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-ATI)', \
      "./ati/skein_64_GPU_10runs.dat" using 1:2 title 'Skein (GPU-ATI)', \
      "./ati/sha_64_GPU_10runs.dat" using 1:2 title 'SHA-1 (GPU-ATI)', \
      "./ati/echo_64_GPU_10runs.dat" using 1:2 title 'ECHO (GPU-ATI)', \
      "./ati/cube_64_CPU_5runs_16per32.dat" using 1:2 title 'CubeHash (CPU)', \
      "./ati/echo_64_CPU_10runs.dat" using 1:2 title 'ECHO (CPU)', \
      "./ati/sha_64_CPU_10runs.dat" using 1:2 title 'SHA-1 (CPU)', \
      "./ati/skein_64_CPU_10runs.dat" using 1:2 title 'Skein (CPU)'

