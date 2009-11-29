#!/usr/bin/env python
 
import pyopencl as cl
import numpy as np
import sys
 
src = open('echo.cl', 'r').read()
ctx = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg = cl.Program(ctx, src).build()
 
output = np.empty(1, dtype=np.int8)
hashbitlen = 512
data = "whyisthereamonkeyhere?"
databitlen = len(data) * 8
hashval = np.empty(hashbitlen/8, dtype=np.uint8)

hashbitlen_buf = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(hashbitlen))
data_buf = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(data))
databitlen_buf = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(databitlen))
hashval_buf = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=hashval.size)
output_buf = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=16)

evt = prg.Hash(queue, (5,), hashbitlen_buf, data_buf, databitlen_buf, hashval_buf,output_buf)
cl.enqueue_read_buffer(queue, hashval_buf, hashval).wait()
cl.enqueue_read_buffer(queue, output_buf, output).wait()

print output

print "%lu ns" % (evt.profile.end - evt.profile.start)
 
hashval_hex = ""
 
for i in xrange(0, hashval.size):
  hashval_hex += "%02x" % hashval[i]
 
print hashval_hex