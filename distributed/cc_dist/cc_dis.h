#include "../../shared/globals.hpp"
#include "../../shared/graph.cuh"
#include "../../shared/argument_parsing.cuh"
extern "C" {
    void cc_sync(Graph<OutEdge> G,ArgumentParser arguments,uint graph_value[]);
    void cc_async(Graph<OutEdge> G,ArgumentParser arguments,uint graph_value[]);
    void my_abort(int err); 
    void part(Graph<OutEdge> graph, Graph<OutEdge> graph_cut[], uint n);
}