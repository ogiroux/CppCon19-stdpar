#include <limits>
#include <chrono>
#include <random>
#include <algorithm>
#include <iostream>
#include <iomanip>
#import <Metal/Metal.h>
#include "travel.hpp"

constexpr int MAX_CITIES = 15;

char const* city_names[MAX_CITIES] = {
  "A", "B", "C", "D", "E", "F",
  "G", "H", "I", "J", "K",
  "L", "M", "N", "O"
};

int* init(int N) {
  int* distances = new int[N * N];
  std::mt19937 r;
  std::shuffle(city_names, city_names + N, r);
  for (int i = 0; i < N; ++i) {
    for (int j = 0; j < N; ++j) {
      if (i == j) {
        distances[i*N + j] = 9999;
      } else if (city_names[i][0] + 1 == city_names[j][0]) {
        distances[i*N + j] = (r() % 15) + 5;
      } else {
        distances[i*N + j] = (r() % 900) + 100;
      }
    }
  }
  return distances;
}

long factorial(long x) {
  if (x <= 1) {
    return 1;
  }
  return x * factorial(x - 1);
}

route_cost find_best_route(int const* distances, int N) {

    __strong id<MTLDevice> mtldevice = MTLCreateSystemDefaultDevice();
    __strong id<MTLBuffer> __distances = [mtldevice newBufferWithLength:N*N*sizeof(int) options:MTLResourceStorageModeShared];
    __strong id<MTLBuffer> __block_best = [mtldevice newBufferWithLength:1024*sizeof(route_cost) options:MTLResourceStorageModeShared];
    __strong id<MTLLibrary> library = [mtldevice newDefaultLibrary];
    __strong id<MTLFunction> function = [library newFunctionWithName:@"find_best_kernel"];
    __strong id<MTLComputePipelineState> compute_pipeline_state = [mtldevice newComputePipelineStateWithFunction:function error:0];
    __strong id<MTLCommandQueue> command_queue = [mtldevice newCommandQueue];
    __strong id<MTLCommandBuffer> command_buffer = [command_queue commandBuffer];
    __strong id<MTLComputeCommandEncoder> command_encoder = [command_buffer computeCommandEncoder];
    [command_encoder setComputePipelineState:compute_pipeline_state];

    int* dev_distances = (int*)__distances.contents;
    memcpy(dev_distances, distances, N*N*sizeof(int));
    [command_encoder setBuffer:__distances offset:0 atIndex:0];
    [command_encoder setBytes:&N length:sizeof(int) atIndex:1];

    long num_routes = factorial(N);
    [command_encoder setBytes:&num_routes length:sizeof(long) atIndex:2];
    route_cost* block_best = (route_cost*)__block_best.contents;
    [command_encoder setBuffer:__block_best offset:0 atIndex:3];
    MTLSize numThreadgroups{96, 1, 1}, threadsPerGroup{1024, 1, 1};
    [command_encoder dispatchThreadgroups:numThreadgroups threadsPerThreadgroup:threadsPerGroup];
    [command_encoder endEncoding];
    [command_buffer commit];
    [command_buffer waitUntilCompleted];

    route_cost best_route;
    for (int i = 0; i < 96; ++i)
        best_route = route_cost::minf(best_route, block_best[i]);
    return best_route;
}

void print_route(route_cost best_route, int N) {
  std::cout << "Best route: " << best_route.cost << " miles\n";
  route_iterator it(best_route.route, N);
  std::cout << city_names[it.first()];
  while (!it.done()) {
    std::cout << ", " << city_names[it.next()];
  }
  std::cout << "\n";
}

int main(int argc, char **argv) {
  int N = argc < 2 ? 5 : std::atoi(argv[1]);
  if (N < 1 || N > MAX_CITIES) {
    std::cout << N << " must be between 1 and " << MAX_CITIES << ".\n";
    return 1;
  }
  int const* distances = init(N);

  find_best_route(distances, std::min(N, 5));

  std::cout << "Checking " << factorial(N) 
            << " routes for the best way to visit " << N << " cities...\n";
  auto start = std::chrono::steady_clock::now();

  auto best_route = find_best_route(distances, N);

  auto end = std::chrono::steady_clock::now();
  auto duration =
    std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  std::cout << "Took " << (duration / 1000) << "." << std::setw(3) 
            << std::setfill('0') << (duration % 1000) << "s\n";

  print_route(best_route, N);
}
