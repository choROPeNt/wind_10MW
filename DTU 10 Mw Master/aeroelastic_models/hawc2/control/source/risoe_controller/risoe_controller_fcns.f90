module risoe_controller_fcns
! Constants
real*8 pi,degrad,raddeg
parameter(pi=3.14159265358979,degrad=0.0174532925,raddeg=57.2957795131)
integer*4 maxwplines
parameter(maxwplines=100)
! Types
type Tfirstordervar
  real*8 tau,x1,x1_old,y1,y1_old
  integer*4 stepno1
end type Tfirstordervar
type Tlowpass2order
  real*8 zeta,f0,x1,x2,x1_old,x2_old,y1,y2,y1_old,y2_old
  integer*4 stepno1
end type Tlowpass2order
type Tnotch2order
  real*8::zeta1=0.1
  real*8::zeta2=0.001
  real*8 f0,x1,x2,x1_old,x2_old,y1,y2,y1_old,y2_old
  integer*4 stepno1
end type Tnotch2order
type Tbandpassfilt
  real*8::zeta=0.02
  real*8::tau=0.0
  real*8 f0,x1,x2,x1_old,x2_old,y1,y2,y1_old,y2_old
  integer*4 stepno1
end type Tbandpassfilt
type Tpidvar
  real*8 Kpro,Kdif,Kint,outmin,outmax,velmax,error1,outset1,outres1
  integer*4 stepno1
  real*8 outset,outpro,outdif,error1_old,outset1_old,outres1_old,outres
end type Tpidvar
type Tpid2var
  real*8 Kpro(2),Kdif(2),Kint(2),outmin,outmax,velmax,error1(2),outset1,outres1
  integer*4 stepno1
  real*8 outset,outpro,outdif,error1_old(2),outset1_old,outres1_old,outres
end type Tpid2var
type Twpdata
  real*8 wpdata(maxwplines,2)
  integer*4 lines
end type Twpdata
! Variables
integer*4 stepno
logical const_power
real*8 deltat,time_old,overspeed_percent
real*8 added_pitch_rate,Err0,ErrDot0,PitNonLin1
real*8 omega_ref_max,omega_ref_min,Pe_rated,Qg_rated,pitch_stopang,max_lss_torque
real*8 Kopt,rel_sp_open_Qg
real*8 kk1,kk2,rel_limit
real*8 switch1_pitang_lower,switch1_pitang_upper,switch1
real*8 switch1_pitang_lower_org,switch1_pitang_upper_org
real*8 DT_damp_gain
logical::generator_cutin=.false.
real*8 t_cutin,t_generator_cutin,t_cutin_delay
integer*4 pitch_stoptype
real*8 t_cutout,pitch_stopdelay,pitch_stopdelay2,pitch_stopvelmax,pitch_stopvelmax2
type(Tlowpass2order) omega2ordervar
type(Tnotch2order) DT_mode_filt
type(Tnotch2order) pwr_DT_mode_filt
type(Tbandpassfilt) DT_damper_filt
type(Tpid2var) PID_pit_var
type(Tpidvar) PID_gen_var
type(Twpdata) OPdatavar
type(Tfirstordervar) wspfirstordervar
type(Tfirstordervar) pitchfirstordervar
type(Tfirstordervar) torquefirstordervar
type(Tfirstordervar) switchfirstordervar
type(Tfirstordervar) cutinfirstordervar
!**************************************************************************************************
contains
!**************************************************************************************************
function switch_spline(x,x0,x1)
implicit none
! A function that goes from 0 at x0 to 1 at x1
real*8 switch_spline,x,x0,x1
if (x0.ge.x1) then
  if (x.lt.x0) then
    switch_spline=0.d0
  else
    switch_spline=1.d0
  endif
elseif (x0.gt.x1) then
  switch_spline=0.d0
else
  if (x.lt.x0) then
    switch_spline=0.d0
  elseif (x.gt.x1) then
    switch_spline=1.d0 
  else
    switch_spline=2.d0/(-x1+x0)**3*x**3+(-3.d0*x0-3.d0*x1)/(-x1+x0)**3*x**2&
                 +6.d0*x1*x0/(-x1+x0)**3*x+(x0-3.d0*x1)*x0**2/(-x1+x0)**3
  endif
