
#include "../../shared/timer.hpp"


#include "../../shared/subgraph.cuh"
#include "../../shared/partitioner.cuh"
#include "../../shared/subgraph_generator.cuh"
#include "../../shared/gpu_error_check.cuh"
#include "../../shared/gpu_kernels.cuh"
#include "../../shared/subway_utilities.hpp"
#include "cc_dis.h"

void cc_sync(Graph<OutEdge> G, ArgumentParser arguments, uint graph_value[])
{
	cudaFree(0);
	
	Timer timer;
	timer.Start();
	
	Graph<OutEdge> graph(arguments.input, false);
	graph.ReadGraph();
	
	float readtime = timer.Finish();
	cout << "Graph Reading finished in " << readtime/1000 << " (s).\n";
	

	for(unsigned int i=0; i<graph.num_nodes; i++)
	{
		graph.value[i] = graph_value[i];
		graph.label1[i] = false;
		graph.label2[i] = true;
	}

	gpuErrorcheck(cudaMemcpy(graph.d_outDegree, graph.outDegree, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_value, graph.value, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label1, graph.label1, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label2, graph.label2, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	
	Subgraph<OutEdge> subgraph(graph.num_nodes, graph.num_edges);
	
	SubgraphGenerator<OutEdge> subgen(graph);
	
	subgen.generate(graph, subgraph);


	Partitioner<OutEdge> partitioner;
	
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
			gpuErrorcheck(cudaMemcpy(subgraph.d_activeEdgeList, subgraph.activeEdgeList + partitioner.fromEdge[i], (partitioner.partitionEdgeSize[i]) * sizeof(OutEdge), cudaMemcpyHostToDevice));
			cudaDeviceSynchronize();

			moveUpLabels<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(subgraph.d_activeNodes, graph.d_label1, graph.d_label2, partitioner.partitionNodeSize[i], partitioner.fromNode[i]);

			cc_kernel<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(partitioner.partitionNodeSize[i],
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
        graph_value[i] = graph_value[i]<graph.value[i]? graph_value[i]:graph.value[i];

	gpuErrorcheck(cudaFree(graph.d_outDegree));
    gpuErrorcheck(cudaFree(graph.d_value));
    gpuErrorcheck(cudaFree(graph.d_label1));
    gpuErrorcheck(cudaFree(graph.d_label2));
    gpuErrorcheck(cudaFreeHost(graph.edgeList));
	// if(arguments.hasOutput)
	// 	utilities::SaveResults(arguments.output, graph.value, graph.num_nodes);
}

