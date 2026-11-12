! IMSL Fortran 90 documented interface example. Requires IMSL installation/license.
program case_evcrg
use iso_fortran_env, only: dp => real64
use evcrg_int
implicit none
real(dp) :: a(2,2)
complex(dp) :: w(2),v(2,2)
integer :: j
a=0; a(1,1)=2; a(2,2)=2; a(1,2)=1; a(2,1)=1
call evcrg(a,w,v)
do j=1,2
 if(maxval(abs(matmul(cmplx(a,kind=dp),v(:,j))-w(j)*v(:,j)))>1d-7) error stop 'EVCRG eigenvector residual'
enddo
call emit_c('evcrg', w)

contains
subroutine emit_r(label,vals)
character(*), intent(in) :: label
real(dp), intent(in) :: vals(:)
integer :: i
write(*,'(a)',advance='no') trim(label)
do i=1,size(vals)
 write(*,'(1x,es24.16)',advance='no') vals(i)
enddo
write(*,*)
end subroutine
subroutine emit_c(label,vals)
character(*), intent(in) :: label
complex(dp),intent(in) :: vals(:)
integer :: i
! Order eigenvalues by increasing REAL part, so library ordering does not affect comparison.
complex(dp) :: sorted(size(vals)), tmp
integer :: j
sorted=vals
if(label=='evcrg'.or.label=='evccg'.or.label=='evlcg'.or.label=='gvcrg') then
 do i=1,size(sorted)
  do j=i+1,size(sorted)
   if (real(sorted(j)) < real(sorted(i))) then
    tmp=sorted(i); sorted(i)=sorted(j); sorted(j)=tmp
   endif
  enddo
 enddo
endif
write(*,'(a)',advance='no') trim(label)
do i=1,size(sorted)
 write(*,'(2(1x,es24.16))',advance='no') real(sorted(i),dp),aimag(sorted(i))
enddo
write(*,*)
end subroutine

end program
