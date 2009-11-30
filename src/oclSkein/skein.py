#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

src   = open('skein.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

interval=64
mult=2
start=8192*2
maxi=2**21
runs=3
datas=[]
for i in range(0,runs,1):
  datas.append([])

data        = "a" * interval
databitlen  = len(data) * 8

hashbitlen  = 512
hashval     = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
hashval_buf     = cl.Buffer(ctx, cl.mem_flags.READ_WRITE, size=hashval.size)

databitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databitlen))
data_buf        = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))

bcnt_buf        = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=4)
b_buf           = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=8*8)
x_buf           = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=8*8)
t_buf           = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=8*2)

for k in range(0, runs,1):
  i=start
	
  # for i in range(0, maxi+interval, interval):
  while(i<maxi):
    print "run %d i=%d" % (k,i)
    events  = []
    datalen = 0
    rundata=[]

    events.append( prg.Init(queue, (1,), bcnt_buf, b_buf, x_buf, t_buf, hashbitlen_buf) )

    for j in range(0, i, interval):
      datalen += databitlen / 8
      events.append( prg.Update(queue, (1,), bcnt_buf, b_buf, x_buf, t_buf, data_buf, databitlen_buf) )

    events.append( prg.Final(queue, (1,),  bcnt_buf, b_buf, x_buf, t_buf, hashval_buf, hashbitlen_buf) )

    events[-1].wait()
    cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()

    datas[k].append(sum(evt.profile.end - evt.profile.start for evt in events))
    i*=2
    print sum(evt.profile.end - evt.profile.start for evt in events)

i=start
k=0
while (i<maxi):
# for i in range(0, (maxi+interval)/interval, 1):
  time=0
  for j in range(0, runs, 1):
    time+=datas[j][k]
  k+=1
  print "%d\t%lu" % (i, time/runs)
  i*=2