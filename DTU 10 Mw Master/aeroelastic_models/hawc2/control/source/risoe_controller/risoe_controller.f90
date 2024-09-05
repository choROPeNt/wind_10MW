! Version history:
! 01-02-2013: LARH Takes over from MHHA, status signal added to output array2 
subroutine init_regulation(array1,array2)
use risoe_controller_fcns
implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'init_regulation'::init_regulation
real*8 array1(1000),array2(1)
! Local vars
integer*4 i,ifejl
character text32*32
real*8 minimum_pitch_angle
logical findes
! Input array1 must contain
!
!       ; Overall parameters
!    1: constant   1   ; Rated power [kW]                         
!    2: constant   2   ; Minimum rotor speed [rad/s]
!    3: constant   3   ; Rated rotor speed [rad/s]
!    4: constant   4   ; Maximum allowable generator torque [Nm]
!    5: constant   5   ; Minimum pitch angle, theta_min [deg], 
!                      ; if |theta_min|>90, then a table of <wsp,theta_min> is read 
!                      ; from a file named 'wptable.n', where n=int(theta_min)
!    6: constant   6   ; Maximum pitch angle [deg]
!    7: constant   7   ; Maximum pitch velocity operation [deg/s]
!    8: constant   8   ; Frequency of generator speed filter [Hz]
!    9: constant   9   ; Damping ratio of speed filter [-]
!   10: constant  10   ; Frequency of free-free DT torsion mode [Hz], if zero no notch filter used
!       ; Partial load control parameters
!   11: constant  11   ; Optimal Cp tracking K factor [Nm/(rad/s)^2], 
!                      ; Qg=K*Omega^2, K=eta*0.5*rho*A*Cp_opt*R^3/lambda_opt^3                
!   12: constant  12   ; Proportional gain of torque controller [Nm/(rad/s)]
!   13: constant  13   ; Integral gain of torque controller [Nm/rad]
!   14: constant  14   ; Differential gain of torque controller [Nm/(rad/s^2)]
!       ; Full load control parameters
!   15: constant  15   ; Generator control switch [1=constant power, 2=constant torque]
!   16: constant  16   ; Proportional gain of pitch controller [rad/(rad/s)]
!   17: constant  17   ; Integral gain of pitch controller [rad/rad]
!   18: constant  18   ; Differential gain of pitch controller [rad/(rad/s^2)]
!   19: constant  19   ; Proportional power error gain [rad/W]
!   20: constant  20   ; Integral power error gain [rad/(Ws)]
!   21: constant  21   ; Coefficient of linear term in aerodynamic gain scheduling, KK1 [deg]
!   22: constant  22   ; Coefficient of quadratic term in aerodynamic gain scheduling, KK2 [deg^2] 
!                      ; (if zero, KK1 = pitch angle at double gain)
!   23: constant  23   ; Relative speed for double nonlinear gain [-]
!       ; Cut-in simulation parameters
!   24: constant  24   ; Cut-in time [s], if zero no cut-in simulated
!   25: constant  25   ; Time delay for soft start [1/1P]
!       ; Cut-out simulation parameters
!   26: constant  26   ; Cut-out time [s], if zero no cut-out simulated
!   27: constant  27   ; Time constant for 1st order filter lag of torque cut-out [s]
!   28: constant  28   ; Stop type [1=linear two pitch speed stop, 2=exponential pitch speed stop]
!   29: constant  29   ; Time delay for pitch stop 1 [s]
!   30: constant  30   ; Maximum pitch velocity during stop 1 [deg/s]
!   31: constant  31   ; Time delay for pitch stop 2 [s]
!   32: constant  32   ; Maximum pitch velocity during stop 2 [deg/s]
!       ; Expert parameters (keep default values unless otherwise given)
!   33  constant  33   ; Lower angle above lowest minimum pitch angle for switch [deg]
!   34: constant  34   ; Upper angle above lowest minimum pitch angle for switch [deg]
!   35: constant  35   ; Ratio between filtered and reference speed for fully open torque limits [%]
!   36: constant  36   ; Time constant of 1st order filter on wind speed used for minimum pitch [1/1P]
!   37: constant  37   ; Time constant of 1st order filter on pitch angle for gain scheduling [1/1P]
!  	38: constant  38   ; Proportional gain of DT damper [Nm/(rad/s)], requires frequency in input 10
!   39: constant  39   ; Percent maximum overspeed of generator speed before cut-out [%]
!   40: constant  40   ; Additional non-linear pitch control term: Err0
!   41: constant  41   ; Additional non-linear pitch control term: ErrDot0
!   42: constant  42   ; Additional non-linear pitch control term: PitNonLin1
!
! Output array2 contains nothing for init
!
! Overall parameters
Pe_rated                 =array1( 1)*1.d3
omega_ref_min            =array1( 2)
omega_ref_max            =array1( 3)
max_lss_torque           =array1( 4)
minimum_pitch_angle      =array1( 5)*degrad
pitch_stopang            =array1( 6)*degrad
PID_pit_var.velmax       =array1( 7)*degrad
omega2ordervar.f0        =array1( 8)
omega2ordervar.zeta      =array1( 9)
DT_mode_filt.f0          =array1(10)
! Partial load control parameters
Kopt                     =array1(11)
if (Kopt*omega_ref_max**2.ge.Pe_rated/omega_ref_max) Kopt=Pe_rated/omega_ref_max**3
PID_gen_var.Kpro         =array1(12)
PID_gen_var.Kint         =array1(13)
PID_gen_var.Kdif         =array1(14)
! Full load control parameters
const_power         =(int(array1(15)).eq.1)
PID_pit_var.kpro(1)      =array1(16)
PID_pit_var.kint(1)      =array1(17)
PID_pit_var.kdif(1)      =array1(18)
PID_pit_var.kpro(2)      =array1(19)
PID_pit_var.kint(2)      =array1(20)
PID_pit_var.kdif(2)      =0.d0
kk1                      =array1(21)*degrad
kk2                      =array1(22)*degrad*degrad
rel_limit                =array1(23)
! Cut-in simulation parameters
t_cutin                  =array1(24)
t_cutin_delay            =array1(25)*2.d0*pi/omega_ref_max
! Cut-out simulation parameters
t_cutout                 =array1(26)
torquefirstordervar.tau  =array1(27)
pitch_stoptype       =int(array1(28))
pitch_stopdelay          =array1(29)
pitch_stopvelmax         =array1(30)*degrad
pitch_stopdelay2         =array1(31)
pitch_stopvelmax2        =array1(32)*degrad
! Expert parameters (keep default values unless otherwise given)
switch1_pitang_lower_org =array1(33)*degrad
switch1_pitang_upper_org =array1(34)*degrad
rel_sp_open_Qg           =array1(35)*1.d-2
wspfirstordervar.tau     =array1(36)*2.d0*pi/omega_ref_max
pitchfirstordervar.tau   =array1(37)*2.d0*pi/omega_ref_max
! Drivetrain damper
DT_damp_gain             =array1(38)
DT_damper_filt.f0        =DT_mode_filt.f0
pwr_DT_mode_filt.f0      =DT_mode_filt.f0
! Overspeed
overspeed_percent        =array1(39)*0.01d0
! Additional non-linear pitch control term
Err0                     = array1(40)
ErrDot0                  = array1(41)
PitNonLin1               = array1(42)
! Default and derived parameters
PID_gen_var.velmax=0.d0 !No limit to generator torque change rate
Qg_rated=Pe_rated/omega_ref_max
switchfirstordervar.tau=2.d0*pi/omega_ref_max
cutinfirstordervar.tau=2.d0*pi/omega_ref_max
! Wind speed table
if (dabs(minimum_pitch_angle).lt.90.d0*degrad) then 
  Opdatavar.lines=2
  Opdatavar.wpdata(1,1)=0.d0
  Opdatavar.wpdata(2,1)=99.d0
  Opdatavar.wpdata(1,2)=minimum_pitch_angle
  Opdatavar.wpdata(2,2)=minimum_pitch_angle
