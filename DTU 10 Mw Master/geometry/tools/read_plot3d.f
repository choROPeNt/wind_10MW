      program ReadPlot3D
c---------------------------------------------------------------------------
c     Basic program for reading a 3D Plot3D grid file
c     author: Frederik Zahle frza@dtu.dk
c     date: 20.03.2013
c---------------------------------------------------------------------------
      implicit none

      integer::i,j,k,n,export=0
      type coord
      real(kind=8),dimension(:,:,:),pointer::x,y,z
      end type coord
      integer :: nblock
      integer,dimension(:),allocatable :: ni,nj,nk
      type(coord),dimension(:),allocatable :: blocks
      integer::len
      character(len=128)::filename

      if(iargc().eq.0)then
         print*,'Please supply a filename'
         stop
      endif
      call GETARG(1,filename)
      len=LEN_TRIM(filename)

c     read the unformatted grid file
      print*, 'opening file ',filename(1:len),' ...'
      open(unit=10,file=filename(1:len),form='unformatted')
      read(10)nblock
      allocate(blocks(nblock),ni(nblock),nj(nblock),nk(nblock))
      read(10)(ni(n),nj(n),nk(n),n=1,nblock)
      do n=1,nblock
        allocate(blocks(n)%x(1:ni(n),1:nj(n),1:nk(n))
     &          ,blocks(n)%y(1:ni(n),1:nj(n),1:nk(n))
     &          ,blocks(n)%z(1:ni(n),1:nj(n),1:nk(n)))
        print*,'reading block',n,ni(n),nj(n),nk(n)
        read(10)
     &  (((blocks(n)%x(i,j,k),i=1,ni(n)),j=1,nj(n)),k=1,nk(n)),
     &  (((blocks(n)%y(i,j,k),i=1,ni(n)),j=1,nj(n)),k=1,nk(n)),
     &  (((blocks(n)%z(i,j,k),i=1,ni(n)),j=1,nj(n)),k=1,nk(n))
      enddo
      close(10)

      print*,'Export file to ascii file? (1=yes)'
      read*,export
      open(unit=10,file='export.dat')
      if(export.eq.1)then
         do n=1,nblock
             do k=1,nk(n)
             do j=1,nj(n)
             do i=1,ni(n)
                 write(10,*)blocks(n)%x(i,j,k)
     &                     ,blocks(n)%y(i,j,k)
     &                     ,blocks(n)%z(i,j,k)
             enddo;enddo;enddo
         enddo
      endif

      end

