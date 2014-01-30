#include "MT_local.hcl"


__kernel void main(MT_state state,uint count,uint sampleOffset,__global float * result) {

	MT_init( prng, state );
	float sum = 0.0f;
	for(uint i = 0;i < count;++i) {
		sum += MT_rndFloat(prng);
	}
	sum /= count;
	result[sampleOffset+get_global_id(0)] = sum;
	MT_save(prng);
}
	
