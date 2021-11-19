#!/bin/bash

mpirun -n 2 -hostfile hostfile ./sswp_dis_async --input ../../graph.bwcsr
