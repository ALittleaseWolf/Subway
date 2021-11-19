
CC=/usr/bin/mpicxx
NC=/usr/local/cuda/bin/nvcc
CFLAGS=-std=c++11 -O3
NFLAGS=-gencode arch=compute_60,code=sm_60
# NFLAGS=-gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_75,code=compute_75
SHARED=../../shared

DEP=$(SHARED)/argument_parsing.o $(SHARED)/graph.o $(SHARED)/timer.o $(SHARED)/gpu_kernels.o $(SHARED)/partitioner.o $(SHARED)/subway_utilities.o $(SHARED)/subgraph_generator.o $(SHARED)/subgraph.o


all: make1 sswp_dis_sync sswp_dis_async 

make1: part.cu
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o part.o -c part.cu $(CFLAGS)

sswp_dis_sync: sswp_dis_sync.cpp sswp-sync.cu part.o
	$(CC) -I../../common/inc -o sswp_dis_sync.o -c sswp_dis_sync.cpp $(CFLAGS) -L/usr/local/cuda/lib64 -lcudart
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o sswp-sync.o -c sswp-sync.cu $(CFLAGS)
	$(CC) -o sswp_dis_sync $(DEP) sswp-sync.o sswp_dis_sync.o part.o -L/usr/local/cuda/lib64 -lcudart

sswp_dis_async: sswp_dis_async.cpp sswp-async.cu part.o 
	$(CC) -I../../common/inc -o sswp_dis_async.o -c sswp_dis_async.cpp $(CFLAGS) -L/usr/local/cuda/lib64 -lcudart
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o sswp-async.o -c sswp-async.cu $(CFLAGS)
	$(CC) -o sswp_dis_async $(DEP) sswp-async.o sswp_dis_async.o part.o -L/usr/local/cuda/lib64 -lcudart

clean:
	rm part.o
	rm sswp-sync.o sswp_dis_sync.o sswp_dis_sync
	rm sswp-async.o sswp_dis_async.o  sswp_dis_async
