set terminal pdf font "Times-Roman,10" size 6in, 3in
set autoscale
set logscale y
set logscale x
set title "SHA-3 Candidates on ATI Graphics Card"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"
set key outside
set xr [512:1048576]

plot  "./ati/cube_64_GPU_5runs_16per32.dat" using 1:2 title 'CubeHash (GPU-ATI)', \
      "./ati/skein_64_GPU_10runs.dat" using 1:2 title 'Skein (GPU-ATI)', \
      "./ati/echo_64_GPU_10runs.dat" using 1:2 title 'ECHO (GPU-ATI)'

