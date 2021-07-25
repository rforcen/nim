//
// voronoi.cl
//

// input point struct
struct Point {
  float2 pos;
  uint color;
  uint pad; // 32 bit alignment field
};

inline float dist_squared(float2 a, float2 b) {
  float2 c = a - b;
  return dot(c, c);
}

#define dist2(i) dist_squared(points[i].pos, current_point)

// voronio kernel
kernel void voronoi(global uint *image,          // 0: output image
                    global struct Point *points, // 1: point set
                    int n_points                 // 2: n_points
) {

  uint black = 0xff000000u;

  size_t index = get_global_id(0);
  int width = (int)sqrt((float)get_global_size(0)); // w x w = n

  float2 current_point = (float2)(index % width, index / width) / width;

  uint color = black;
  float dist = dist2(0), circ_diam = 1e-6f;

  for (int i = 1; i < n_points; i++) {
    float d = dist2(i);

    if (d < circ_diam) { // draw center circle??
      color = black;
      break;
    }
    if (d < dist) {
      dist = d;
      color = points[i].color;
    }
  }

  image[index] = black | color;
}