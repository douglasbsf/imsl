! Bounded nonlinear least squares via GALAHAD BNLS (double precision).
! Same Rosenbrock residual and bounds as IMSL BCLSF validation case.
program validate_bclsf
  use GALAHAD_BNLS_double
  use iso_fortran_env, only: wp => real64, output_unit
  implicit none
  type(NLPT_problem_type) :: nlp
  type(BNLS_control_type) :: control
  type(BNLS_inform_type) :: inform
  type(BNLS_data_type) :: data
  type(USERDATA_type) :: userdata
  integer :: s
  integer, parameter :: n = 2, m_r = 2, jr_ne = 3
  external :: eval_ros_r, eval_ros_jr

  nlp%n = n
  nlp%m_r = m_r
  nlp%Jr%ne = jr_ne
  allocate(nlp%X_l(n), nlp%X_u(n), nlp%X(n))
  nlp%X_l = [-2.0_wp, -1.0_wp]
  nlp%X_u = [0.5_wp, 2.0_wp]
  nlp%X = [-1.2_wp, 1.0_wp]

  call SMT_put(nlp%Jr%type, 'COORDINATE', s)
  allocate(nlp%Jr%val(jr_ne), nlp%Jr%row(jr_ne), nlp%Jr%col(jr_ne))
  ! Dense sparse pattern of Rosenbrock Jacobian:
  ! r1 = 10*(x2 - x1**2); r2 = 1 - x1
  nlp%Jr%row = [1, 1, 2]
  nlp%Jr%col = [1, 2, 1]

  call BNLS_initialize(data, control, inform)
  control%jacobian_available = 2
  control%print_level = 0
  control%subproblem_solver = 1
  control%BLLS_control%SBLS_control%definite_linear_solver = 'potr '
  control%BLLS_control%SBLS_control%symmetric_linear_solver = 'sytr '
  control%BLLSB_control%symmetric_linear_solver = 'sytr '
  control%BLLSB_control%FDC_control%symmetric_linear_solver = 'sytr '
  inform%status = 1
  call BNLS_solve(nlp, control, inform, data, userdata, &
                  eval_R=eval_ros_r, eval_Jr=eval_ros_jr)
  if (inform%status /= 0) then
    write(output_unit,'(a,1x,i0)') 'BNLS_status', inform%status
    error stop 'GALAHAD BNLS failed'
  end if
  write(output_unit,'(a,2(1x,es24.16))') 'bclsf', nlp%X(1), nlp%X(2)
  call BNLS_terminate(data, control, inform)
  deallocate(nlp%X_l, nlp%X_u, nlp%X)
  if (allocated(nlp%Z)) deallocate(nlp%Z)
  if (allocated(nlp%G)) deallocate(nlp%G)
  if (allocated(nlp%R)) deallocate(nlp%R)
  if (allocated(nlp%X_status)) deallocate(nlp%X_status)
  deallocate(nlp%Jr%type, nlp%Jr%val, nlp%Jr%row, nlp%Jr%col)
end program validate_bclsf

subroutine eval_ros_r(status, X, userdata, R)
  use GALAHAD_USERDATA_double
  use iso_fortran_env, only: wp => real64
  implicit none
  integer, intent(out) :: status
  real(wp), dimension(:), intent(in) :: X
  real(wp), dimension(:), intent(out) :: R
  type(USERDATA_type), intent(inout) :: userdata
  R(1) = 10.0_wp * (X(2) - X(1)*X(1))
  R(2) = 1.0_wp - X(1)
  status = 0
  associate(unused => userdata); end associate
end subroutine eval_ros_r

subroutine eval_ros_jr(status, X, userdata, Jr_val)
  use GALAHAD_USERDATA_double
  use iso_fortran_env, only: wp => real64
  implicit none
  integer, intent(out) :: status
  real(wp), dimension(:), intent(in) :: X
  real(wp), dimension(:), intent(out) :: Jr_val
  type(USERDATA_type), intent(inout) :: userdata
  Jr_val(1) = -20.0_wp * X(1)   ! dr1/dx1
  Jr_val(2) = 10.0_wp           ! dr1/dx2
  Jr_val(3) = -1.0_wp           ! dr2/dx1
  status = 0
  associate(unused => userdata); end associate
end subroutine eval_ros_jr
