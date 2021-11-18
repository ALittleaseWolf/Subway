
CC=/usr/bin/mpicxx
NC=/usr/local/cuda/bin/nvcc
CFLAGS=-std=c++11 -O3
NFLAGS=-gencode arch=compute_60,code=sm_60
# NFLAGS=-gencode arch=compute_30,code=sm_30 -gencode arch=compute_35,code=sm_35 -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_75,code=compute_75
SHARED=../shared

DEP=$(SHARED)/argument_parsing.o $(SHARED)/graph.o $(SHARED)/timer.o $(SHARED)/gpu_kernels.o $(SHARED)/partitioner.o $(SHARED)/subway_utilities.o $(SHARED)/subgraph_generator.o $(SHARED)/subgraph.o


all: make1 bfs_dis_sync bfs_dis_async 

make1: bfs_part.cu
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o bfs_part.o -c bfs_part.cu $(CFLAGS)

bfs_dis_sync: bfs_dis_sync.cpp bfs-sync.cu bfs_part.o
	$(CC) -I../../common/inc -o bfs_dis_sync.o -c bfs_dis_sync.cpp $(CFLAGS) -L/usr/local/cuda/lib64 -lcudart
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o bfs-sync.o -c bfs-sync.cu $(CFLAGS)
	$(CC) -o bfs_dis_sync $(DEP) bfs-sync.o bfs_dis_sync.o bfs_part.o -L/usr/local/cuda/lib64 -lcudart

bfs_dis_async: bfs_dis_async.cpp bfs-async.cu bfs_part.o 
	$(CC) -I../../common/inc -o bfs_dis_async.o -c bfs_dis_async.cpp $(CFLAGS) -L/usr/local/cuda/lib64 -lcudart
	$(NC) -ccbin g++ -I../../common/inc -m64  $(NFLAGS) -o bfs-async.o -c bfs-async.cu $(CFLAGS)
	$(CC) -o bfs_dis_async $(DEP) bfs-async.o bfs_dis_async.o bfs_part.o -L/usr/local/cuda/lib64 -lcudart

clean:
	rm bfs_part.o
	rm bfs-sync.o bfs_dis_sync.o bfs_dis_sync
	rm bfs-async.o bfs_dis_async.o  bfs_dis_async