else
  write(text32,'(i)') int(minimum_pitch_angle*raddeg)
  inquire(file='wpdata.'//trim(adjustl(text32)),exist=findes)      
  if (findes) then
    open(88,file='wpdata.'//trim(adjustl(text32)))
    read(88,*,iostat=ifejl) Opdatavar.lines
    if (ifejl.eq.0) then
      do i=1,Opdatavar.lines
        read(88,*,iostat=ifejl) Opdatavar.wpdata(i,1),Opdatavar.wpdata(i,2) 
        if (ifejl.ne.0) then
          write(6,*) ' *** ERROR *** Could not read lines in minimum '&
                   //'pitch table in file wpdata.'//trim(adjustl(text32))
          stop
        endif
        Opdatavar.wpdata(i,2)=Opdatavar.wpdata(i,2)*degrad
      enddo
    else
      write(6,*) ' *** ERROR *** Could not read number of lines '&
               //'in minimum pitch table in file wpdata.'//trim(adjustl(text32))
      stop
    endif
    close(88)
  else
    write(6,*) ' *** ERROR *** File ''wpdata.'//trim(adjustl(text32))&
             //''' does not exist in the working directory'
    stop
  endif
endif
! Initiate the dynamic variables
stepno=0
time_old=0.d0
! No output
array2=0.d0
return
end subroutine init_regulation
!**************************************************************************************************
subroutine update_regulation(array1,array2)
use risoe_controller_fcns
implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'update_regulation'::update_regulation
real*8 array1(1000),array2(100)
! Input array1 must contain
!
!    1: general time                           ; [s]     
!    2: constraint bearing1 shaft_rot 1 only 2 ; [rad/s] Generator LSS speed 
!    3: constraint bearing2 pitch1 1 only 1    ; [rad]         
!    4: constraint bearing2 pitch2 1 only 1    ; [rad]                               
!    5: constraint bearing2 pitch3 1 only 1    ; [rad]                               
!  6-8: wind free_wind 1 0.0 0.0 hub height    ; [m/s] global coords at hub height
!    9: added pitch rate from external system  ; [rad/s]
!
! Output array2 contains
!
!    1: Generator torque reference            [Nm]
!    2: Pitch angle reference of blade 1      [rad]    
!    3: Pitch angle reference of blade 2      [rad]    
!    4: Pitch angle reference of blade 3      [rad]    
!    5: Power reference                       [W]
!    6: Filtered wind speed                   [m/s]
!    7: Filtered rotor speed                  [rad/s]
!    8: Filtered rotor speed error for torque [rad/s]
!    9: Bandpass filtered rotor speed         [rad/s]
!   10: Proportional term of torque contr.    [Nm]
!   11: Integral term of torque controller    [Nm]
!   12: Minimum limit of torque               [Nm]
!   13: Maximum limit of torque               [Nm]
!   14: Torque limit switch based on pitch    [-]
!   15: Filtered rotor speed error for pitch  [rad/s]
!   16: Power error for pitch                 [W]
!   17: Proportional term of pitch controller [rad]
!   18: Integral term of pitch controller     [rad]
!   19: Minimum limit of pitch                [rad]
!   20: Maximum limit of pitch                [rad]
!   21: Torque reference from DT damper       [Nm]
!   22: Status signal: 0: ok, 1 shutdown due to overspeed       [-]
!   23: Total added pitch rate                [rad/s]
!
! Local variables
real*8 time,omega,omegafilt,domega_dt_filt,wsp,WSPfilt
real*8 omega_err_filt_pitch,omega_err_filt_speed,omega_dtfilt
real*8 added_term
real*8 ommin1,ommin2,ommax1,ommax2
real*8 pitang(3),meanpitang,meanpitangfilt,theta_min,e_pitch(2)
real*8 kgain_pitch(3,2),kgain_torque(3),aero_gain,x,dummy,y(2)
real*8 Qg_min_partial,Qg_max_partial,Qg_min_full,Qg_max_full
real*8 Qgen_ref,theta_col_ref,thetaref(3),Pe_ref,Qdamp_ref
real*8 CtrlStatus
!**************************************************************************************************
! Increment time step (may actually not be necessary in type2 DLLs)
!**************************************************************************************************
time=array1(1)
if (time.gt.time_old) then
  deltat=time-time_old
  time_old=time
  stepno=stepno+1
endif
!**************************************************************************************************
! Inputs and their filtering
!**************************************************************************************************

CtrlStatus = 0.d0

omega=array1(2)
! Mean pitch angle
pitang(1)=array1(3)
pitang(2)=array1(4)
pitang(3)=array1(5)
meanpitang=(pitang(1)+pitang(2)+pitang(3))/3.d0
! Wind speed as horizontal vector sum
wsp=dsqrt(array1(6)**2+array1(7)**2)
! Pitch rate to be added to PID controller from external control algorithm
added_pitch_rate = array1(9)

! Low-pass filtering of the rotor speed
y=lowpass2orderfilt(deltat,stepno,omega2ordervar,omega)
omegafilt=y(1)
domega_dt_filt=y(2)
! Check for overspeed
if (omegafilt.gt.(1.d0+overspeed_percent)*omega_ref_max) then
  t_cutout=time+deltat
  CtrlStatus = 1.d0
endif
! Mean pitch angle
! Low-pass filtering of the mean pitch angle for gain scheduling
meanpitangfilt=min(lowpass1orderfilt(deltat,stepno,pitchfirstordervar,meanpitang),30.d0*degrad)
! Low-pass filtering of the nacelle wind speed 
WSPfilt=lowpass1orderfilt(deltat,stepno,wspfirstordervar,wsp)
! Minimum pitch angle may vary with filtered wind speed
theta_min=GetOptiPitch(WSPfilt)
switch1_pitang_lower=switch1_pitang_lower_org+theta_min
switch1_pitang_upper=switch1_pitang_upper_org+theta_min
!**************************************************************************************************
! Speed ref. changes max. <-> min. for torque controller and remains at rated for pitch controller
!**************************************************************************************************
if (omegafilt.gt.0.5d0*(omega_ref_max+omega_ref_min)) then
  omega_err_filt_speed=omegafilt-omega_ref_max
else
  omega_err_filt_speed=omegafilt-omega_ref_min
endif
!**************************************************************************************************
! PID regulation of generator torque 
!**************************************************************************************************
! Limits for full load
if (const_power) then 
  Qg_min_full=dmin1(Pe_rated/dmax1(omega,1.d-15),max_lss_torque)
  Qg_max_full=Qg_min_full
else 
  Qg_min_full=Qg_rated
  Qg_max_full=Qg_rated
endif
! Limits for partial load that opens in both ends
ommin1=omega_ref_min
ommin2=omega_ref_min/rel_sp_open_Qg
ommax1=(2.d0*rel_sp_open_Qg-1.d0)*omega_ref_max
ommax2=rel_sp_open_Qg*omega_ref_max
x=switch_spline(omegafilt,ommin1,ommin2)
Qg_min_partial=dmin1(Kopt*omegafilt**2*x,Kopt*ommax1**2)     
x=switch_spline(omegafilt,ommax1,ommax2)
Qg_max_partial=dmax1(Kopt*omegafilt**2*(1.d0-x)+Qg_max_full*x,Kopt*ommin2**2)
! Switch based on pitch
switch1=switch_spline(meanpitang,switch1_pitang_lower,switch1_pitang_upper)
switch1=lowpass1orderfilt(deltat,stepno,switchfirstordervar,switch1)
! Interpolation between partial and full load torque limits based on switch 1
PID_gen_var.outmin=(1.d0-switch1)*Qg_min_partial+switch1*Qg_min_full
PID_gen_var.outmax=(1.d0-switch1)*Qg_max_partial+switch1*Qg_max_full
if (PID_gen_var.outmin.gt.PID_gen_var.outmax) PID_gen_var.outmin=PID_gen_var.outmax
! Compute PID feedback to generator torque
kgain_torque=1.d0
Qgen_ref=PID(stepno,deltat,kgain_torque,PID_gen_var,omega_err_filt_speed)
!-------------------------------------------------------------------------------------------------  
! Control of cut-in regarding generator torque
!-------------------------------------------------------------------------------------------------
if (t_cutin.gt.0.d0) then
  if (generator_cutin) then
    x=switch_spline(time,t_generator_cutin,t_generator_cutin+t_cutin_delay)
    Qgen_ref=Qgen_ref*x
  else
    Qgen_ref=0.d0
  endif
endif
!-------------------------------------------------------------------------------------------------
! Control of cut-out regarding generator torque
!-------------------------------------------------------------------------------------------------
if ((t_cutout.gt.0.d0).and.(time.gt.t_cutout)) then
  Qgen_ref=lowpass1orderfilt(deltat,stepno,torquefirstordervar,0.d0)
else
  dummy=lowpass1orderfilt(deltat,stepno,torquefirstordervar,Qgen_ref)
endif
!-------------------------------------------------------------------------------------------------
! Reference electrical power
!-------------------------------------------------------------------------------------------------
Pe_ref=Qgen_ref*omega
!-------------------------------------------------------------------------------------------------
! Active DT damping based on notch filtered of rotor speed
!-------------------------------------------------------------------------------------------------
if ((DT_damp_gain.gt.0.d0).and.(DT_damper_filt.f0.gt.0.d0)) then
  omega_dtfilt=bandpassfilt(deltat,stepno,DT_damper_filt,omega)
  if (t_cutin.gt.0.d0) then
    if (generator_cutin) then
      x=switch_spline(time,t_generator_cutin+t_cutin_delay,t_generator_cutin+2.d0*t_cutin_delay)
      Qdamp_ref=DT_damp_gain*omega_dtfilt*x
      Qgen_ref=dmin1(dmax1(Qgen_ref+Qdamp_ref,0.d0),max_lss_torque)
    endif
  else
    Qdamp_ref=DT_damp_gain*omega_dtfilt
    Qgen_ref=dmin1(dmax1(Qgen_ref+Qdamp_ref,0.d0),max_lss_torque)
  endif
endif
!**************************************************************************************************
! PID regulation of collective pitch angle  
!**************************************************************************************************
! Reference speed is equal rated speed
omega_err_filt_pitch=omegafilt-omega_ref_max
! Additional non-linear pitch control term
if ((PitNonLin1.gt.0.d0).and.(Err0.gt.0.d0).and.(ErrDot0.gt.0.d0)) then
  added_term = omega_err_filt_pitch/Err0 + domega_dt_filt/ErrDot0
  if (added_term.gt.1.0d0) then
    added_pitch_rate = PitNonLin1*added_term + added_pitch_rate
  endif
endif
! Limits
PID_pit_var.outmin=theta_min
PID_pit_var.outmax=pitch_stopang
! Aerodynamic gain scheduling
if (kk2.gt.0.d0) then
  aero_gain=1.d0+meanpitangfilt/kk1+meanpitangfilt**2/kk2
else
  aero_gain=1.d0+meanpitangfilt/kk1
endif
!WRITE(*,*)  'aero_gain=', aero_gain, 'meanpitangfilt=', meanpitangfilt    
! Nonlinear gain to avoid large rotor speed excursion
kgain_pitch=(omega_err_filt_pitch**2/(omega_ref_max*(rel_limit-1.d0))**2+1.d0)/aero_gain
!-------------------------------------------------------------------------------------------------
! Control of cut-in regarding pitch 
!-------------------------------------------------------------------------------------------------
if (t_cutin.gt.0.d0) then
  if (time.lt.t_cutin) then
    PID_pit_var.outmin=pitch_stopang
    PID_pit_var.outmax=pitch_stopang
    kgain_pitch=0.d0
    dummy=lowpass1orderfilt(deltat,stepno,cutinfirstordervar,omega-omega_ref_min)
  else
    if (.not.generator_cutin) then 
      kgain_pitch(1:3,1)=0.25d0*kgain_pitch(1:3,1)
      kgain_pitch(1:3,2)=0.d0
      omega_err_filt_pitch=omegafilt-omega_ref_min
      x=lowpass1orderfilt(deltat,stepno,cutinfirstordervar,omega-omega_ref_min)
      if (dabs(x).lt.omega_ref_min*1.d-2) then
        generator_cutin=.true.
        t_generator_cutin=time
      endif
    else
      x=switch_spline(time,t_generator_cutin,t_generator_cutin+t_cutin_delay)
      omega_err_filt_pitch=omegafilt-(omega_ref_min*(1.d0-x)+omega_ref_max*x)
      kgain_pitch(1:3,1)=0.25d0*kgain_pitch(1:3,1)+kgain_pitch(1:3,1)*0.75d0*x
      kgain_pitch(1:3,2)=kgain_pitch(1:3,2)*x
    endif
  endif
endif
!WRITE(*,*)  'time=', time, 'aero_gain=', aero_gain, 'kgain_pitch=', kgain_pitch    
!-------------------------------------------------------------------------------------------------
! Control of cut-out regarding pitch 
!-------------------------------------------------------------------------------------------------
if ((t_cutout.gt.0.d0).and.(time.gt.t_cutout+pitch_stopdelay)) then
  select case(pitch_stoptype)
    case(0,1) ! Normal 2-step stop situation
      PID_pit_var.outmax=pitch_stopang
      PID_pit_var.outmin=pitch_stopang
      if (time.gt.t_cutout+pitch_stopdelay+pitch_stopdelay2) then 
        PID_pit_var.velmax=pitch_stopvelmax2
      else
        PID_pit_var.velmax=pitch_stopvelmax
      endif
    case(2) ! Exponential decay approach
      PID_pit_var.outmax=pitch_stopang
      PID_pit_var.outmin=pitch_stopang
      if ((time-(t_cutout+pitch_stopdelay))/pitch_stopdelay2.lt.10.d0) then 
        PID_pit_var.velmax=pitch_stopang/pitch_stopdelay2&
                          *dexp(-(time-(t_cutout+pitch_stopdelay))/pitch_stopdelay2)
      else 
        PID_pit_var.velmax=0.d0
      endif
      if (PID_pit_var.velmax.gt.pitch_stopvelmax) PID_pit_var.velmax=pitch_stopvelmax
      if (PID_pit_var.velmax.lt.pitch_stopvelmax2) PID_pit_var.velmax=pitch_stopvelmax2
    case default    
      write(6,'(a,i2,a)') ' *** ERROR *** Stop type ',pitch_stoptype,' not known'
      stop
  end select
endif
!-------------------------------------------------------------------------------------------------
! Compute PID feedback to generator torque
!-------------------------------------------------------------------------------------------------
if (DT_mode_filt.f0.gt.0.d0) then
  e_pitch(1)=notch2orderfilt(deltat,stepno,DT_mode_filt,omega_err_filt_pitch)
  e_pitch(2)=notch2orderfilt(deltat,stepno,pwr_DT_mode_filt,Pe_ref-Pe_rated)
else
  e_pitch(1)=omega_err_filt_pitch
  e_pitch(2)=Pe_ref-Pe_rated
endif
theta_col_ref=PID2(stepno,deltat,kgain_pitch,PID_pit_var,e_pitch,added_pitch_rate)
thetaref=theta_col_ref
!WRITE(*,*)  'time=', time, 'e_pitch=', e_pitch, 'omega_err_filt_pitch=', omega_err_filt_pitch    
!**************************************************************************************************
! Output
!**************************************************************************************************
array2( 1)=Qgen_ref             !    1: Generator torque reference            [Nm]  
array2( 2)=thetaref(1)          !    2: Pitch angle reference of blade 1      [rad]    
array2( 3)=thetaref(2)          !    3: Pitch angle reference of blade 2      [rad]    
array2( 4)=thetaref(3)          !    4: Pitch angle reference of blade 3      [rad]   
array2( 5)=Pe_ref               !    5: Power reference                       [W] 
array2( 6)=WSPfilt              !    6: Filtered wind speed                   [m/s] 
array2( 7)=omegafilt            !    7: Filtered rotor speed                  [rad/s] 
array2( 8)=omega_err_filt_speed !    8: Filtered rotor speed error for torque [rad/s]   
array2( 9)=omega_dtfilt         !    9: Bandpass filtered rotor speed         [rad/s] 
array2(10)=PID_gen_var.outpro   !   10: Proportional term of torque contr.    [Nm]  
array2(11)=PID_gen_var.outset   !   11: Integral term of torque controller    [Nm]  
array2(12)=PID_gen_var.outmin   !   12: Minimum limit of torque               [Nm]  
array2(13)=PID_gen_var.outmax   !   13: Maximum limit of torque               [Nm]  
array2(14)=switch1              !   14: Torque limit switch based on pitch    [-]  
array2(15)=omega_err_filt_pitch !   15: Filtered rotor speed error for pitch  [rad/s]  
array2(16)=e_pitch(2)           !   16: Power error for pitch                 [W]
array2(17)=PID_pit_var.outpro   !   17: Proportional term of pitch controller [rad]
array2(18)=PID_pit_var.outset   !   18: Integral term of pitch controller     [rad]
array2(19)=PID_pit_var.outmin   !   19: Minimum limit of pitch                [rad]
array2(20)=PID_pit_var.outmax   !   20: Maximum limit of pitch                [rad]
array2(21)=Qdamp_ref            !   21: Torque reference from DT damper       [Nm]
array2(22)=CtrlStatus           !   22: Controller error status:              [-]
                                !       0 - no error
                                !       1 - rotor overspeed shutdown
array2(23)=added_pitch_rate     !   23: Total added pitch rate                [rad/s]
return
end subroutine update_regulation
!**************************************************************************************************
