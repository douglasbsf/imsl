program dbg
  character(256)::line
  character(64)::tag
  real(8)::v(4)
  integer::u,ios
  open(newunit=u,file='results/imsl/evcrg.txt',status='old',action='read',iostat=ios)
  print *,'open ios',ios
  read(u,'(a)',iostat=ios)line
  print *,'line=[',trim(line),'] ios',ios
  read(line,*,iostat=ios)tag
  print *,'tag=[',trim(tag),'] ios',ios
  read(line,*,iostat=ios)tag,v(1:4)
  print *,'vals',v,'ios',ios
end program
