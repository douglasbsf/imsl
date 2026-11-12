! Strictly Fortran 2008 validator. No Python/SciPy/JSON runtime.
! Checks open-source output vs independent analytical reference,
! then optionally compares with outputs produced by licensed IMSL.
program compare
 use iso_fortran_env, only: dp=>real64, output_unit, error_unit, iostat_end
 implicit none
 integer, parameter :: ncases=19, maxdata=16
 character(len=24),parameter :: names(ncases) = [character(len=24) :: &
  'evcrg','evccg','evlcg','gvcrg','mrrrr','mcrcr','mucrv', &
  'linear_operators','lslcg','lin_sol_gen','rcurv','csiez', &
  'bclsf','unlsf','u4lsf','ivprk','svign','umach','ifnls']
 real(dp)::reference(maxdata),os(maxdata,ncases),ims(maxdata),err,threshold
 character(len=256)::oss_locale,ims_locale,rec,status,mode,pathname
 integer::i,n,failures,passed,imsl_count,report,stat
 logical::found,strict,run_imsl

 mode=''; call get_command_argument(1,mode)
 strict=trim(mode)=='--strict-imsl'
 run_imsl=(trim(mode)=='--imsl'.or.strict)
 failures=0;passed=0;imsl_count=0
 os=0d0;oss_locale=''
 open(newunit=report,file='results/comparison.tsv',status='replace',action='write',iostat=stat)
 if(stat/=0) error stop 'Cannot create results/comparison.tsv'
 write(report,'(a)') 'case'//achar(9)//'reference_check'//achar(9)//'imsl_comparison'//achar(9)//'max_abs_error'
 write(output_unit,'(a)') 'FORTRAN VALIDATOR: analytical reference vs open-source result'
 do i=1,ncases
  call expected(names(i),reference,n)
  call read_result('results/opensource.txt',names(i),n,os(:,i),oss_locale,found)
  if(.not.found) then
   write(error_unit,'(2a)') 'MISSING open-source case: ',trim(names(i))
   failures=failures+1
   cycle
  endif
  if(names(i)=='ifnls') then
   err=0d0
   if(trim(oss_locale)/='1.234,50') err=1d0
  else
   err=maxval(abs(os(1:n,i)-reference(1:n)))
  endif
  threshold=tol(names(i))
  if(err>threshold) then
   write(error_unit,'(a,1x,a,1x,es12.4)') 'FAIL reference:',trim(names(i)),err
   failures=failures+1;rec='FAIL'
  else
   write(output_unit,'(2a)') 'PASS reference: ',trim(names(i))
   passed=passed+1;rec='PASS'
  endif
  status='NOT_RUN'
  if(run_imsl) then
   pathname='results/imsl/'//trim(names(i))//'.txt'
   call read_result(trim(pathname),names(i),n,ims,ims_locale,found)
   if(found) then
    imsl_count=imsl_count+1
    if(names(i)=='ifnls') then
     err=0d0
     if(trim(ims_locale)/=trim(oss_locale)) err=1d0
    else
     err=maxval(abs(ims(1:n)-os(1:n,i)))
    endif
    if(err<=tol(names(i))) then
     status='PASS'
    else
     status='FAIL'
     failures=failures+1
    endif
   else if(strict) then
    status='MISSING'
    failures=failures+1
   endif
  endif
  write(report,'(a)') trim(names(i))//achar(9)//trim(rec)//achar(9)//trim(status)//achar(9)// &
                       to_string(err)
  if(run_imsl) write(output_unit,'(4a)') 'IMSL compare ',trim(names(i)),': ',trim(status)
 enddo
 close(report)
 write(output_unit,'(a,i0,a,i0)') 'OPEN-SOURCE VERIFIED: ',passed,' / ',ncases
 if(run_imsl) write(output_unit,'(a,i0,a,i0)') 'IMSL OUTPUTS READ: ',imsl_count,' / ',ncases
 write(output_unit,'(a)') 'Report: results/comparison.tsv'
 if(failures>0) error stop 'Validation failed; inspect results/comparison.tsv'
contains
 subroutine expected(name,v,n)
  character(*),intent(in)::name
  real(dp),intent(out)::v(:)
  integer,intent(out)::n
  v=0d0
  select case(trim(name))
  case('evcrg');v(1:4)=[1d0,0d0,3d0,0d0];n=4
  case('evccg','evlcg');v(1:4)=[2d0,1d0,3d0,-2d0];n=4
  case('gvcrg');v(1:4)=[2d0,0d0,3d0,0d0];n=4
  case('mrrrr');v(1:4)=[2d0,6d0,5d0,11d0];n=4
  case('mcrcr');v(1:8)=[2d0,2d0,6d0,0d0,4d0,2d0,11d0,1d0];n=8
  case('mucrv');v(1:4)=[6d0,2d0,12d0,-1d0];n=4
  case('linear_operators','lin_sol_gen');v(1:2)=[2d0,3d0];n=2
  case('lslcg');v(1:4)=[2d0,0d0,2d0,0d0];n=4
  case('rcurv');v(1:3)=[2d0,-1d0,.5d0];n=3
  case('csiez');v(1:3)=[.125d0,3.375d0,15.625d0];n=3
  case('bclsf');v(1:2)=[.5d0,.25d0];n=2
  case('unlsf','u4lsf');v(1:2)=[1d0,1d0];n=2
  case('ivprk');v(1)=exp(-1d0);n=1
  case('svign');v(1:5)=[-2d0,1d0,1d0,3d0,5d0];n=5
  case('umach');v(1)=1d0;n=1
  case('ifnls');n=0
  case default
   error stop 'No analytical reference for case'
  end select
 end subroutine

 pure real(dp) function tol(name)
  character(*),intent(in)::name
  select case(trim(name))
   case('bclsf','ivprk');tol=1d-5
   case('unlsf','u4lsf');tol=1d-6
   case default;tol=1d-8
  end select
 end function

 subroutine read_result(path,label,n,values,locale,found)
  character(*),intent(in)::path,label
  integer,intent(in)::n
  real(dp),intent(out)::values(:)
  character(*),intent(out)::locale
  logical,intent(out)::found
  character(len=4096)::line
  character(len=128)::tag
  integer::u,st,k
  found=.false.;values=0d0;locale=''
  open(newunit=u,file=path,status='old',action='read',iostat=st)
  if(st/=0) return
  do
   read(u,'(a)',iostat=st) line
   if(st/=0) exit
   tag='';read(line,*,iostat=st) tag
   if(st/=0.or.trim(tag)/=trim(label)) cycle
   if(trim(label)=='ifnls') then
    k=index(adjustl(line),' ')
    if(k<=0) cycle
    locale=trim(adjustl(line(k+1:)))
    found=.true.;exit
   endif
   read(line,*,iostat=st) tag,values(1:n)
   if(st==0) then
    found=.true.;exit
   endif
  enddo
  close(u)
 end subroutine

 function to_string(v) result(s)
  real(dp),intent(in)::v
  character(len=32)::s
  write(s,'(es16.8)') v
  s=adjustl(s)
 end function
end program
