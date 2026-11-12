! IMSL Fortran 90 documented interface example. Requires IMSL installation/license.
program case_bclsf
use iso_fortran_env, only: dp => real64
use bclsf_int
implicit none
real(dp) :: x(2), lower(2),upper(2),guess(2)
external :: rosbck
lower=[-2d0,-1d0]; upper=[0.5d0,2d0]; guess=[-1.2d0,1d0]
call bclsf(rosbck,2,0,lower,upper,x,xguess=guess)
call emit_r('bclsf',x)

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

subroutine rosbck(m,n,x,f)
use iso_fortran_env, only: dp => real64
implicit none
integer,intent(in)::m,n
real(dp),intent(in)::x(n)
real(dp),intent(out)::f(m)
f(1)=10d0*(x(2)-x(1)**2)
f(2)=1d0-x(1)
end subroutine
subroutine ode_rhs(n,t,y,yp)
use iso_fortran_env, only: dp=>real64
implicit none
integer,intent(in)::n
real(dp),intent(in)::t,y(n)
real(dp),intent(out)::yp(n)
yp=-y
end subroutine
