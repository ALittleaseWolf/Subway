#include "../shared/globals.hpp"
#include "../shared/graph.cuh"
#include "../shared/argument_parsing.cuh"
extern "C" {
    void bfs_sync(Graph<OutEdge> G, ArgumentParser arguments);
    void bfs_async(Graph<OutEdge> G, ArgumentParser arguments);
    void my_abort(int err); 
    void bfs_part(Graph<OutEdge> graph, Graph<OutEdge> graph_cut[], uint n);
}