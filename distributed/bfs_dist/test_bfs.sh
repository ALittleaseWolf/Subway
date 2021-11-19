#!/bin/sh

mpirun -n 2 -hostfile hostfile ./bfs_dis_async --input ../../graph.bcsr
