  subroutine init_servo_with_limits(array1,array2)
  use servo_with_limits_data
  implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'init_servo_with_limits'::init_servo_with_limits
  real*8 array1(7),array2(1)
! Input array1 must contain
!
!    1: Number of blades [-]
!    2: Filter frequency [Hz]  
!    3: Filter damping ratio [-]
!    4: Max. pitch speed [deg/s]
!    5: Max. pitch acceleration [deg/s^2]
!    6: Min. pitch angle [deg]  
!    7: Max. pitch angle [deg] 
!
! Output array2 contains nothing
!
! Save parameters
  nblades  =int(array1(1))
  omega0   =array1(2)*2.d0*pi
!  filt(1:3)%f0=array1(2)
!  filt(1:3)%ksi=array1(3)
  beta0    =array1(3)
  vmax     =array1(4)*pi/180.d0
  amax     =array1(5)*pi/180.d0
  theta_min=array1(6)*pi/180.d0
  theta_max=array1(7)*pi/180.d0
! Set initial conditions 
  ynew(1,1:nblades)=0.d0
  ynew(2,1:nblades)=0.d0
! Set oldtime
  stepno=0
  oldtime=0.d0
  array2=0.d0
  return
  end subroutine init_servo_with_limits
!***********************************************************************
  subroutine update_servo_with_limits(array1,array2)
  use servo_with_limits_data
!  use imsl
  implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'update_servo_with_limits'::update_servo_with_limits
  real*8 array1(4),array2(9)
! Input array1 must contain
!
!    1: Time                                  [s]
!    2: Pitch1 demand angle                   [rad] 
!    3: Pitch2 demand angle                   [rad] 
!    4: Pitch3 demand angle                   [rad] 
!
! Output array2 contains
!
!            1: Pitch1 angle                          [rad] 
!            2: Pitch2 angle                          [rad] 
!            3: Pitch3 angle                          [rad] 
!    nblades+1: Pitch1 velocity                       [rad/s] 
!    nblades+2: Pitch2 velocity                       [rad/s] 
!    nblades+3: Pitch3 velocity                       [rad/s] 
!  2*nblades+1: Pitch1 acceleration                   [rad/s^2] 
!  2*nblades+2: Pitch2 acceleration                   [rad/s^2] 
!  2*nblades+3: Pitch3 acceleration                   [rad/s^2] 
!
! Local variables
  integer*4 i,j,ido
  real*8 tol,param(50),y(2),t,tend,timestep
  parameter(tol=1.d-5)
  real*8 theta
  real*8 work(15),relerr,abserr
  parameter(abserr=1.d-8)
  integer*4 iflag,iwork(5)
  external ode
! Initial call values
  relerr=1.d-4
  iflag=1
! Check if the time has changed
  timestep=array1(1)-oldtime
  if (timestep.gt.0.d0) then
    stepno=stepno+1
    oldtime=array1(1)
    yold=ynew
!   Loop for all blades
    do i=1,nblades
!     Parameters for divprk
      param=0.d0
      param(4)=50000
      ido=1
      t=0.d0
!     Initial conditions for pitch angle and velocity
      y(1:2)=yold(1:2,i)
!     Actual and reference position and velocity of pitch angle
      theta_ref=array1(i+1)
!     Compute pitch angle and velocity at next step 
      tend=timestep
      call rkf45(ode,2,y,t,tend,relerr,abserr,iflag,work,iwork)
!!     Simple 2nd order filter
!      y=lowpass2orderfilt(timestep,stepno,filt(i),theta_ref)
!     Apply hard limits on angles
      if (y(1).lt.theta_min) then
        y(1)=theta_min
        y(2)=0.d0
      endif
      if (y(1).gt.theta_max) then
        y(1)=theta_max
        y(2)=0.d0
      endif
!     Save results
      ynew(1:2,i)=y(1:2)
!     Fill output array2
      oldarray2(i)=y(1)
      oldarray2(nblades+i)=y(2)
      oldarray2(2*nblades+i)=(y(2)-yold(2,i))/timestep
    enddo
  endif
! Insert output
  array2(1:3*nblades)=oldarray2(1:3*nblades)
  return
  end subroutine update_servo_with_limits
!***********************************************************************
  subroutine ode(t,y,yprime)
  use servo_with_limits_data
  implicit none
  real*8 t,y(2),yprime(2)
! ODEs
  yprime(1) = y(2)
  yprime(2) = -amax/vmax*y(2)&
              +amax*dtanh(omega0**2*(theta_ref-y(1))/amax-&
                          (2.d0*beta0*omega0-amax/vmax)*y(2)/amax)
  return
  end subroutine ode
!***********************************************************************
