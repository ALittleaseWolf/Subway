#include <iostream>
#include <mpi.h>

using std::cout;
using std::cerr;
using std::endl;

#include "bfs_dis.h"
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
    Graph<OutEdge> graph(arguments.input, false);
    graph.ReadGraph();

    uint n = (uint)world_size;
    Graph<OutEdge> graph_cut[n];
    bfs_part(graph, graph_cut, n);
    graph.FreeGraph();
    
    if (world_rank == 0) {
         // 得到当前进程的名字
        char processor_name[MPI_MAX_PROCESSOR_NAME];
        int name_len;
        MPI_Get_processor_name(processor_name, &name_len);
        cout << processor_name << endl;
        bfs_sync(graph_cut[0], arguments);
    } else if (world_rank == 1) {
        char processor_name[MPI_MAX_PROCESSOR_NAME];
        int name_len;
        MPI_Get_processor_name(processor_name, &name_len);
        cout << processor_name << endl;
        // bfs_sync(graph_cut[1], arguments);
    }

    MPI_CHECK(MPI_Finalize());
    return 0;
}

void my_abort(int err)
{
    cout << "Test FAILED\n";
    MPI_Abort(MPI_COMM_WORLD, err);
}
