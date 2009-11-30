#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

interval=64
maxi=8192
runs=10
datas=[]
for i in range(0,runs,1):
  datas.append([])

src   = open('sha1.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

hashbitlen      = 160
hashval         = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
hashval_buf     = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=hashval.size)

data            = "a" * interval
databytelen     = len(data)

data_buf        = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))
databytelen_buf = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databytelen))

state_buf       = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=8*5)
count_buf       = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=8*2)
buffer_buf      = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=1*64)

for k in range(0, runs,1):
  for i in range(1, maxi+interval, interval):
    events  = []
    datalen = 0
    events.append( prg.Init(queue, (1,), state_buf, count_buf) )

    for j in range(0, i, interval):
      datalen += databytelen
      events.append( prg.Update(queue, (1,), state_buf, count_buf, buffer_buf, data_buf, databytelen_buf) )
  
    events.append( prg.Final(queue, (1,), state_buf, count_buf, buffer_buf, hashval_buf) )

    events[-1].wait()
    cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()

    datas[k].append(sum(evt.profile.end - evt.profile.start for evt in events))

for i in range(0, (maxi+interval)/interval, 1):
  time=0
  for j in range(0, runs, 1):
    time+=datas[j][i]
  print "%d\t%lu" % (i*interval, time/runs)
  # hashval_hex = ""
  # for i in xrange(0, hashval.size):
  #   hashval_hex += "%02x" % hashval[i]
  # 
  # print "%d\t%lu\t%s" % (datalen, sum(evt.profile.end - evt.profile.start for evt in events), hashval_hex)