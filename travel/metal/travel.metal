#include <metal_compute>
#include <metal_simdgroup> 
#include "travel.hpp"

[[max_total_threads_per_threadgroup(1024)]]
kernel void find_best_kernel(device int* distances [[buffer(0)]], 
                             constant int& N [[buffer(1)]], 
                             constant long& num_routes [[buffer(2)]], 
                             device route_cost* block_best [[buffer(3)]],
                             unsigned tid [[thread_position_in_grid]],
                             unsigned tidg [[thread_position_in_threadgroup]],
                             unsigned gid [[threadgroup_position_in_grid]],
                             unsigned gsz [[threads_per_grid]],
                             unsigned laneid [[thread_index_in_simdgroup]],
                             unsigned sid [[simdgroup_index_in_threadgroup]]) {
    route_cost local_best{-1, 1<<30};
    threadgroup route_cost best[1024];
    if (sid == 0)
        best[laneid] = local_best;
    threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    for (long i = tid; i < num_routes; i += gsz) {
        int cost = 0;
        route_iterator it(i, N);
        int from = it.first();
        while (!it.done()) {
            int to = it.next();
            cost += distances[from*N + to];
            from = to;
        }
        if(cost < local_best.cost)
            local_best = route_cost{i, cost};
    }
    if(metal::simd_min(local_best.cost) == local_best.cost)
        best[sid] = local_best;
    threadgroup_barrier(metal::mem_flags::mem_threadgroup);
    if (sid != 0)
        return;
    local_best = best[laneid];
    if(metal::simd_min(local_best.cost) == local_best.cost)
        block_best[gid] = local_best;
}
