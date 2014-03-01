#include "mwc64x.cl"



__kernel void main(ulong seed,uint count,uint sampleOffset,__global float * result) {

	mwc64x_state_t rng;
	MWC64X_SeedStreams(&rng, sampleOffset, count);
	float sum = 0.0f;
	for(uint i = 0;i < count;++i) {
		float x = ((float)MWC64X_NextUint(&rng))/0xFFFFFFFF;
		sum += x;
	}
	sum /= count;
	result[sampleOffset+get_global_id(0)] = sum;
}
	
