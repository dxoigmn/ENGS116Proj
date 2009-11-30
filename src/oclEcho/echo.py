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

src   = open('echo.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

# Grab sizeof(hashState)
statesize       = np.empty(1, dtype=np.uint32)
statesize_buf   = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.COPY_HOST_PTR, hostbuf=statesize)
prg.size(queue, (1,), statesize_buf)
cl.enqueue_read_buffer(queue, statesize_buf, statesize).wait()

statesize = long(statesize[0])

hashbitlen      = 512
hashval         = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
hashval_buf     = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=hashval.size)

data            = "a" * 32
databitlen      = len(data) * 8

data_buf        = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))
databitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databitlen))

state_buf       = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=statesize)

for k in range(0, runs,1):
  for i in range(0, maxi+interval, interval):
    # print "run %d i=%d" % (k,i)
    events  = []
    datalen = 0

    events.append( prg.Init(queue, (1,), state_buf, hashbitlen_buf) )

    for j in range(0, i, 32):
      datalen += databitlen / 8
      events.append( prg.Update(queue, (1,), state_buf, data_buf, databitlen_buf) )

    events.append( prg.Final(queue, (1,), state_buf, hashval_buf) )

    events[-1].wait()
    cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()

    datas[k].append(sum(evt.profile.end - evt.profile.start for evt in events))
    # print sum(evt.profile.end - evt.profile.start for evt in events)

for i in range(0, (maxi+interval)/interval, 1):
  time=0
  for j in range(0, runs, 1):
    time+=datas[j][i]
  print "%d\t%lu" % (i*interval, time/runs)