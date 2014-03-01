#include "Random123/threefry.h"
//typedef unsigned int uint32_t;

/**
* Code taken from library
*/
#define R123_0x1p_31f (1.f/(1024.f*1024.f*1024.f*2.f))
#define R123_0x1p_24f (128.f*R123_0x1p_31f)

float u01fixedpt_closed_open_32_24(uint32_t i){
    return (i>>8)*R123_0x1p_24f; /* 0x1.0p-24f; */
}

__kernel void main(__global ulong * seed,uint count,uint sampleOffset,__global float * result) {

//	printf("%d\n",get_global_id(0));
	threefry2x32_ctr_t  ctr = {{0,seed[0]+(sampleOffset+get_global_id(0))*count}};
	threefry2x32_key_t key = {{seed[1], seed[2]}};
	float sum = 0.0f;
	threefry2x32_ctr_t rand;
	for(uint i = 0;i < count;++i) {
		if(i % 2 == 0) {
			rand = threefry2x32(ctr, key);
			ctr.v[0]++;
		}
		sum += u01fixedpt_closed_open_32_24(rand.v[i%2]);
	}
	sum /= count;
	result[sampleOffset+get_global_id(0)] = sum;
}
	
