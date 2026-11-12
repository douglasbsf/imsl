! Open-source Fortran reference: LAPACK + BLAS and Fortran intrinsics.
! Example-only small deterministic problems; NOT an IMSL ABI-compatible replacement.
program oss_lapack_examples
 use iso_fortran_env, only: dp=>real64
 use extra_cases, only: run_extra
 implicit none
 call eigen_real()
 call eigen_complex('evccg')
 call eigen_complex('evlcg')
 call eigen_generalized()
 call mult_real()
 call mult_complex()
 call mult_vector()
 call solve_with_operator()
 call solve_complex()
 call solve_real()
 call poly_fit()
 call spline_not_a_knot()
 call run_extra()
contains
 subroutine emit_r(label,vals)
  character(*),intent(in)::label
  real(dp),intent(in)::vals(:)
  integer::i
  write(*,'(a)',advance='no') trim(label)
  do i=1,size(vals)
   write(*,'(1x,es24.16)',advance='no') vals(i)
  enddo
  write(*,*)
 end subroutine
 subroutine emit_c(label,vals,sort_by_real)
  character(*),intent(in)::label
  complex(dp),intent(in)::vals(:)
  logical,intent(in)::sort_by_real
  complex(dp)::temp,values(size(vals))
  integer::i,j
  values=vals
  if(sort_by_real) then
   do i=1,size(values)
    do j=i+1,size(values)
     if(real(values(j),dp)<real(values(i),dp)) then
      temp=values(i);values(i)=values(j);values(j)=temp
     endif
    enddo
   enddo
  endif
  write(*,'(a)',advance='no') trim(label)
  do i=1,size(values)
   write(*,'(2(1x,es24.16))',advance='no') real(values(i),dp),aimag(values(i))
  enddo
  write(*,*)
 end subroutine
 subroutine require_ok(info,case_name)
  integer,intent(in)::info
  character(*),intent(in)::case_name
  if(info/=0) then
   print *, trim(case_name)//' LAPACK INFO=',info
   error stop 1
  endif
 end subroutine
 subroutine eigen_real()
  real(dp)::a(2,2),wr(2),wi(2),vl(1,1),vr(2,2),work(128)
  complex(dp)::w(2)
  integer::info
  a=0; a(1,1)=2;a(2,2)=2;a(1,2)=1;a(2,1)=1
  call dgeev('N','V',2,a,2,wr,wi,vl,1,vr,2,work,128,info)
  call require_ok(info,'evcrg')
  w=cmplx(wr,wi,dp)
  ! Eigenvector residual for a symmetric 2x2 matrix.
  if(maxval(abs(matmul(reshape([2d0,1d0,1d0,2d0],[2,2]),vr(:,1))-wr(1)*vr(:,1)))>1d-9) &
   error stop 'DGEEV eigenvector residual'
  call emit_c('evcrg',w,.true.)
 end subroutine
 subroutine eigen_complex(label)
  character(*),intent(in)::label
  complex(dp)::a(2,2),original(2,2),w(2),vl(1,1),vr(2,2),work(128)
  real(dp)::rwork(4)
  integer::info
  a=cmplx(0,0,dp);a(1,1)=cmplx(2,1,dp);a(2,2)=cmplx(3,-2,dp);a(1,2)=cmplx(1,0,dp)
  original=a
  call zgeev('N','V',2,a,2,w,vl,1,vr,2,work,128,rwork,info)
  call require_ok(info,label)
  if(maxval(abs(matmul(original,vr(:,1))-w(1)*vr(:,1)))>1d-9) error stop 'ZGEEV residual 1'
  if(maxval(abs(matmul(original,vr(:,2))-w(2)*vr(:,2)))>1d-9) error stop 'ZGEEV residual 2'
  call emit_c(label,w,.true.)
 end subroutine
 subroutine eigen_generalized()
  real(dp)::a(2,2),b(2,2),orig_a(2,2),orig_b(2,2),ar(2),ai(2),beta(2),vr(2,2),vl(1,1),work(128)
  complex(dp)::w(2)
  integer::info
  a=0;b=0;a(1,1)=4;a(2,2)=9;a(1,2)=1;b(1,1)=2;b(2,2)=3
  orig_a=a;orig_b=b
  call dggev('N','V',2,a,2,b,2,ar,ai,beta,vl,1,vr,2,work,128,info)
  call require_ok(info,'gvcrg')
  w=cmplx(ar,ai,dp)/beta
  if(maxval(abs(matmul(orig_a,vr(:,1))-real(w(1),dp)*matmul(orig_b,vr(:,1))))>1d-9) &
   error stop 'DGGEV eigenvector residual 1'
  if(maxval(abs(matmul(orig_a,vr(:,2))-real(w(2),dp)*matmul(orig_b,vr(:,2))))>1d-9) &
   error stop 'DGGEV eigenvector residual 2'
  call emit_c('gvcrg',w,.true.)
 end subroutine
 subroutine mult_real()
  real(dp)::a(2,2),b(2,2),c(2,2)
  a=reshape([1d0,3d0,2d0,4d0],[2,2]);b=reshape([2d0,0d0,1d0,2d0],[2,2])
  call dgemm('N','N',2,2,2,1d0,a,2,b,2,0d0,c,2)
  call emit_r('mrrrr',reshape(c,[4]))
 end subroutine
 subroutine mult_complex()
  complex(dp)::a(2,2),b(2,2),c(2,2)
  a=reshape([cmplx(1,1,dp),cmplx(3,0,dp),cmplx(2,0,dp),cmplx(4,-1,dp)],[2,2])
  b=reshape([cmplx(2,0,dp),cmplx(0,0,dp),cmplx(1,1,dp),cmplx(2,0,dp)],[2,2])
  call zgemm('N','N',2,2,2,cmplx(1,0,dp),a,2,b,2,cmplx(0,0,dp),c,2)
  call emit_c('mcrcr',reshape(c,[4]),.false.)
 end subroutine
 subroutine mult_vector()
  complex(dp)::a(2,2),x(2),y(2)
  a=reshape([cmplx(1,1,dp),cmplx(3,0,dp),cmplx(2,0,dp),cmplx(4,-1,dp)],[2,2])
  x=[cmplx(1,-1,dp),cmplx(2,1,dp)]
  call zgemv('N',2,2,cmplx(1,0,dp),a,2,x,1,cmplx(0,0,dp),y,1)
  call emit_c('mucrv',y,.false.)
 end subroutine
 subroutine solve_with_operator()
  real(dp)::a(2,2),b(2,1)
  integer::ipiv(2),info
  a=0;a(1,1)=2;a(2,2)=4;b(:,1)=[4d0,12d0]
  call dgesv(2,1,a,2,ipiv,b,2,info)
  call require_ok(info,'linear_operators')
  call emit_r('linear_operators',b(:,1))
 end subroutine
 subroutine solve_complex()
  complex(dp)::a(2,2),b(2,1)
  integer::ipiv(2),info
  a=cmplx(0,0,dp);a(1,1)=cmplx(2,1,dp);a(2,2)=cmplx(3,-1,dp)
  b(:,1)=[cmplx(4,2,dp),cmplx(6,-2,dp)]
  call zgesv(2,1,a,2,ipiv,b,2,info)
  call require_ok(info,'lslcg')
  call emit_c('lslcg',b(:,1),.false.)
 end subroutine
 subroutine solve_real()
  real(dp)::a(2,2),b(2,1)
  integer::ipiv(2),info
  a=reshape([3d0,1d0,1d0,2d0],[2,2]);b(:,1)=[9d0,8d0]
  call dgesv(2,1,a,2,ipiv,b,2,info)
  call require_ok(info,'lin_sol_gen')
  call emit_r('lin_sol_gen',b(:,1))
 end subroutine
 subroutine poly_fit()
  real(dp)::xd(5),yd(5),a(5,3),b(5,1),work(256)
  integer::i,info
  xd=[-2d0,-1d0,0d0,1d0,2d0];yd=2d0-xd+0.5d0*xd**2
  do i=1,5
   a(i,:)=[1d0,xd(i),xd(i)**2]
  enddo
  b=0;b(:,1)=yd
  call dgels('N',5,3,1,a,5,b,5,work,256,info)
  call require_ok(info,'rcurv')
  call emit_r('rcurv',b(1:3,1))
 end subroutine
 subroutine spline_not_a_knot()
  ! General cubic-spline system: unknown second derivatives M(i),
  ! with the two not-a-knot third-derivative continuity conditions.
  integer,parameter::n=4
  real(dp)::x(n),y(n),h(n-1),m(n,1),coef(n,n),pts(3),output(3)
  real(dp)::a,b,step,tt
  integer::i,j,ipiv(n),info
  x=[0d0,1d0,2d0,3d0];y=x**3;h=x(2:n)-x(1:n-1)
  coef=0;m=0
  coef(1,1)=-h(2);coef(1,2)=h(1)+h(2);coef(1,3)=-h(1)
  do i=2,n-1
   coef(i,i-1)=h(i-1);coef(i,i)=2d0*(h(i-1)+h(i));coef(i,i+1)=h(i)
   m(i,1)=6d0*((y(i+1)-y(i))/h(i)-(y(i)-y(i-1))/h(i-1))
  enddo
  coef(n,n-2)=-h(n-1);coef(n,n-1)=h(n-2)+h(n-1);coef(n,n)=-h(n-2)
  call dgesv(n,1,coef,n,ipiv,m,n,info)
  call require_ok(info,'csiez')
  pts=[0.5d0,1.5d0,2.5d0]
  do j=1,3
   tt=pts(j)
   i=1
   do while(i<n-1 .and. tt>x(i+1))
    i=i+1
   enddo
   step=h(i);a=(x(i+1)-tt)/step;b=(tt-x(i))/step
   output(j)=a*y(i)+b*y(i+1) + &
             ((a*a*a-a)*m(i,1)+(b*b*b-b)*m(i+1,1))*step*step/6d0
  enddo
  call emit_r('csiez',output)
 end subroutine
end program
