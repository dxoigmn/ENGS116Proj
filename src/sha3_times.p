set   autoscale                        # scale axes automatically
set title "SHA-3 Candidates Running Time versus Message Length"
set xlabel "Message Size (bytes)"
set ylabel "Time (ns)"

plot "./oclCubeHash/cube_hash.dat" using 1:2 title 'CubeHash', \
     "./ECHO_OpenCL/echo.dat" using 1:2 title 'ECHO', \
     "./oclSha1/sha1.dat" using 1:2 title 'SHA-1', \
     "./oclSkein/skein.dat" using 1:2 title 'Skein'
