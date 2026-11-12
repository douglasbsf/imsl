! Intel Fortran Windows-specific NLS module, NOT an IMSL routine.
program case_ifnls
use ifnls
implicit none
character(80) :: value
integer :: status,n
status=NLSSetLocale('Spanish','Spain')
n=NLSFormatNumber(value,'1234.50')
if (n<0) error stop 'NLSFormatNumber failed'
print '(a,1x,a)', 'ifnls',trim(value)
end program
