#include <iostream>
#include <mpi.h>

using std::cout;
using std::cerr;
using std::endl;

#include "sswp_dis.h"
#define MPI_CHECK(call) \
    if((call) != MPI_SUCCESS) { \
        cerr << "MPI error calling \""#call"\"\n"; \
        my_abort(-1); }

int main(int argc, char *argv[])
{
    MPI_Init(NULL, NULL);
    int world_size,world_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    ArgumentParser arguments(argc, argv, true, false);
    Graph<OutEdgeWeighted> graph(arguments.input, true);
    graph.ReadGraph();

    uint n = (uint)world_size;
    Graph<OutEdgeWeighted> graph_cut[n];
    part(graph, graph_cut, n);
    graph.FreeGraph();
    
    // status
    uint graph_value[graph.num_nodes];
    for(uint i=0;i<graph.num_nodes;i++)
    {
        graph_value[i] = 0;
    }

    if(world_rank != 0){
        MPI_Status status;
        MPI_Probe(world_rank - 1, 0, MPI_COMM_WORLD, &status);
        int num_recv = 0;
        MPI_Get_count(&status, MPI_UNSIGNED, &num_recv);
        MPI_Recv(graph_value, num_recv, MPI_UNSIGNED, world_rank - 1, 0, MPI_COMM_WORLD, &status);
        sswp_sync(graph_cut[world_rank], arguments, graph_value);
    }else{
        sswp_sync(graph_cut[world_rank], arguments, graph_value);
    }

    int num_send = graph.num_nodes;

    MPI_Send(graph_value, num_send, MPI_UNSIGNED, (world_rank + 1) % world_size, 0, MPI_COMM_WORLD);

    if (world_rank == 0) {
        MPI_Status status;
        MPI_Probe(world_size - 1, 0, MPI_COMM_WORLD, &status);
        int num_recv = 0;
        MPI_Get_count(&status, MPI_UNSIGNED, &num_recv);
        MPI_Recv(graph_value, num_recv, MPI_UNSIGNED, world_size-1, 0, MPI_COMM_WORLD, &status);
        for(uint i=0;i<graph.num_nodes && i < 10;i++)
        {
            cout <<i<< ":"<<graph_value[i]<<" ";
        }
        cout << endl;
    }

    MPI_CHECK(MPI_Finalize());
    return 0;
}

void my_abort(int err)
{
    cout << "Test FAILED\n";
    MPI_Abort(MPI_COMM_WORLD, err);
}
