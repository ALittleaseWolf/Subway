#include "../../shared/globals.hpp"
#include "../../shared/graph.cuh"
#include "../../shared/argument_parsing.cuh"
extern "C" {
    void sssp_sync(Graph<OutEdgeWeighted> G,ArgumentParser arguments,uint graph_value[]);
    void sssp_async(Graph<OutEdgeWeighted> G,ArgumentParser arguments,uint graph_value[]);
    void my_abort(int err); 
    void part(Graph<OutEdgeWeighted> graph, Graph<OutEdgeWeighted> graph_cut[], uint n);
}