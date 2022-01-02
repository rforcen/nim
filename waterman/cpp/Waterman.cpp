#include "Waterman.h"
/*
#include <boost/python.hpp>
#include <boost/python/numpy.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>

namespace p = boost::python;
namespace np = boost::python::numpy;
*/
WatermanPoly::WatermanPoly() {}

QuickHull3D WatermanPoly::genHull(double radius)
{
    return QuickHull3D(genPoly(radius));
}

//3d waterman polygon generator -> vec3* and 'ntc', radius: change from 1.. after must generate the convex hull
vector<double> WatermanPoly::genPoly(double radius)
{
    double x, y, z, a, b, c, xra, xrb, yra, yrb, zra, zrb, R, Ry, s, radius2;

    vector<double> coords;

    a = b = c = 0; // center

    s = radius;
    radius2 = radius; // * radius;
    xra = ceil(a - s);
    xrb = floor(a + s);

    for (x = xra; x <= xrb; x++)
    {
        R = radius2 - (x - a) * (x - a);
        if (R < 0)
            continue;
        s = sqrt(R);
        yra = ceil(b - s);
        yrb = floor(b + s);
        for (y = yra; y <= yrb; y++)
        {
            Ry = R - (y - b) * (y - b);
            if (Ry < 0)
                continue; //case Ry < 0
            if (Ry == 0 && c == floor(c))
            { //case Ry=0
                if (fmod((x + y + c), 2) != 0)
                    continue;
                else
                {
                    zra = c;
                    zrb = c;
                }
            }
            else
            { // case Ry > 0
                s = sqrt(Ry);
                zra = ceil(c - s);
                zrb = floor(c + s);
                if (fmod((x + y), 2) == 0)
                { // (x+y)mod2=0
                    if (fmod(zra, 2) != 0)
                    {
                        if (zra <= c)
                            zra = zra + 1;
                        else
                            zra = zra - 1;
                    }
                }
                else
                { // (x+y) mod 2 <> 0
                    if (fmod(zra, 2) == 0)
                    {
                        if (zra <= c)
                            zra = zra + 1;
                        else
                            zra = zra - 1;
                    }
                }
            }

            for (z = zra; z <= zrb; z += 2)
            { // save vertex x,y,z
                coords.push_back(x);
                coords.push_back(y);
                coords.push_back(z);
            }
        }
    }

    return coords;
}

// python stuff
/*
static void initPython() {
    static bool must_init=true;
    if (must_init) {
     Py_Initialize(); // init boost & numpy boost
     np::initialize();
     must_init=false;
    }
}

template <class T>
void*clone_data(vector<T>&v) { //  vector data clone
    auto sz=v.size()*sizeof(T);
    return memcpy(malloc(sz), v.data(), sz);
}

// create a cloned data numpy array
template <class T>
static np::ndarray vector2numpy(vector<T>v) {
    return np::from_data(clone_data(v),     // data -> clone
            np::dtype::get_builtin<T>(),  // dtype -> double
            p::make_tuple(v.size()),    // shape -> size
            p::make_tuple(sizeof(T)), p::object()); // stride
}

template <class T>
static np::ndarray vector2Coords(vector<T>v) {
    return np::from_data(clone_data(v),     // data -> clone
            np::dtype::get_builtin<T>(),  // dtype -> double
            p::make_tuple(v.size()/3, 3),    // shape
            p::make_tuple(sizeof(T)*3, sizeof(T)), p::object()); // stride
}

template <class T>
vector<T>  normalizeCoords(vector<T>coords) { // 0..1
    auto   mm = std::minmax_element(coords.begin(), coords.end());
    double diff=abs(*mm.second - *mm.first);
    if(diff!=0)
        for (size_t i=0; i<coords.size(); i++) coords[i]/=diff;
    return coords;
}

template <class T>
p::list vector2list(vector<T>&v) {
    p::list l;
    for (auto _v:v) l.append(_v);
    return l;
}

static p::list waterman(double radius) {
    initPython();

    WatermanPoly wp;
    auto hull = wp.genHull(radius); // generate convex hull

    vector<vector<int>> faces=hull.getFaces();

    p::list l, lf; // main list: l, face list: lf
    for (auto f:faces) lf.append(vector2list(f));

    l.append(vector2Coords(normalizeCoords(hull.getVertex())));
    l.append(lf);

    return l; // coords(numpy(n_vertex, 3), face_list:list(list()))
}


BOOST_PYTHON_MODULE(Waterman) {
    def("waterman", waterman, (p::arg("radius")));
}

*/