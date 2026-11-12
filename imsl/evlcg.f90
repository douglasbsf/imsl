! IMSL Fortran 90 documented interface example. Requires IMSL installation/license.
program case_evlcg
use iso_fortran_env, only: dp => real64
use evlcg_int
implicit none
complex(dp) :: a(2,2), w(2)
a=cmplx(0,0,dp); a(1,1)=cmplx(2,1,dp); a(2,2)=cmplx(3,-2,dp); a(1,2)=cmplx(1,0,dp)
call evlcg(a,w)
call emit_c('evlcg', w)

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
