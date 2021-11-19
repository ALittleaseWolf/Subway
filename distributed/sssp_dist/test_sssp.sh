#!/bin/bash

mpirun -n 2 -hostfile hostfile ./sssp_dis_async --input ../../graph.bwcsr
