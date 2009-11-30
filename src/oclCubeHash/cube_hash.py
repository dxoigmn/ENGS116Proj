#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

src   = open('cube_hash_new.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

hashbitlen      = 512
hashval         = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
hashval_buf     = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=hashval.size)

data            = "a" * 32
databitlen      = len(data) * 8

data_buf        = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))
databitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databitlen))

pos_buf         = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=4)
x_buf           = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=4*32)

for i in range(0, 1024+32, 32):
  events  = []
  datalen = 0

  events.append( prg.Init(queue, (1,), hashbitlen_buf, pos_buf, x_buf) )

  for j in range(0, i, 32):
    datalen += databitlen / 8
    events.append( prg.Update(queue, (1,), pos_buf, x_buf, data_buf, databitlen_buf) )

  events.append( prg.Final(queue, (1,), hashbitlen_buf, pos_buf, x_buf, hashval_buf) )

  events[-1].wait()
  cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()

  hashval_hex = ""
  for i in xrange(0, hashval.size):
    hashval_hex += "%02x" % hashval[i]

  print "%d\t%lu\t%s" % (datalen, sum(evt.profile.end - evt.profile.start for evt in events), hashval_hex)