rm default.metallib travel
xcrun clang++ -std=c++20 travel.mm -framework MetalKit -framework Metal -framework Foundation -O2 -o travel
xcrun metal -O2 travel.metal
#AGC_ENABLE_STATUS_FILE=1 FS_CACHE_SIZE=0 USE_MONOLITHIC_COMPILER=1 
