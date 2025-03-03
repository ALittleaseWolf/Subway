
#include "../../shared/timer.hpp"


#include "../../shared/subgraph.cuh"
#include "../../shared/partitioner.cuh"
#include "../../shared/subgraph_generator.cuh"
#include "../../shared/gpu_error_check.cuh"
#include "../../shared/gpu_kernels.cuh"
#include "../../shared/subway_utilities.hpp"
#include "bfs_dis.h"

void bfs_async(Graph<OutEdge> G, ArgumentParser arguments, uint graph_value[])
{
	cudaFree(0);

	
	Timer timer;
	timer.Start();
	
	Graph<OutEdge> graph;
    graph.ReadGraphFromGraph(G);
	
	float readtime = timer.Finish();
	cout << "Graph Reading finished in " << readtime/1000 << " (s).\n";
	
   for(uint i=0; i<graph.num_nodes;i++)
    {
        graph.value[i] = graph_value[i];
        if(graph_value[i] != DIST_INFINITY)
        {
            graph.label2[i] = true;
        }
        graph.label1[i] = false;
    }
    graph.value[arguments.sourceNode] = 0;
	graph.label1[arguments.sourceNode] = false;
	graph.label2[arguments.sourceNode] = true;


	gpuErrorcheck(cudaMemcpy(graph.d_outDegree, graph.outDegree, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_value, graph.value, graph.num_nodes * sizeof(unsigned int), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label1, graph.label1, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	gpuErrorcheck(cudaMemcpy(graph.d_label2, graph.label2, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));
	
	Subgraph<OutEdge> subgraph(graph.num_nodes, graph.num_edges);
	
	SubgraphGenerator<OutEdge> subgen(graph);
	
	subgen.generate(graph, subgraph);
	
	for(unsigned int i=0; i<graph.num_nodes; i++)
	{
		graph.label1[i] = false;
	}
	graph.label1[arguments.sourceNode] = true;
	gpuErrorcheck(cudaMemcpy(graph.d_label1, graph.label1, graph.num_nodes * sizeof(bool), cudaMemcpyHostToDevice));

	Partitioner<OutEdge> partitioner;
	
	timer.Start();
	
	unsigned int gItr = 0;
	
	bool finished;
	bool *d_finished;
	gpuErrorcheck(cudaMalloc(&d_finished, sizeof(bool)));
		
	while (subgraph.numActiveNodes>0)
	{
		gItr++;
		
		partitioner.partition(subgraph, subgraph.numActiveNodes);
		// a super iteration
		for(int i=0; i<partitioner.numPartitions; i++)
		{
			cudaDeviceSynchronize();
			gpuErrorcheck(cudaMemcpy(subgraph.d_activeEdgeList, subgraph.activeEdgeList + partitioner.fromEdge[i], (partitioner.partitionEdgeSize[i]) * sizeof(OutEdge), cudaMemcpyHostToDevice));
			cudaDeviceSynchronize();

			//moveUpLabels<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(subgraph.d_activeNodes, graph.d_label, partitioner.partitionNodeSize[i], partitioner.fromNode[i]);
			mixLabels<<<partitioner.partitionNodeSize[i]/512 + 1 , 512>>>(subgraph.d_activeNodes, graph.d_label1, graph.d_label2, partitioner.partitionNodeSize[i], partitioner.fromNode[i]);
			
			uint itr = 0;
			do
			{
				itr++;
				finished = true;
				gpuErrorcheck(cudaMemcpy(d_finished, &finished, sizeof(bool), cudaMemcpyHostToDevice));
				
				bfs_async<<< partitioner.partitionNodeSize[i]/512 + 1 , 512 >>>(partitioner.partitionNodeSize[i],
														partitioner.fromNode[i],
														partitioner.fromEdge[i],
														subgraph.d_activeNodes,
														subgraph.d_activeNodesPointer,
														subgraph.d_activeEdgeList,
														graph.d_outDegree,
														graph.d_value, 
														d_finished,
														(itr%2==1) ? graph.d_label1 : graph.d_label2,
														(itr%2==1) ? graph.d_label2 : graph.d_label1);

				cudaDeviceSynchronize();
				gpuErrorcheck( cudaPeekAtLastError() );
				
				gpuErrorcheck(cudaMemcpy(&finished, d_finished, sizeof(bool), cudaMemcpyDeviceToHost));
			}while(!(finished));
			
			cout << itr << ((itr>1) ? " Inner Iterations" : " Inner Iteration") << " in Global Iteration " << gItr << ", Partition " << i  << endl;
		}
		
		subgen.generate(graph, subgraph);
			
	}	
	
	float runtime = timer.Finish();
	cout << "Processing finished in " << runtime/1000 << " (s).\n";
	
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

