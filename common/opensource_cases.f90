module opensource_cases
  use iso_fortran_env, only: real64, output_unit
  use emit_utils
  use minpack_module, only: lmdif1
  use fitpack_core, only: FP_REAL, FP_SIZE, FP_FLAG, curfit, splev, &
    IOPT_NEW_SMOOTHING, OUTSIDE_EXTRAPOLATE, FITPACK_SUCCESS
  use dop853_module, only: dop853_class, dop853_wp
  implicit none
  private
  public :: run_case
contains
  subroutine run_case(name)
    character(*), intent(in) :: name
    select case(name)
    case('evcrg'); call eigen_real()
    case('evccg','evlcg'); call eigen_complex(name)
    case('gvcrg'); call eigen_generalized()
    case('mrrrr'); call multiply_real()
    case('mcrcr'); call multiply_complex()
    case('mucrv'); call multiply_vector()
    case('linear_operators'); call solve_real(name,.true.)
    case('lslcg'); call solve_complex()
    case('lin_sol_gen'); call solve_real(name,.false.)
    case('rcurv'); call polynomial_fit()
    case('csiez'); call spline_fitpack()
    case('unlsf'); call solve_minpack(name,1.0e-10_real64)
    case('u4lsf'); call solve_minpack(name,1.0e-9_real64)
    case('ivprk'); call integrate_dop853()
    case('umach'); call emit_real(name,[1.0_real64])
    case('ifnls'); write(output_unit,'(a)') 'ifnls 1.234,50'
    case default; error stop 'unknown validation case'
    end select
  end subroutine

  subroutine check(info,name)
    integer,intent(in)::info
    character(*),intent(in)::name
    if(info/=0) error stop trim(name)//' library failure'
  end subroutine

  subroutine eigen_real()
    real(real64)::a(2,2),wr(2),wi(2),vl(1,1),vr(1,1),work(64)
    complex(real64)::w(2)
    integer::info
    a=reshape([2d0,1d0,1d0,2d0],[2,2])
    call dgeev('N','N',2,a,2,wr,wi,vl,1,vr,1,work,size(work),info)
    call check(info,'DGEEV');w=cmplx(wr,wi,real64)
    call emit_complex('evcrg',w,.true.)
  end subroutine

  subroutine eigen_complex(name)
    character(*),intent(in)::name
    complex(real64)::a(2,2),w(2),vl(1,1),vr(1,1),work(64)
    real(real64)::rwork(4)
    integer::info
    a=cmplx(0d0,0d0,real64);a(1,1)=cmplx(2d0,1d0,real64)
    a(2,2)=cmplx(3d0,-2d0,real64);a(1,2)=cmplx(1d0,0d0,real64)
    call zgeev('N','N',2,a,2,w,vl,1,vr,1,work,size(work),rwork,info)
    call check(info,'ZGEEV');call emit_complex(name,w,.true.)
  end subroutine

  subroutine eigen_generalized()
    real(real64)::a(2,2),b(2,2),ar(2),ai(2),beta(2),vl(1,1),vr(1,1),work(64)
    complex(real64)::w(2)
    integer::info
    a=0d0;b=0d0;a(1,1)=4d0;a(1,2)=1d0;a(2,2)=9d0;b(1,1)=2d0;b(2,2)=3d0
    call dggev('N','N',2,a,2,b,2,ar,ai,beta,vl,1,vr,1,work,size(work),info)
    call check(info,'DGGEV');w=cmplx(ar,ai,real64)/beta
    call emit_complex('gvcrg',w,.true.)
  end subroutine

  subroutine multiply_real()
    real(real64)::a(2,2),b(2,2),c(2,2)
    a=reshape([1d0,3d0,2d0,4d0],[2,2]);b=reshape([2d0,0d0,1d0,2d0],[2,2])
    call dgemm('N','N',2,2,2,1d0,a,2,b,2,0d0,c,2)
    call emit_real('mrrrr',reshape(c,[4]))
  end subroutine

  subroutine multiply_complex()
    complex(real64)::a(2,2),b(2,2),c(2,2)
    a=reshape([cmplx(1d0,1d0,real64),cmplx(3d0,0d0,real64), &
      cmplx(2d0,0d0,real64),cmplx(4d0,-1d0,real64)],[2,2])
    b=reshape([cmplx(2d0,0d0,real64),cmplx(0d0,0d0,real64), &
      cmplx(1d0,1d0,real64),cmplx(2d0,0d0,real64)],[2,2])
    call zgemm('N','N',2,2,2,cmplx(1d0,0d0,real64),a,2,b,2, &
      cmplx(0d0,0d0,real64),c,2)
    call emit_complex('mcrcr',reshape(c,[4]))
  end subroutine

  subroutine multiply_vector()
    complex(real64)::a(2,2),x(2),y(2)
    a=reshape([cmplx(1d0,1d0,real64),cmplx(3d0,0d0,real64), &
      cmplx(2d0,0d0,real64),cmplx(4d0,-1d0,real64)],[2,2])
    x=[cmplx(1d0,-1d0,real64),cmplx(2d0,1d0,real64)]
    call zgemv('N',2,2,cmplx(1d0,0d0,real64),a,2,x,1,cmplx(0d0,0d0,real64),y,1)
    call emit_complex('mucrv',y)
  end subroutine

  subroutine solve_real(name,diagonal)
    character(*),intent(in)::name
    logical,intent(in)::diagonal
    real(real64)::a(2,2),b(2,1)
    integer::ipiv(2),info
    if(diagonal) then
      a=0d0;a(1,1)=2d0;a(2,2)=4d0;b(:,1)=[4d0,12d0]
    else
      a=reshape([3d0,1d0,1d0,2d0],[2,2]);b(:,1)=[9d0,8d0]
    end if
    call dgesv(2,1,a,2,ipiv,b,2,info);call check(info,'DGESV')
    call emit_real(name,b(:,1))
  end subroutine

  subroutine solve_complex()
    complex(real64)::a(2,2),b(2,1)
    integer::ipiv(2),info
    a=cmplx(0d0,0d0,real64);a(1,1)=cmplx(2d0,1d0,real64)
    a(2,2)=cmplx(3d0,-1d0,real64);b(:,1)=[cmplx(4d0,2d0,real64),cmplx(6d0,-2d0,real64)]
    call zgesv(2,1,a,2,ipiv,b,2,info);call check(info,'ZGESV')
    call emit_complex('lslcg',b(:,1))
  end subroutine

  subroutine polynomial_fit()
    real(real64)::x(5),y(5),a(5,3),b(5,1),work(128)
    integer::i,info
    x=[-2d0,-1d0,0d0,1d0,2d0];y=2d0-x+0.5d0*x*x
    do i=1,5;a(i,:)=[1d0,x(i),x(i)*x(i)];end do
    b(:,1)=y;call dgels('N',5,3,1,a,5,b,5,work,size(work),info)
    call check(info,'DGELS');call emit_real('rcurv',b(1:3,1))
  end subroutine

  subroutine spline_fitpack()
    integer(FP_SIZE),parameter::m=4_FP_SIZE,k=3_FP_SIZE,nest=8_FP_SIZE,lwrk=m*(k+1)+nest*(7+3*k)
    real(FP_REAL)::x(m),y(m),w(m),xp(3),yp(3),t(nest),c(nest),wrk(lwrk),fp
    integer(FP_SIZE)::n,iwrk(nest)
    integer(FP_FLAG)::ier
    x=[0d0,1d0,2d0,3d0];y=x**3;w=1d0;xp=[0.5d0,1.5d0,2.5d0]
    call curfit(IOPT_NEW_SMOOTHING,m,x,y,w,x(1),x(m),k,0d0,nest,n,t,c,fp,wrk,lwrk,iwrk,ier)
    if(.not.FITPACK_SUCCESS(ier)) error stop 'FITPACK curfit failure'
    call splev(t,n,c,k,xp,yp,3_FP_SIZE,OUTSIDE_EXTRAPOLATE,ier)
    if(.not.FITPACK_SUCCESS(ier)) error stop 'FITPACK splev failure'
    call emit_real('csiez',real(yp,real64))
  end subroutine

  subroutine solve_minpack(name,tol)
    character(*),intent(in)::name
    real(real64),intent(in)::tol
    integer,parameter::m=2,n=2,lwa=m*n+5*n+m
    real(real64)::x(n),f(m),wa(lwa)
    integer::info,iwa(n)
    x=[-1.2d0,1d0]
    call lmdif1(rosenbrock,m,n,x,f,tol,info,iwa,wa,lwa)
    if(info<=0.or.info>4) error stop 'MINPACK lmdif1 failure'
    call emit_real(name,x)
  end subroutine

  subroutine rosenbrock(m,n,x,f,iflag)
    integer,intent(in)::m,n
    real(real64),intent(in)::x(n)
    real(real64),intent(out)::f(m)
    integer,intent(inout)::iflag
    f=[10d0*(x(2)-x(1)**2),1d0-x(1)]
  end subroutine

  subroutine integrate_dop853()
    type(dop853_class)::solver
    real(dop853_wp)::x,y(1),rtol(1),atol(1)
    integer::idid
    logical::ok
    x=0d0;y=1d0;rtol=1d-11;atol=1d-13
    call solver%initialize(fcn=decay,n=1,status_ok=ok)
    if(.not.ok) error stop 'DOP853 initialization failure'
    call solver%integrate(x,y,1d0,rtol,atol,iout=0,idid=idid)
    if(idid<1) error stop 'DOP853 integration failure'
    call emit_real('ivprk',real(y,real64))
  end subroutine

  subroutine decay(me,x,y,f)
    class(dop853_class),intent(inout)::me
    real(dop853_wp),intent(in)::x,y(:)
    real(dop853_wp),intent(out)::f(:)
    f=-y
  end subroutine
end module opensource_cases
