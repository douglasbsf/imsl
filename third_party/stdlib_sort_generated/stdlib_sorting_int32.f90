! Integer-only extraction of Fortran-lang stdlib SORT (Musser introsort).
! Generated from third_party/stdlib_sort via fypp, then reduced to int32 for
! SVIGN validation without pulling string/bitset dependencies.
module stdlib_sorting
  use iso_fortran_env, only: int32, real64
  implicit none
  private
  integer, parameter :: int_index = int32
  integer, parameter :: dp = real64
  public :: sort
  interface sort
    module procedure sort_int32
  end interface
contains
  pure subroutine sort_int32(array, reverse)
    integer(int32), intent(inout) :: array(:)
    logical, intent(in), optional :: reverse
    integer(int32) :: work(size(array))
    integer :: n
    n = size(array)
    if (n <= 1) return
    ! stdlib uses 0-based assumed-shape views; adapt with a local copy.
    work = array
    if (present(reverse)) then
      if (reverse) then
        work = -work
        call int32_increase_sort(work)
        work = -work
        array = work
        return
      end if
    end if
    call int32_increase_sort(work)
    array = work
  end subroutine

  pure subroutine int32_increase_sort(array)
    integer(int32), intent(inout) :: array(0:)
    integer(int32) :: depth_limit
    depth_limit = 2 * int(floor(log(real(size(array, kind=int_index), kind=dp)) / log(2.0_dp)), kind=int32)
    call introsort(array, depth_limit)
  contains
    pure recursive subroutine introsort(array, depth_limit)
      integer(int32), intent(inout) :: array(0:)
      integer(int32), intent(in) :: depth_limit
      integer(int_index), parameter :: insert_size = 16_int_index
      integer(int_index) :: index
      if (size(array, kind=int_index) <= insert_size) then
        call insertion_sort(array)
      else if (depth_limit == 0) then
        call heap_sort(array)
      else
        call partition(array, index)
        call introsort(array(0:index-1), depth_limit-1)
        call introsort(array(index+1:), depth_limit-1)
      end if
    end subroutine

    pure subroutine partition(array, index)
      integer(int32), intent(inout) :: array(0:)
      integer(int_index), intent(out) :: index
      integer(int32) :: u, v, w, x, y
      integer(int_index) :: i, j
      u = array(0)
      v = array(size(array, kind=int_index)/2-1)
      w = array(size(array, kind=int_index)-1)
      if ((u > v) .neqv. (u > w)) then
        x = u
        y = array(0)
        array(0) = array(size(array, kind=int_index)-1)
        array(size(array, kind=int_index)-1) = y
      else if ((v < u) .neqv. (v < w)) then
        x = v
        y = array(size(array, kind=int_index)/2-1)
        array(size(array, kind=int_index)/2-1) = array(size(array, kind=int_index)-1)
        array(size(array, kind=int_index)-1) = y
      else
        x = w
      end if
      i = -1_int_index
      do j = 0_int_index, size(array, kind=int_index)-2
        if (array(j) <= x) then
          i = i + 1
          y = array(i)
          array(i) = array(j)
          array(j) = y
        end if
      end do
      y = array(i+1)
      array(i+1) = array(size(array, kind=int_index)-1)
      array(size(array, kind=int_index)-1) = y
      index = i + 1
    end subroutine

    pure subroutine insertion_sort(array)
      integer(int32), intent(inout) :: array(0:)
      integer(int_index) :: i, j
      integer(int32) :: key
      do j = 1_int_index, size(array, kind=int_index)-1
        key = array(j)
        i = j - 1
        do while (i >= 0)
          if (array(i) <= key) exit
          array(i+1) = array(i)
          i = i - 1
        end do
        array(i+1) = key
      end do
    end subroutine

    pure subroutine heap_sort(array)
      integer(int32), intent(inout) :: array(0:)
      integer(int_index) :: i, heap_size
      integer(int32) :: y
      heap_size = size(array, kind=int_index)
      do i = (heap_size-2)/2_int_index, 0_int_index, -1_int_index
        call max_heapify(array, i, heap_size)
      end do
      do i = heap_size-1, 1_int_index, -1_int_index
        y = array(0)
        array(0) = array(i)
        array(i) = y
        call max_heapify(array, 0_int_index, i)
      end do
    end subroutine

    pure recursive subroutine max_heapify(array, i, heap_size)
      integer(int32), intent(inout) :: array(0:)
      integer(int_index), intent(in) :: i, heap_size
      integer(int_index) :: l, r, largest
      integer(int32) :: y
      largest = i
      l = 2_int_index * i + 1_int_index
      r = l + 1_int_index
      if (l < heap_size) then
        if (array(l) > array(largest)) largest = l
      end if
      if (r < heap_size) then
        if (array(r) > array(largest)) largest = r
      end if
      if (largest /= i) then
        y = array(i)
        array(i) = array(largest)
        array(largest) = y
        call max_heapify(array, largest, heap_size)
      end if
    end subroutine
  end subroutine int32_increase_sort
end module stdlib_sorting
