#include "Waterman.h"

int main()
{
    auto wp = WatermanPoly();
    auto qh = wp.genHull(45);
    auto faces=qh.getFaces();
    auto vertices = qh.getVertices();
    return 0;
}