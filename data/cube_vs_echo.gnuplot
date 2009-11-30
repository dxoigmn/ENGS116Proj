set terminal pdf font "Times-Roman,10" size 6in, 3in
set autoscale
set title "CubeHash vs. Echo for varying hash bitlengths at 32 byte message size"
set xlabel "Hash Length (bits)"
set ylabel "Time (ns)"
set key outside
set xr [128:512]

plot  "./cubeVsecho/echo_gpu.dat" using 1:2 with linespoints title 'ECHO (GPU-NVIDIA)', \
      "./cubeVsecho/cube_gpu.dat" using 1:2 with linespoints title 'CubeHash (GPU-NVIDIA)'