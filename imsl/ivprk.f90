! IMSL Fortran 90 documented interface example. Requires IMSL installation/license.
program case_ivprk
use iso_fortran_env, only: dp => real64
use ivprk_int
implicit none
real(dp) :: t,tend,y(1)
integer :: ido
external :: ode_rhs
t=0d0; tend=1d0; y=[1d0]; ido=1
call ivprk(ido,ode_rhs,t,tend,y,tol=1d-9)
call emit_r('ivprk',y)
ido=3
call ivprk(ido,ode_rhs,t,tend,y,tol=1d-9)

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
