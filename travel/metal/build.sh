rm default.metallib travel
xcrun clang++ -std=c++20 travel.mm -framework MetalKit -framework Metal -framework Foundation -O2 -o travel
xcrun metal -O2 travel.metal