endif
return
end function switch_spline
!**************************************************************************************************
function interpolate(x,x0,x1,f0,f1)
implicit none
real*8 interpolate,x,x0,x1,f0,f1
if (x0.eq.x1) then 
  interpolate=f0
else 
  interpolate=(x-x1)/(x0-x1)*f0+(x-x0)/(x1-x0)*f1
endif
return
end function interpolate
!**************************************************************************************************
function GetOptiPitch(wsp)
implicit none
real*8 GetOptiPitch,wsp
! local vars
real*8 x,x0,x1,f0,f1,pitch
integer*4 i
i=1
do while((OPdatavar.wpdata(i,1).le.wsp).and.(i.le.OPdatavar.lines))
  i=i+1
enddo
if (i.eq.1) then 
  GetOptiPitch=OPdatavar.wpdata(1,2)
elseif (i.gt.OPdatavar.lines) then
  GetOptiPitch=OPdatavar.wpdata(OPdatavar.lines,2)
else
  x=wsp
  x0=OPdatavar.wpdata(i-1,1)
  x1=OPdatavar.wpdata(i,1)
  f0=OPdatavar.wpdata(i-1,2)
  f1=OPdatavar.wpdata(i,2)
  Pitch=interpolate(x,x0,x1,f0,f1)
  GetOptiPitch=Pitch
endif
return
end function GetOptiPitch
!**************************************************************************************************
function lowpass1orderfilt(dt,stepno,filt,x)
implicit none
integer*4 stepno
real*8 lowpass1orderfilt,dt,x,y,a1,b1,b0,tau
type(Tfirstordervar) filt
! Step 
if ((stepno.eq.1).and.(stepno.gt.filt.stepno1)) then
  filt.x1_old=x
  filt.y1_old=x
  y=x
else
  if (stepno.gt.filt.stepno1) then
    filt.x1_old=filt.x1
    filt.y1_old=filt.y1
  endif
  tau=filt.tau
  a1 = (2 * tau - dt) / (2 * tau + dt)
  b0 = dt / (2 * tau + dt)
  b1 = b0
  y=a1*filt.y1_old+b0*x+b1*filt.x1_old
endif
! Save previous values
filt.x1=x
filt.y1=y
filt.stepno1=stepno
! Output
lowpass1orderfilt=y
return
end function lowpass1orderfilt
!**************************************************************************************************
function lowpass2orderfilt(dt,stepno,filt,x)
implicit none
real*8 lowpass2orderfilt(2),dt,x
integer*4 stepno
type(Tlowpass2order) filt
! local vars
real*8 y,f0,zeta,a1,a2,b0,b1,b2,denom
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
  zeta=filt.zeta
  denom=3.d0+6.d0*zeta*pi*f0*dt+4.d0*pi**2*f0**2*dt**2
  a1=(6.d0-4.d0*pi**2*f0**2*dt**2)/denom
  a2=(-3.d0+6.d0*zeta*pi*f0*dt-4.d0*pi**2*f0**2*dt**2)/denom
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
lowpass2orderfilt(1)=y
lowpass2orderfilt(2)=0.5d0*(y-filt.y2_old)/dt
return
end function lowpass2orderfilt
!**************************************************************************************************
function notch2orderfilt(dt,stepno,filt,x)
implicit none
real*8 notch2orderfilt,dt,x
integer*4 stepno
type(Tnotch2order) filt
! local vars
real*8 y,f0,zeta1,zeta2,a1,a2,b0,b1,b2,denom
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
  zeta1=filt.zeta1
  zeta2=filt.zeta2
  denom=3.d0+6.d0*zeta1*pi*f0*dt+4.d0*pi**2*f0**2*dt**2
  a1=(6.d0-4.d0*pi**2*f0**2*dt**2)/denom
  a2=(-3.d0+6.d0*zeta1*pi*f0*dt-4.d0*pi**2*f0**2*dt**2)/denom
  b0=(3.d0+6.d0*zeta2*pi*f0*dt+4.d0*pi**2*f0**2*dt**2)/denom
  b1=(-6.d0+4.d0*pi**2*f0**2*dt**2)/denom
  b2=(3.d0-6.d0*zeta2*pi*f0*dt+4.d0*pi**2*f0**2*dt**2)/denom
  y=a1*filt.y1_old+a2*filt.y2_old+b0*x+b1*filt.x1_old+b2*filt.x2_old
