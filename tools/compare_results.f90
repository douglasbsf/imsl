program compare_results
  use iso_fortran_env, only: real64
  implicit none
  integer,parameter::ncases=19,maxvals=16
  character(24),parameter::names(ncases)=[character(24):: &
    'evcrg','evccg','evlcg','gvcrg','mrrrr','mcrcr','mucrv', &
    'linear_operators','lslcg','lin_sol_gen','rcurv','csiez', &
    'bclsf','unlsf','u4lsf','ivprk','svign','umach','ifnls']
  integer,parameter::counts(ncases)=[4,4,4,4,4,8,4,2,4,2,3,3,2,2,2,1,5,1,0]
  real(real64)::a(maxvals),b(maxvals),max_abs,max_rel,den,atol,rtol
  character(32)::sa,sb,status
  character(256)::pa,pb,pc
  integer::i,j,summary,out
  logical::oka,okb
  call execute_command_line('if not exist results\comparison mkdir results\comparison')
  open(newunit=summary,file='results/comparison/summary.tsv',status='replace',action='write')
  write(summary,'(a)') 'case'//achar(9)//'status'//achar(9)//'max_abs_error'//achar(9)// &
    'max_rel_error'//achar(9)//'abs_tol'//achar(9)//'rel_tol'
  do i=1,ncases
    pa='results/imsl/'//trim(names(i))//'.txt'
    pb='results/opensource/'//trim(names(i))//'.txt'
    pc='results/comparison/'//trim(names(i))//'.txt'
    call read_values(trim(pa),trim(names(i)),counts(i),a,sa,oka)
    call read_values(trim(pb),trim(names(i)),counts(i),b,sb,okb)
    call tolerances(trim(names(i)),atol,rtol)
    ! -1 is the TSV sentinel for unavailable errors when either side did not run.
    max_abs=-1d0;max_rel=-1d0
    if(trim(names(i))=='ifnls') then
      ! IFNLS is Intel NLS (not IMSL). Compare formatted strings when both ran.
      if(oka.and.okb) then
        if(trim(sa)==trim(sb)) then
          status='PASS';max_abs=0d0;max_rel=0d0
        else
          status='FAIL';max_abs=1d0;max_rel=1d0
        end if
      else if(.not.oka.and..not.okb) then
        status='NOT_APPLICABLE';max_abs=0d0;max_rel=0d0
      else if(.not.okb) then
        status=normalize_failure(sb)
      else
        status=normalize_failure(sa)
      end if
    else if(.not.okb) then
      status=normalize_failure(sb)
    else if(.not.oka) then
      status=normalize_failure(sa)
    else
      max_abs=0d0;max_rel=0d0
      do j=1,counts(i)
        max_abs=max(max_abs,abs(a(j)-b(j)))
        den=max(abs(a(j)),abs(b(j)),tiny(1d0))
        max_rel=max(max_rel,abs(a(j)-b(j))/den)
      end do
      if(max_abs<=atol.or.max_rel<=rtol) then
        status='PASS'
      else
        status='FAIL'
      end if
    end if
    open(newunit=out,file=trim(pc),status='replace',action='write')
    write(out,'(a)') 'case='//trim(names(i))
    write(out,'(a)') 'status='//trim(status)
    write(out,'(a,es24.16)') 'max_abs_error=',max_abs
    write(out,'(a,es24.16)') 'max_rel_error=',max_rel
    write(out,'(a,es24.16)') 'abs_tolerance=',atol
    write(out,'(a,es24.16)') 'rel_tolerance=',rtol
    close(out)
    write(summary,'(a,a,a,a,4(a,es24.16))') trim(names(i)),achar(9),trim(status),achar(9), &
      '',max_abs,achar(9),max_rel,achar(9),atol,achar(9),rtol
  end do
  close(summary)
contains
  subroutine read_values(path,label,n,v,state,ok)
    character(*),intent(in)::path,label
    integer,intent(in)::n
    real(real64),intent(out)::v(:)
    character(*),intent(out)::state
    logical,intent(out)::ok
    character(4096)::line
    character(64)::tag
    integer::u,ios
    v=0d0;state='COMPILATION_ERROR';ok=.false.
    open(newunit=u,file=path,status='old',action='read',iostat=ios)
    if(ios/=0)return
    do
      read(u,'(a)',iostat=ios)line
      if(ios/=0)exit
      if(index(adjustl(line),'# STATUS ') == 1) then
        state=trim(adjustl(line(10:)))
        cycle
      end if
      tag='';read(line,*,iostat=ios)tag
      if(ios/=0.or.trim(tag)/=trim(label))cycle
      if(n>0)then
        read(line,*,iostat=ios)tag,v(1:n)
        ok=ios==0
        if(ok)state='RAN'
      else
        ! Capture the remainder of the labeled line for string cases (IFNLS).
        state=trim(adjustl(line(len_trim(label)+1:)))
        ok=.true.
      end if
    end do
    close(u)
  end subroutine

  function normalize_failure(state) result(value)
    character(*),intent(in)::state
    character(32)::value
    select case(trim(state))
    case('BLOCKED');value='BLOCKED'
    case('NOT_APPLICABLE');value='NOT_APPLICABLE'
    case('RUNTIME_ERROR');value='RUNTIME_ERROR'
    case default;value='COMPILATION_ERROR'
    end select
  end function

  subroutine tolerances(name,atol,rtol)
    character(*),intent(in)::name
    real(real64),intent(out)::atol,rtol
    select case(trim(name))
    case('csiez');atol=1d-9;rtol=1d-9
    case('unlsf','u4lsf');atol=1d-7;rtol=1d-7
    case('bclsf');atol=1d-8;rtol=1d-8  ! distinct LM/BNLS solvers; active bound
    case('ivprk');atol=1d-9;rtol=1d-9
    case default;atol=1d-10;rtol=1d-10
    end select
  end subroutine
end program compare_results
