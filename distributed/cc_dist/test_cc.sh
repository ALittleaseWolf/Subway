#!/bin/sh

mpirun -n 2 -hostfile hostfile ./cc_dis_async --input ../../graph.bcsr