endif
! Save previous values
filt.x2=filt.x1
filt.x1=x
filt.y2=filt.y1
filt.y1=y
filt.stepno1=stepno
! Output
notch2orderfilt=y
return
end function notch2orderfilt
!**************************************************************************************************
function bandpassfilt(dt,stepno,filt,x)
implicit none
real*8 bandpassfilt,dt,x
integer*4 stepno
type(Tbandpassfilt) filt
! local vars
real*8 y,f0,zeta,tau,a1,a2,b0,b1,b2,denom
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
  zeta=filt.zeta
  tau=filt.tau
  denom=3.d0+6.d0*zeta*pi*f0*dt+4.d0*pi**2*f0**2*dt**2
  a1=-(-6.d0+4.d0*pi**2*f0**2*dt**2)/denom
  a2=-(3.d0-6.d0*zeta*pi*f0*dt+4.d0*pi**2*f0**2*dt**2)/denom
  b0=-(-6.d0*zeta*pi*f0*dt-12.d0*zeta*pi*f0*tau)/denom
  b1=-24.d0*zeta*pi*f0*tau/denom
  b2=-(6.d0*zeta*pi*f0*dt-12.d0*zeta*pi*f0*tau)/denom
  y=a1*filt.y1_old+a2*filt.y2_old+b0*x+b1*filt.x1_old+b2*filt.x2_old
endif
! Save previous values
filt.x2=filt.x1
filt.x1=x
filt.y2=filt.y1
filt.y1=y
filt.stepno1=stepno
! Output
bandpassfilt=y
return
end function bandpassfilt
!**************************************************************************************************
function PID(stepno,dt,kgain,PIDvar,error)
implicit none
integer*4 stepno              
real*8 PID,dt,kgain(3),error
type(Tpidvar) PIDvar
! Local vars
real*8 eps
parameter(eps=1.d-6)
! Initiate
if (stepno.eq.1) then
  PIDvar.outset1=0
  PIDvar.outres1=0
  PIDvar.error1=0
  PIDvar.error1_old=0.0
  PIDvar.outset1_old=0.0
  PIDvar.outres1_old=0.0
endif
! Save previous values
if (stepno.gt.PIDvar.stepno1) then
  PIDvar.outset1_old=PIDvar.outset1
  PIDvar.outres1_old=PIDvar.outres1
  PIDvar.error1_old=PIDvar.error1
endif
! Update the integral term
PIDvar.outset=PIDvar.outset1_old+0.5d0*(error+PIDvar.error1)*Kgain(2)*PIDvar.Kint*dt
! Update proportional term
PIDvar.outpro=Kgain(1)*PIDvar.Kpro*0.5d0*(error+PIDvar.error1)
! Update differential term
PIDvar.outdif=Kgain(3)*PIDvar.Kdif*(error-PIDvar.error1_old)/dt
! Sum to up
PIDvar.outres=PIDvar.outset+PIDvar.outpro+PIDvar.outdif
! Satisfy hard limits
if (PIDvar.outres.lt.PIDvar.outmin) then 
  PIDvar.outres=PIDvar.outmin
elseif (PIDvar.outres.gt.PIDvar.outmax) then 
  PIDvar.outres=PIDvar.outmax
endif
! Satisfy max velocity
if (PIDvar.velmax.gt.eps) then
    if ((abs(PIDvar.outres-PIDvar.outres1_old)/dt).gt.PIDvar.velmax) &
      PIDvar.outres=PIDvar.outres1_old+dsign(PIDvar.velmax*dt,PIDvar.outres-PIDvar.outres1_old)
