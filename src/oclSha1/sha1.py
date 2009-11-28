#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

src   = open('sha1c.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.CPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()

msg     = "abc"
len     = len(msg)
digest  = np.empty(20, dtype=np.uint8)

msg_buf     = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.char.array(msg))
len_buf     = cl.Buffer(ctx, cl.mem_flags.READ_ONLY | cl.mem_flags.COPY_HOST_PTR, hostbuf=np.uint32(len))
digest_buf  = cl.Buffer(ctx, cl.mem_flags.WRITE_ONLY, size=digest.size)

evt = prg.sha1(queue, (4,), msg_buf, len_buf, digest_buf)
cl.enqueue_read_buffer(queue, digest_buf, digest).wait()

print "%lu ns" % (evt.profile.end - evt.profile.start)

digest_hex = ""

for i in xrange(0, digest.size):
  digest_hex += "%02x" % digest[i]

print digest_hex