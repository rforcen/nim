# transformation string parser
import algorithm, tables, strutils
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

    p = if t in tr_tab: tr_tab[t](p)
    else:
        case t:
        of 'k': p.kisN # (n, f1)
        of 'c': p.chamfer # (f1)
        of 'n': p.insetN # (n, f1, f2)
        of 'x': p.extrudeN # (n)
        of 'l': p.loft # (n, f1)
        of 'H': p.hollow # (f1,f2)

        else: p # error -> no nothing

# string transform
proc transform*(p: Polyhedron, tr: string, n: int = 0, f1: float = 0.1,
        f2: float = 0.0): Polyhedron =
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
        result.transform(t, n, f1, f2)

# scan tt..tP
proc transform*(s: string): Polyhedron =
    transform(polychar(s[^1]), s[0 .. ^2]) # last char is poly seed rest in transformation
