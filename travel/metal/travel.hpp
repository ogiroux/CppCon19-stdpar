struct route_cost {
  long route;
  int cost;
#ifndef __METAL_VERSION__
  route_cost() : route(-1), cost(1 << 30) { }
  route_cost(long route, int cost)
    : route(route), cost(cost) { }
  static struct min_class {
    route_cost operator()(route_cost const& x, route_cost const& y) const {
    return x.cost < y.cost ? x : y;
    }
  }  min;
  static route_cost minf(
    route_cost const& x, route_cost const& y) {
    return x.cost < y.cost ? x : y;
  }
#endif
};
#ifndef __METAL_VERSION__
route_cost::min_class route_cost::min;
#endif

struct route_iterator {
  long remainder;
  int hops_left;
  unsigned visited = 0;
  route_iterator(long route_id, int num_hops)
    : remainder(route_id), hops_left(num_hops)
  { }
  bool done() const {
    return hops_left <= 0;
  }
  int first() {
    int index = (int)(remainder % hops_left);
    remainder /= hops_left;
    --hops_left;
    visited = (1 << index);
    return index;
  }
  int next() {
    long available = remainder % hops_left;
    remainder /= hops_left;
    --hops_left;
    int index = 0;
    while (true) {
      if ((visited & (1 << index)) == 0) {
        if (--available < 0) {
          break;
        }
      }
      ++index;
    }
    visited |= (1 << index);
    return index;
  }
};