endif
! Anti-windup on integral term and save results
PIDvar.outset1=PIDvar.outres-PIDvar.outpro-PIDvar.outdif
PIDvar.outres1=PIDvar.outres
PIDvar.error1=error
PIDvar.stepno1=stepno
! Set output
if (stepno.eq.0) then 
  PID=0
else 
  PID=PIDvar.outres
endif
return
end function PID
!**************************************************************************************************
function PID2(stepno,dt,kgain,PIDvar,error,added_term)
implicit none
integer*4 stepno              
real*8 PID2,dt,kgain(3,2),error(2),added_term
type(Tpid2var) PIDvar
! Local vars
real*8 eps
parameter(eps=1.d-6)
! Initiate
if (stepno.eq.1) then
  PIDvar.outset1=0
  PIDvar.outres1=0
  PIDvar.error1=0
  PIDvar.error1_old=0.0
  PIDvar.outset1_old=0.0
  PIDvar.outres1_old=0.0
endif
! Save previous values
if (stepno.gt.PIDvar.stepno1) then
  PIDvar.outset1_old=PIDvar.outset1
  PIDvar.outres1_old=PIDvar.outres1
  PIDvar.error1_old=PIDvar.error1
endif
! Update the integral term
PIDvar.outset=PIDvar.outset1_old+0.5d0*dt*(Kgain(2,1)*PIDvar.Kint(1)*(error(1)+PIDvar.error1(1))&
                                          +Kgain(2,2)*PIDvar.Kint(2)*(error(2)+PIDvar.error1(2)))
! Update proportional term
PIDvar.outpro=0.5d0*(Kgain(1,1)*PIDvar.Kpro(1)*(error(1)+PIDvar.error1(1))&
                    +Kgain(1,2)*PIDvar.Kpro(2)*(error(2)+PIDvar.error1(2)))
! Update differential term
PIDvar.outdif=(Kgain(3,1)*PIDvar.Kdif(1)*(error(1)-PIDvar.error1_old(1)))/dt + added_term*dt
! Sum up
PIDvar.outres=PIDvar.outset+PIDvar.outpro+PIDvar.outdif
! Satisfy hard limits
if (PIDvar.outres.lt.PIDvar.outmin) then 
  PIDvar.outres=PIDvar.outmin
elseif (PIDvar.outres.gt.PIDvar.outmax) then 
  PIDvar.outres=PIDvar.outmax
endif

if (isnan(PID_pit_var.outres)) then

WRITE(*,*)  'PID_pit_var.outres=', PID_pit_var.outres
WRITE(*,*)  'PID_pit_var.outpro=', PID_pit_var.outpro
WRITE(*,*)  'PID_pit_var.outdif=', PID_pit_var.outdif

WRITE(*,*)  'dt=', dt

WRITE(*,*)  'PIDvar.error1_old(1)=', PIDvar.error1_old(1)

WRITE(*,*)  'error(1)=', error(1)


WRITE(*,*)  'PIDvar.Kdif(1)=', PIDvar.Kdif(1)

WRITE(*,*)  'Padded_term=', added_term


WRITE(*,*)  'PID_pit_var.outset=', PID_pit_var.outset
pause
endif

! Satisfy max velocity
if (PIDvar.velmax.gt.eps) then
    if ((abs(PIDvar.outres-PIDvar.outres1_old)/dt).gt.PIDvar.velmax) &
      PIDvar.outres=PIDvar.outres1_old+dsign(PIDvar.velmax*dt,PIDvar.outres-PIDvar.outres1_old)
endif

! Anti-windup on integral term and save results
PIDvar.outset1=PIDvar.outres-PIDvar.outpro-PIDvar.outdif
PIDvar.outres1=PIDvar.outres
PIDvar.error1=error
PIDvar.stepno1=stepno
! Set output
if (stepno.eq.0) then 
  PID2=0
else 
  PID2=PIDvar.outres
endif
return
end function PID2
!**************************************************************************************************
end module risoe_controller_fcns