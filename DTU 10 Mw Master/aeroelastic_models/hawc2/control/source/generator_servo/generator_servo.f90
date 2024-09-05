  subroutine init_generator_servo(array1,array2)
  use generator_servo_fcns
  implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'init_generator_servo'::init_generator_servo
  real*8 array1(1000),array2(1)
! Input array1 must contain
!
!    1: constant 1 ; Frequency of genertor 2nd order control model [Hz]   
!    2: constant 2 ; Damping ratio of genertor 2nd order control model [-]
!    3: constant 3 ; Maximum allowable LSS torque (pull-out torque) [Nm]
!    4: constant 4 ; Generator efficiency [-]
!    5: constant 5 ; Gearratio [-]
!    6: constant 6 ; Time for half value in softstart of torque [s]
!....7: constant 7 1000;     unit conversion factor
!
! Output array2 contains nothing
!
! Save parameters
  lowpass2ordergen.f0=array1(1)*2.d0*pi
  lowpass2ordergen.ksi=array1(2)
  generatorvar.max_lss_torque=array1(3)
  generatorvar.eta=array1(4)
  generatorvar.gearratio=array1(5)
  UnitConversionFactor=array1(7)
! Initiate the dynamic variables
  generatorvar.stepno=0
  generatorvar.time_old=0.d0
! Zero output
  array2=0.d0
  return
  end subroutine init_generator_servo
!***********************************************************************
  subroutine update_generator_servo(array1,array2)
  use generator_servo_fcns
!  use imsl
  implicit none
!DEC$ ATTRIBUTES DLLEXPORT, C, ALIAS:'update_generator_servo'::update_generator_servo
  real*8 array1(1000),array2(100)
! Input array1 must contain
!
!    1: general time                           ; Time [s]     
!    2: dll inpvec 1 1                         ; Electrical torque reference [Nm]
!    3: constraint bearing1 shaft_rot 1 only 2 ; Generator LSS speed [rad/s]   
!....4: mbdy momentvec shaft 1 1 shaft # only 3;

!
! Output array2 contains
!
!    1: Generator LSS torque [Nm]
!    2: Electrical generator power [W]
!    3: Gearbox reaction tower top LSS [Nm]
!    4: Generator reaction tower top HSS  [Nm]
!    5: Mechanical generator power [kW]
!    6: mbdy moment_ext towertop 2 3 shaft;
!
! Local vars
  real*8 time,omegagen,Qgref,mech_Qgref,mech_Qg,Qg,softstart_torque
  real*8 Qshaft
! New step?
  time=array1(1)
  if (time.gt.generatorvar.time_old) then
    generatorvar.deltat=time-generatorvar.time_old
    generatorvar.time_old=time
    generatorvar.stepno=generatorvar.stepno+1
  endif
! Save input
  Qgref=array1(2)
  Qshaft=array1(4)
  omegagen=array1(3)
! Reference mech. torque
  mech_Qgref=dmin1(Qgref/generatorvar.eta,generatorvar.max_lss_torque)
! Low-pass filter generator speed (LSS)
  mech_Qg=lowpass2orderfilt(generatorvar.deltat,generatorvar.stepno,lowpass2ordergen,mech_Qgref);
! Output
  array2(1)=-mech_Qg
  array2(2)=mech_Qg*omegagen*generatorvar.eta
  array2(3)=-mech_Qg+mech_Qg/generatorvar.gearratio
  array2(4)=-mech_Qg/generatorvar.gearratio
  array2(5)=mech_Qg*omegagen*1.d-3
  array2(6)=-Qshaft*UnitConversionFactor

  return
  end subroutine update_generator_servo
!***********************************************************************
