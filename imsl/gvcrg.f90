! IMSL Fortran 90 documented interface example. Requires IMSL installation/license.
program case_gvcrg
use iso_fortran_env, only: dp => real64
use gvcrg_int
implicit none
real(dp) :: a(2,2), b(2,2), beta(2)
complex(dp) :: alpha(2), vec(2,2), w(2)
a=0; b=0; a(1,1)=4; a(2,2)=9; a(1,2)=1; b(1,1)=2; b(2,2)=3
call gvcrg(a,b,alpha,beta,vec)
w=alpha/beta
if(maxval(abs(matmul(cmplx(a,kind=dp),vec(:,1))-w(1)*matmul(cmplx(b,kind=dp),vec(:,1))))>1d-7) &
 error stop 'GVCRG residual 1'
if(maxval(abs(matmul(cmplx(a,kind=dp),vec(:,2))-w(2)*matmul(cmplx(b,kind=dp),vec(:,2))))>1d-7) &
 error stop 'GVCRG residual 2'
call emit_c('gvcrg',w)

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
