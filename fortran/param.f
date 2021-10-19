c
c parameter wrapping test
c
      

      subroutine param1(p, r)
        double precision p, r

        print '(2g5.2)', p, r
        p=44444.444
        r=4.3d68
        print *, '--> returning modified params p,r:', p, r

        return
      end

      subroutine param(op, degree,  zeror, zeroi, fail)
      
        integer degree
        double precision op(101), zeror(101), zeroi(101)
        logical fail
  
        print *, '--> param.fortran: deg,ops 1,2 ', degree, op(1), op(2)
        
        fail=.false.
        degree=100
  
        return
      end