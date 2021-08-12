# transformation string parser
import algorithm, tables, strutils, random
import common, transform

# seed char to poly
proc polychar*(c: char): Polyhedron =
    const ptab = {'T': Tetrahedron, 'C': Cube, 'H': Hexahedron,
            'I': Icosahedron, 'O': Octahedron, 'D': Dodecahedron}.toTable
    ptab.getOrDefault(c)

# char transform to poly
proc transform*(p: var Polyhedron, t: char, n: int = 0, f1: float = 0.0,
        f2: float = 0.0) =
    const tr_tab = {'a': ambo, 'g': gyro, 'p': propellor, 'r': reflection,
            'd': dual, 'w': whirl, 'q': quinto, 'P': perspectiva1}.toTable

    if t in tr_tab: p = tr_tab[t](p)
    else:
        case t:
        of 'k': p = p.kisN # (n, f1)
        of 'c': p = p.chamfer # (f1)
        of 'n': p = p.insetN # (n, f1, f2)
        of 'x': p = p.extrudeN # (n)
        of 'l': p = p.loft # (n, f1)
        of 'H': p = p.hollow # (f1,f2)

        else: discard # error -> no nothing

# string transform
proc transform*(p: Polyhedron, tr: string, n: int = 0, f1: float = 0.1,
        f2: float = 0.0, limit_vertex = 10000): Polyhedron =
    const equiv = {'e': "aa", 'b': "ta", 'o': "jj", 'm': "k3j", 't': "dkd",
            'j': "dad", 's': "dgd", }.toTable

    # replace all 'tr' with equiv
    var (trf, trw) = ("", tr)
    while trf != trw:
        trf = trw
        for c in trf:
            if c in equiv:
                trw = trw.replace($c, equiv[c])

    result = p
    for t in trw.reversed:
        if result.vertex.len > limit_vertex: break
        result.transform(t, n, f1, f2)

# scan tt..tP
proc transform*(s: string): Polyhedron =
    transform(polychar(s[^1]), s[0 .. ^2]) # last char is poly seed rest in transformation

const nice_trans = "PcdPqxT,gadPkI,gHqgI,ncrHI,rrkHqlO,wcplD,HxHqI,wggkpD,xlHxqC,lqqqD,rPnPT,aPcdkpI,HlkwD,HcdC,awxaI,nrkHwO,dpaadkI,qdpnqC,PHckD,HqakrpO,rkqkI,wHgPaD,nkkrcPaO,glrHPO,nHrxHC,lqkawpC,PncPxO,alawnwrT,akqlC,xdqdlxT,HddaD,qkpPlD,nPPkwT,HgpgD,dwwaI,dqwgC,HkaxC,PdrkD,lqgalD,PcdPqxT,gadPkI,gHqgI,ncrHI,rrkHqlO,qkcxC,PqlkgD,xHPwC,kdpalI,waadI,rndPdO,cwPakkT,PPdpqO,HdgqI,pwPHD,qkPPI,knwwlO,dPPnqC,PHkwlT,pHncD,llPgI,cHcT,wwaknaT,PHddcxI,HqgaPO,rndPdO,cwPakkT,PPdpqO,HdgqI,pwPHD,qkPPI,knwwlO,dPPnqC,PHkwlT,pHncD,llPgI,cHcT,wwaknaT,kcklI,dlldI,qPxgwT,HnHqkkT,HlggkC,qpkHgC,xxrngacO,nrllkHD,wqPaD,ppHHD,HHgaI,cgcwD,nPnPdrO,lxdqPI,gdnkgpD,qxPpI,knHnrkD,PPnxlO,kkPawdI,PrPqC,PdPlD,qqqacC,PllxI,HqaaD,kHqPD,dPkkkrqT,gaqdPqD,nxrrC,PqrkgaI,nqldkdC,PlcPrD,glqPI,klpxxC,PnqxO,PPlcO,xllnqO,pdPldxkC,nrrPnD,ldHqxwO,xHkaI,kaHqkwD,aPxxwckT,kwrnHC,dPxrcT,qPrlpD,qdwwlD,qdcwI,HqqHrC,nxqqaD,wkglaI,nrccI,pagwO,aqkpD,HPprO,nnHprnC,dkqgqO,rndPdO,nHxrT,rHcwwO,qxcwO,HplnrrcD,HrHHdD,lxkwnqO,xqPndD,ndgdaD,nHnkC,qdwwlD,qqldgC,HaaqqkO,PakcO,qxrHclC,gkaPI,ddgkwlO,nqawprPO,gdPwlcD,ldwPllgC,xwgkD,clxwaqO,HacrD,kcklI,gpxnD,qndcaO,qPcrO,nddPnO,HPaaD,ndkwawlC,PanaT,arckrqaC"

proc rand_preset*: string =
    let trs = nice_trans.split(',')
    result = trs[rand(trs.high)]

proc rand_transform*: string =
    const
        trs = "agprdwqPkcnxlH"
        seeds = "TCIOD"

    for i in 0..3+rand(3):
        result &= trs[rand(trs.high)]
    result &= seeds[rand(seeds.high)]


when isMainModule:
    randomize()
    for i in 0..10:
        echo rand_transform()
