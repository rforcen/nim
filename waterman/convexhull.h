// nim interface for convex_hull

#include "cpp/QuickHull3D.h"
#include "cpp/Point3d.h"
#include <limits>

extern "C"
{
    void convex_hull(size_t n_vertices, double *vertices, size_t *n_faces, size_t *hn_vertices, int **o_faces, double **o_vertices)
    {
        // printf("n.vertices: %d\n", n_vertices);
        // for (int i=0; i<n_vertices; i++) printf("%f ", vertices[i]);

        vector<double> vv;

        for (size_t i = 0; i < n_vertices; i++)
            vv.push_back(vertices[i]);
        QuickHull3D hull(vv);

        auto faces = hull.getFaces(); // faces & vertexes
        auto coords = hull.getVertex();

        // faces list
        *n_faces = 0;

        for (auto f : faces) // count faces
            *n_faces += f.size() + 1;

        // populate o_face: |n_intems|items,.,,.

        auto _faces = new int[*n_faces];

        size_t i = 0;
        for (auto f : faces)
        {
            _faces[i++] = f.size();
            for (auto ix : f)
                _faces[i++] = ix;
        }

        // vertex list
        *hn_vertices = coords.size();
        // printf("cpp: n. vertex:%d, %d\n", *hn_vertices, coords.size());

        auto _vertices = new double[n_vertices];
        auto max_v = -std::numeric_limits<double>::max();

        i = 0;
        for (auto c : coords)
        {
            _vertices[i++] = c;
            if (c > max_v)
                max_v = c;
        }
        // scale
        if (max_v != 0)
            for (auto i = 0; i < n_vertices; i++)
                _vertices[i] /= max_v;

        *o_vertices = _vertices;
        *o_faces = _faces;

        // for (int i=0; i<*n_faces; i++) printf("%d ", (*o_faces)[i]);    puts("");
        // for (int i=0; i<*hn_vertices; i++) printf("%.1f ", (*o_vertices)[i]);     puts("");
    }

    void free_ch(int *o_faces, double *o_vertices)
    {
        delete[] o_faces;
        delete[] o_vertices;
    }
}
