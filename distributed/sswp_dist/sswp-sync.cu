
#include "../../shared/timer.hpp"
#include "../../shared/subgraph.cuh"
#include "../../shared/partitioner.cuh"
#include "../../shared/subgraph_generator.cuh"
#include "../../shared/gpu_error_check.cuh"
#include "../../shared/gpu_kernels.cuh"
#include "../../shared/subway_utilities.hpp"
#include "sswp_dis.h"

void sswp_sync(Graph<OutEdgeWeighted> G,ArgumentParser arguments,uint graph_value[])
{	
	cudaFree(0);
	
	Timer timer;
	timer.Start();
	
	Graph<OutEdgeWeighted> graph;
    graph.ReadGraphFromGraph(G);
	
	float readtime = timer.Finish();
	cout << "Graph Reading finished in " << readtime/1000 << " (s).\n";
	
	for(unsigned int i=0; i<graph.num_nodes; i++)
	{
		graph.value[i] = graph_value[i];
        graph.label2[i] = true;
		graph.label1[i] = false;
	}
	graph.value[arguments.sourceNode] = DIST_INFINITY;
	graph.label1[arguments.sourceNode] = false;
	graph.label2[arguments.sourceNode] = true;


	gpuErrorcheck(cudaMemcpy(graph.d_outDegree, graph.outDegree, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_value, graph.value, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label1, graph.label1, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label2, graph.label2, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	
	Subgraph<OutEdgeWeighted> subgraph(graph.num_nodes, graph.num_edges);
	
	SubgraphGenerator<OutEdgeWeighted> subgen(graph);
	
	subgen.generate(graph, subgraph);


	Partitioner<OutEdgeWeighted> partitioner;
	
	timer.Start();
	
	uint itr = 0;
		
	while (subgraph.numActiveNodes>0)
	{
		itr++;
		
		partitioner.partition(subgraph, subgraph.numActiveNodes);
		// a super iteration
		for(int i=0; i<partitioner.numPartitions; i++)
		{
			cudaDeviceSynchronize();
			gpuErrorcheck(cudaMemcpy(subgraph.d_activeEdgeList, subgraph.activeEdgeList + partitioner.fromEdge[i], (partitioner.partitionEdgeSize[i]) * sizeof(OutEdgeWeighted), cudaMemcpyHostToDevice));
			cudaDeviceSynchronize();

			moveUpLabels<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(subgraph.d_activeNodes, graph.d_label1, graph.d_label2, partitioner.partitionNodeSize[i], partitioner.fromNode[i]);

			sswp_kernel<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(partitioner.partitionNodeSize[i],
													partitioner.fromNode[i],
													partitioner.fromEdge[i],
													subgraph.d_activeNodes,
													subgraph.d_activeNodesPointer,
													subgraph.d_activeEdgeList,
													graph.d_outDegree,
													graph.d_value, 
													//d_finished,
													graph.d_label1,
													graph.d_label2);

			cudaDeviceSynchronize();
			gpuErrorcheck( cudaPeekAtLastError() );	
		}
		
		subgen.generate(graph, subgraph);
			
	}	
	
	float runtime = timer.Finish();
	cout << "Processing finished in " << runtime/1000 << " (s).\n";
	
	cout << "Number of iterations = " << itr << endl;
	
	gpuErrorcheck(cudaMemcpy(graph.value, graph.d_value, graph.num_nodes*sizeof(uint), cudaMemcpyDeviceToHost));
	
	utilities::PrintResults(graph.value, min(30, graph.num_nodes));
	for(uint i=0;i<graph.num_nodes;i++)
		if(graph_value[i] == 0)
			graph_value[i] = graph.value[i];
		else if(graph_value[i] != 0 && graph.value[i]!=0)
        	graph_value[i] = graph_value[i]<graph.value[i]? graph_value[i]:graph.value[i];
		else
			continue;
			
    gpuErrorcheck(cudaFree(graph.d_outDegree));
    gpuErrorcheck(cudaFree(graph.d_value));
    gpuErrorcheck(cudaFree(graph.d_label1));
    gpuErrorcheck(cudaFree(graph.d_label2));
    gpuErrorcheck(cudaFreeHost(graph.edgeList));
	// if(arguments.hasOutput)
	// 	utilities::SaveResults(arguments.output, graph.value, graph.num_nodes);
}

