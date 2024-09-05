module generator_servo_fcns
real*8 pi,degrad,raddeg
real*8 UnitConversionFactor
parameter(pi=3.14159265358979,degrad=0.0174532925,raddeg=57.2957795131)
! Types
type Tlowpass2order
  real*8 ksi,f0,x1,x2,x1_old,x2_old,y1,y2,y1_old,y2_old
  integer*4 stepno1
end type Tlowpass2order
type Tgenerator
  real*8 eta,gearratio,mgenwa1,mgenera1,max_lss_torque
  integer*4 stepno
  real*8 deltat,outputvektor_old(15),time_old
end type Tgenerator
! Variables
type(Tgenerator) generatorvar
type(Tlowpass2order) lowpass2ordergen
!*****************************************************************************************
contains
!*****************************************************************************************
function lowpass2orderfilt(dt,stepno,filt,x)
implicit none
real*8 lowpass2orderfilt,dt,x
integer*4 stepno
type(Tlowpass2order) filt
! local vars
real*8 y,f0,ksi,a1,a2,b0,b1,b2,denom
! Step
if ((stepno.eq.1).and.(stepno.gt.filt.stepno1)) then
  filt.x1=x
  filt.x2=x
  filt.x1_old=filt.x1
  filt.x2_old=filt.x2
  filt.y1=x
  filt.y2=x
  filt.y1_old=filt.y1
  filt.y2_old=filt.y2
  y=x
else
  if (stepno.gt.filt.stepno1) then
    filt.x1_old=filt.x1
    filt.x2_old=filt.x2
    filt.y1_old=filt.y1
    filt.y2_old=filt.y2
  endif
  f0=filt.f0
  ksi=filt.ksi
  denom=3.d0+6.d0*ksi*pi*f0*dt+4.d0*pi**2*f0**2*dt**2
  a1=(6.d0-4.d0*pi**2*f0**2*dt**2)/denom
  a2=(-3.d0+6.d0*ksi*pi*f0*dt-4.d0*pi**2*f0**2*dt**2)/denom
  b0=4.d0*pi**2*f0**2*dt**2/denom
  b1=b0
  b2=b0
  y=a1*filt.y1_old+a2*filt.y2_old+b0*x+b1*filt.x1_old+b2*filt.x2_old
endif
! Save previous values
filt.x2=filt.x1
filt.x1=x
filt.y2=filt.y1
filt.y1=y
filt.stepno1=stepno
! Output
lowpass2orderfilt=y
return
end function lowpass2orderfilt
!*****************************************************************************************
end module generator_servo_fcns