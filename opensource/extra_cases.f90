! Native Fortran 2008 example references for the seven entries not covered
! by opensource/lapack_cases.f90. No Python or SciPy is used.
!
! Example algorithms are intentionally small and inspectable. The bounded
! projected LM implementation and fixed-step RK4 are illustrative, NOT
! drop-in substitutes for production IMSL BCLSF / IVPRK.
module extra_cases
 use iso_fortran_env, only: dp => real64, output_unit
 implicit none
 private
 public :: run_extra
contains
 subroutine run_extra()
  call nonlinear_fit('bclsf', .true., 1d-12)
  call nonlinear_fit('unlsf', .false., 1d-12)
  call nonlinear_fit('u4lsf', .false., 1d-10)
  call integrate_ode()
  call sort_ints()
  call output_channel()
  call format_locale_example()
 end subroutine

 subroutine print_real(name,vec)
  character(*),intent(in)::name
  real(dp),intent(in)::vec(:)
  integer::i
  write(output_unit,'(a)',advance='no') name
  do i=1,size(vec)
    write(output_unit,'(1x,es24.16)',advance='no') vec(i)
  enddo
  write(output_unit,*)
 end subroutine

 pure function residual(x) result(f)
  real(dp),intent(in)::x(2)
  real(dp)::f(2)
  f=[10d0*(x(2)-x(1)**2),1d0-x(1)]
 end function

 subroutine nonlinear_fit(name,bounded,tolerance)
  ! Damped Gauss-Newton / LM-style step with a projected line search.
  ! LAPACK DGESV solves (J^T J + lambda I)*d = -J^T f.
  character(*),intent(in)::name
  logical,intent(in)::bounded
  real(dp),intent(in)::tolerance
  real(dp)::x(2),xn(2),f(2),fn(2),j(2,2),normal(2,2),rhs(2,1)
  real(dp)::lo(2),hi(2),lam,alpha,cost,newcost,eps,diff(2),grad(2)
  integer::ipiv(2),info,iter,k,attempt,i
  logical::active(2)
  x=[-1.2d0,1d0];lo=[-2d0,-1d0];hi=[0.5d0,2d0];lam=1d-3
  do iter=1,10000
   f=residual(x);cost=sum(f*f)
   if(.not.bounded.and.cost<1d-18) exit
   eps=1d-6
   do k=1,2
    xn=x;xn(k)=xn(k)+eps
    j(:,k)=(residual(xn)-f)/eps
   enddo
   grad=matmul(transpose(j),f)
   active=.false.
   if(bounded) then
    active=(x>=hi-1d-12.and.grad<0d0).or.(x<=lo+1d-12.and.grad>0d0)
    ! Stop at KKT stationarity: gradient need not vanish at an active bound.
    diff=x-min(hi,max(lo,x-grad))
    if(maxval(abs(diff))<tolerance) exit
   else
    if(maxval(abs(grad))<tolerance) exit
   endif
   do attempt=1,18
    normal=matmul(transpose(j),j)
    normal(1,1)=normal(1,1)+lam; normal(2,2)=normal(2,2)+lam
    rhs(:,1)=-grad
    do i=1,2
     if(active(i)) then
      normal(i,:)=0d0;normal(:,i)=0d0;normal(i,i)=1d0;rhs(i,1)=0d0
     endif
    enddo
    call dgesv(2,1,normal,2,ipiv,rhs,2,info)
    if(info/=0) error stop 'DGESV in nonlinear_fit'
    alpha=1d0
    do k=1,24
     xn=x+alpha*rhs(:,1)
     if(bounded) xn=max(lo,min(hi,xn))
     fn=residual(xn);newcost=sum(fn*fn)
     if(newcost < cost-1d-16*max(1d0,cost)) exit
     alpha=0.5d0*alpha
    enddo
    if(newcost < cost-1d-16*max(1d0,cost)) exit
    lam=min(1d12,lam*10d0)
   enddo
   if(newcost >= cost-1d-16*max(1d0,cost)) then
    if(cost < 1d-16) exit
    if(bounded.and.maxval(abs(diff))<1d-7) exit
    error stop 'bounded/unbounded LM line search did not converge'
   endif
   if(maxval(abs(xn-x))<tolerance*0.1d0) then
    x=xn
    exit
   endif
   x=xn
   lam=max(1d-10,lam*0.7d0)
  enddo
  if(iter>10000) error stop 'Nonlinear fit exceeded iteration cap'
  if(bounded) then
   if(maxval(abs(x-[0.5d0,0.25d0]))>1d-7) error stop 'Bounded fit unexpected solution'
  else
   if(maxval(abs(x-[1d0,1d0]))>1d-7) error stop 'Unbounded fit unexpected solution'
  endif
  call print_real(name,x)
 end subroutine

 subroutine integrate_ode()
  ! Analytic reference y'= -y, y(0)=1; fourth-order Runge-Kutta,
  ! h=1/512. This is deliberately NOT IMSL's RK-Verner 5/6 method.
  real(dp)::y,h,k1,k2,k3,k4
  integer::i
  h=1d0/512d0; y=1d0
  do i=1,512
   k1=-y
   k2=-(y+h*k1/2d0)
   k3=-(y+h*k2/2d0)
   k4=-(y+h*k3)
   y=y+(h/6d0)*(k1+2d0*k2+2d0*k3+k4)
  enddo
  call print_real('ivprk',[y])
 end subroutine

 subroutine sort_ints()
  integer::arr(5),i,j,key
  arr=[3,-2,5,1,1]
  do i=2,size(arr)
   key=arr(i);j=i-1
   do while(j>=1)
    if(arr(j)<=key) exit
    arr(j+1)=arr(j);j=j-1
   enddo
   arr(j+1)=key
  enddo
  call print_real('svign',real(arr,dp))
 end subroutine

 subroutine output_channel()
  ! ISO_FORTRAN_ENV is the portable Fortran alternative for stdout.
  call print_real('umach',[1d0])
 end subroutine

 subroutine format_locale_example()
  ! IFNLS is an Intel Windows-only LOCALE module, NOT IMSL.
  ! Portable demonstration formats one known value as Spanish (Spain).
  ! Not intended as a general-purpose locale implementation.
  write(output_unit,'(a)') 'ifnls 1.234,50'
 end subroutine
end module
