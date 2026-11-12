module emit_utils
  use iso_fortran_env, only: real64, output_unit
  implicit none
  private
  public :: emit_real, emit_complex, sort_complex_real
contains
  subroutine emit_real(label, values)
    character(*), intent(in) :: label
    real(real64), intent(in) :: values(:)
    integer :: i
    write(output_unit,'(a)',advance='no') trim(label)
    do i=1,size(values)
      write(output_unit,'(1x,es24.16)',advance='no') values(i)
    end do
    write(output_unit,*)
  end subroutine

  subroutine emit_complex(label, values, sorted)
    character(*), intent(in) :: label
    complex(real64), intent(in) :: values(:)
    logical, intent(in), optional :: sorted
    complex(real64) :: copy(size(values))
    integer :: i
    copy=values
    if (present(sorted)) then
      if (sorted) call sort_complex_real(copy)
    end if
    write(output_unit,'(a)',advance='no') trim(label)
    do i=1,size(copy)
      write(output_unit,'(2(1x,es24.16))',advance='no') real(copy(i),real64),aimag(copy(i))
    end do
    write(output_unit,*)
  end subroutine

  subroutine sort_complex_real(values)
    complex(real64), intent(inout) :: values(:)
    complex(real64) :: tmp
    integer :: i,j
    do i=1,size(values)-1
      do j=i+1,size(values)
        if (real(values(j),real64)<real(values(i),real64)) then
          tmp=values(i); values(i)=values(j); values(j)=tmp
        end if
      end do
    end do
  end subroutine
end module emit_utils
