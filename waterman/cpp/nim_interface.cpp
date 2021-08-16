// rust interface for convex_hull 

#include "QuickHull3D.h"
#include "Point3d.h"

extern "C"
{
    void chull(int n_vertices) {
        printf("n. vertices: %d\n", n_vertices);
    }

    void convex_hull(size_t n_vertices, double *vertices, size_t *n_faces, size_t *hn_vertices, int **o_faces, double **o_vertices)
    {
        vector<double> vv;
        for (size_t i = 0; i < n_vertices; i++)
            vv.push_back(vertices[i]);
        QuickHull3D hull(vv);

        auto faces = hull.getFaces(); // faces & vertexes
        auto coords = hull.getVertex();

        // faces list
        n_faces = 0;

        for (auto f : faces) // count faces
        {
            n_faces += f.size() + 1;
        }
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

        auto _vertices = new double[n_vertices];
        i = 0;
        for (auto c : coords)
            _vertices[i++] = c;

        *o_vertices = _vertices;
        *o_faces = _faces;
    }
    void free_ch(int *o_faces, double *o_vertices)
    {
        delete[] o_faces;
        delete[] o_vertices;
    }
}
