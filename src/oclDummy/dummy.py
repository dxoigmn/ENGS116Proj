#!/usr/bin/env python

import pyopencl as cl
import numpy as np
import sys

src   = open('dummy.cl', 'r').read()
ctx   = cl.Context(dev_type=cl.device_type.GPU)
queue = cl.CommandQueue(ctx, properties=cl.command_queue_properties.PROFILING_ENABLE)
prg   = cl.Program(ctx, src).build()
mem   = cl.Buffer(ctx, cl.mem_flags.READ_WRITE | cl.mem_flags.ALLOC_HOST_PTR, size=4)
evt   = prg.Hash(queue, (1,), mem)
evt.wait()

print "%lu" % (evt.profile.end - evt.profile.start)
