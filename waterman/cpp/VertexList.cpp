//
//  VertexList.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include "VertexList.h"
#include "Vertex.h"

VertexList::VertexList() {}

void VertexList::clear()
{
    head = tail = null;
}

/**
 * Adds a vertex to the end of this list.
 */
void VertexList::add (Vertex *vtx)
{
    if (head == null)
    { head = vtx;
    }
    else
    { tail->next = vtx;
    }
    vtx->prev = tail;
    vtx->next = null;
    tail = vtx;
}

/**
 * Adds a chain of vertices to the end of this list.
 */
void VertexList::addAll (Vertex *vtx)
{
    if (head == null)
    { head = vtx;
    }
    else
    { tail->next = vtx;
    }
    vtx->prev = tail;
    while (vtx->next != null)
    { vtx = vtx->next;
    }
    tail = vtx;
}

/**
 * Deletes a vertex from this list.
 */
void VertexList::del (Vertex *vtx)
{
    if (vtx->prev == null)
    { head = vtx->next;
    }
    else
    { vtx->prev->next = vtx->next;
    }
    if (vtx->next == null)
    { tail = vtx->prev;
    }
    else
    { vtx->next->prev = vtx->prev;
    }
}

/**
 * Deletes a chain of vertices from this list.
 */
void VertexList::del (Vertex *vtx1, Vertex *vtx2)
{
    if (vtx1->prev == null)
    { head = vtx2->next;
    }
    else
    { vtx1->prev->next = vtx2->next;
    }
    if (vtx2->next == null)
    { tail = vtx1->prev;
    }
    else
    { vtx2->next->prev = vtx1->prev;
    }
}

/**
 * Inserts a vertex into this list before another
 * specificed vertex.
 */
void VertexList::insertBefore (Vertex *vtx, Vertex *next)
{
    vtx->prev = next->prev;
    if (next->prev == null)
    { head = vtx;
    }
    else
    { next->prev->next = vtx;
    }
    vtx->next = next;
    next->prev = vtx;
}

/**
 * Returns the first element in this list.
 */
Vertex *VertexList::first()
{
    return head;
}

/**
 * Returns true if this list is empty.
 */
bool VertexList::isEmpty()
{
    return head == null;
}
