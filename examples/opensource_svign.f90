program validate_svign
  use iso_fortran_env, only: real64
  use stdlib_sorting, only: sort
  use emit_utils, only: emit_real
  implicit none
  integer :: values(5)
  values=[3,-2,5,1,1]
  call sort(values)
  call emit_real('svign',real(values,real64))
end program
