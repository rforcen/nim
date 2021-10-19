! sample params passing based on descriptors for a(:)

! descriptors not required as size is fixed
subroutine parammatrix(a,b)
  real,intent(inout) :: a(3,3),b(3)
  print *,'sizeof a ,b', size(a), size(b)
  print *,'a,b:', a,b
end subroutine parammatrix

subroutine pva1d(a)
  real,intent(inout) :: a(:)

  print *,'PVA1d -> size a(:) -> ', size(a,1)
  write (*,'(g5.1)') a
  a = (/111,222,333,444,555,666/)
  a(7)=777

end subroutine pva1d

subroutine pva2d(a)
  real,intent(inout) :: a(:,:)

  print *,'PVA2d -> size a(:,:) -> ', size(a), size(a,1), size(a,2)
  write (*,'(g5.1)') a
  a(1,1)=9999
  a(2,1)=8888
  a(1,2)=7677767
  a(1,3)=7677767
end subroutine pva2d
