# ConvexHull -> libconvexhull.a
sources=main.cpp Face.cpp FaceList.cpp HalfEdge.cpp Point3d.cpp QuickHull3D.cpp  Vector3d.cpp Vertex.cpp VertexList.cpp Waterman.cpp
objs=main.o Face.o FaceList.o HalfEdge.o Point3d.o QuickHull3D.o Vector3d.o Vertex.o VertexList.o Waterman.o
includes=Face.h FaceList.h HalfEdge.h Point3d.h QuickHull3D.h Vector3d.h Vertex.h VertexList.h Waterman.h

wp: $(sources) $(includes)
	g++ -o main -g $(sources)

.SILENT: lib 
lib: $(sources) $(includes)
	g++ -c -O3 $(sources)
	rm -f libconvexhull.a
	ar rsc libconvexhull.a $(objs)
	rm -f $(objs)

.SILENT: clean
clean:
	rm *o