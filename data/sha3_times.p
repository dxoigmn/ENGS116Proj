set   autoscale                        # scale axes automatically
set logscale y
set title "SHA-3 Candidates Running Time versus Message Length"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"

plot "skein_32_CPU_10runs.dat" using 1:2 title 'Skein-32-CPU', \
     "skein_32_GPU_10runs.dat" using 1:2 title 'Skein-32-GPU'
plot "skein_64_CPU_10runs.dat" using 1:2 title 'Skein-64-CPU', \
     "skein_64_GPU_10runs.dat" using 1:2 title 'Skein-64-GPU'
