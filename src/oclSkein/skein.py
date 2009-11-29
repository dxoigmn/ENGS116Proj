#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

src   = open('skein.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

hashbitlen      = 512
data            = "abc"
databitlen      = len(data) * 8
hashval         = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
data_buf        = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))
databitlen_buf  = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databitlen))
hashval_buf     = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=hashval.size)

evt = prg.Hash(queue, (1,), hashbitlen_buf, data_buf, databitlen_buf, hashval_buf)
cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()

print "%lu ns" % (evt.profile.end - evt.profile.start)

hashval_hex = ""

for i in xrange(0, hashval.size):
  hashval_hex += "%02x" % hashval[i]

print hashval_hex
