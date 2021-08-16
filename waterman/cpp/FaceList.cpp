//
//  FaceList.cpp
//  WatermanPoly
//
//  Created by asd on 10/12/2018.
//  Copyright © 2018 voicesync. All rights reserved.
//

#include "FaceList.h"
#include "Face.h"

FaceList::FaceList() {}

void FaceList::clear()
{
    head = tail = null;
}

/**
 * Adds a vertex to the end of this list.
 */
void FaceList::add(Face *vtx)
{
    if (head == null)
    {
        head = vtx;
    }
    else
    {
        tail->next = vtx;
    }
    vtx->next = null;
    tail = vtx;
}

Face *FaceList::first()
{
    return head;
}

/**
 * Returns true if this list is empty.
 */
bool FaceList::isEmpty()
{
    return head == null;
}
