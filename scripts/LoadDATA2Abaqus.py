from abaqus import *
from abaqusConstants import *
from caeModules import *

import numpy as np
import matplotlib.pyplot as plt
import os as os 

# Initial variables

flow = 'turb'               # 'turb' or 'tran'
wsp = 9                     # Windspeed [5,6,8,9,10,11,12,16,20,25]
cycles = 2

precone = 0
#tilt = 5

Aeroload = 1                # Custom 1 , Use given files 0 


# .dat files
file_path1 = '..\\wind_10MW\\DTU 10 Mw Master\\CFD\\3D_DTU_10MW_RWT\\baseline\\\EllipSys3D\\' +flow +'\\power_curve.dat'
file_path2 = '..\\wind_10MW\\DTU 10 Mw Master\\CFD\\3D_DTU_10MW_RWT\\baseline\\\EllipSys3D\\' + flow + '\\wsp_' + str(wsp) + '_spanwise_loads.dat'

data1 = np.genfromtxt(file_path1, comments='#', delimiter=None) # windspeed,power,thrust,cp,ct,pitch,omega [10x7]
data2 = np.genfromtxt(file_path2, comments='#', delimiter=None) # Radius, Fx, Fz, localCp, localCt [101x5] 

# Varibles
windspeed   = data1[:,0]    # [5,6,8,9,10,11,12,16,20,25]
Omega       = data1[:,6]    # Rotational Velocity rad/s
Pitch       = (data1[:,5])    # Degrees

# Finding the index 
def find_row_index(data, target_windspeed):
    for index, row in enumerate(data):
        windspeed = row[0]
        if windspeed == target_windspeed:
            return index  # Return the index of the matching wind speed
    return None  # Return None if the wind speed is not found

row_index = find_row_index(data1, wsp)

# Display the data
print()
print("########### Input Data ###########")
print('Flow type = ' + flow)
print('Windspeed (m/s) = ' + str(wsp))
print()
print('Rotational Speed (Rad/s) = ' + str(Omega[row_index]))
print('Blade angle = ' + str(Pitch[row_index]))
print('Precone angle = ' + str(precone))
print()
if Aeroload == 0: 
    print('Using DTU10MW Aeroloads')
else:
    print('Using Custom Loading')





############# Assembly #############

# Blade Pitch
# Find the current angle of the blade 
a = mdb.models['refblade_master'].rootAssembly

# Get the position information of the instance
position_info = a.instances['PART-1-1'].getRotation()
Axis   = position_info[0]
Vector = position_info[1]
Angle = position_info[2]

# print('Blade Axis = ' + str(Axis))
# print('Blade Vector = ' + str(Vector))
# print('Blade Angle = ' + str(Angle))

# a.translate(instanceList=('PART-1-1', ), vector=Axis)

a.rotate(instanceList=('PART-1-1', ), axisPoint=(0.0, 0.0, 0.0), 
    axisDirection=Vector, angle=-Angle)

a.rotate(instanceList=('PART-1-1', ), axisPoint=(0.0, 0.0, 1.0),    # need to check the angle at which they rotate
    axisDirection=(0.0, 0.0, 1.0), angle=Pitch[row_index])

position_aft = a.instances['PART-1-1'].getRotation()
Angleaft = position_aft[2]

print('Angle of the blade now = ' + str(Angleaft)+ '\n')

# # Precone

a.rotate(instanceList=('PART-1-1', ), axisPoint=(0.0, 0.0, 0.0), 
    axisDirection=(1.0, 0.0, 0.0), angle=precone)

zcoor = sqrt(100/((tan(precone*pi/180)**2)+1))
ycoor = -tan(precone*pi/180)*zcoor

a.rotate(instanceList=('PART-1-1', ), axisPoint=(0.0, 0.0, 0.0), 
    axisDirection=(0, ycoor, zcoor), angle=-Pitch[row_index])

# a.rotate(instanceList=('PART-1-1', ), axisPoint=(0.0, 0.0, 0.0), 
#     axisDirection=(0.628371, -0.168371, 0.759474), angle=-38.866574)

# ((-0.035036, 0.168629, 0.014943), (0.461614, 0.017315, 0.886912), 43.139419)






############# Step #############

mdb.models['refblade_master'].StaticStep(name='Step-1', previous='Initial')
mdb.models['refblade_master'].steps['Step-1'].setValues(timePeriod=1,nlgeom=ON,initialInc=0.1,maxNumInc=100000)

mdb.models['refblade_master'].StaticStep(name='Step-2', previous='Step-1')
mdb.models['refblade_master'].steps['Step-2'].setValues(timePeriod=round(cycles*2*pi/(Omega[row_index]),1), timeIncrementationMethod=FIXED, noStop=OFF,initialInc=0.1,maxNumInc=100000,nlgeom=ON)

# Field Output
mdb.models['refblade_master'].FieldOutputRequest(name='F-Output-1', 
    createStepName='Step-1', variables=('S', 'MISES', 'MISESMAX', 'TSHR', 
    'CTSHR', 'ALPHA', 'TRIAX', 'LODE', 'VS', 'PS', 'CS11', 'ALPHAN', 'SSAVG', 
    'MISESONLY', 'PRESSONLY', 'SEQUT', 'YIELDPOT', 'NBSEQ', 'GKSEQ', 'U', 'UT', 
    'UR', 'V', 'VT', 'VR', 'RBANG', 'RBROT'))

# Set of all the reference nodes

regionDef=mdb.models['refblade_master'].rootAssembly.sets['REF_ALL']

mdb.models['refblade_master'].HistoryOutputRequest(name='Flapwise', 
    createStepName='Step-2', variables=('U2', ), region=regionDef, 
    sectionPoints=DEFAULT, rebar=EXCLUDE)

mdb.models['refblade_master'].HistoryOutputRequest(name='Edgewise', 
    createStepName='Step-2', variables=('U1', ), region=regionDef, 
    sectionPoints=DEFAULT, rebar=EXCLUDE)

print('############# Step #############')
print('Time for 1 cycle =' + str(2*pi/(Omega[row_index])))
print('no of cycles = '+ str(cycles))
print('Step time for cyclic loading =' + str(round(cycles*2*pi/(Omega[row_index]),1)))
print()









############# Loads ##################
print('############# Loads #############')


# Aeroloads to the nodes
# ABAQUS Variables 
nodes = 101
Dist_list = []

for ref_no in range(nodes):
    #CoorZ = mdb.models['refblade_master'].rootAssembly.instances['PART-1-1'].nodes[101395+ref_no].coordinates[2]    #Redo with the sets
    X = mdb.models['refblade_master'].rootAssembly.sets['REFPOINT-%03.f_REFPOINT' %(ref_no+1)].nodes[0].coordinates[0]
    Y = mdb.models['refblade_master'].rootAssembly.sets['REFPOINT-%03.f_REFPOINT' %(ref_no+1)].nodes[0].coordinates[1]
    Z = mdb.models['refblade_master'].rootAssembly.sets['REFPOINT-%03.f_REFPOINT' %(ref_no+1)].nodes[0].coordinates[2]
    #print(CoorZ)
    Dist = sqrt(X**2+Y**2+Z**2)

    Dist_list.append(Dist)

# Convert the list to a NumPy array (matrix)
coorZ_matrix = np.array(Dist_list)

# Manually change the last value of CoorZ to 89
coorZ_matrix[-1] = 89

# Export coorZ_Matrix 
output_file = 'C:\Abaqus_temp\scripts\coorZ_matrix.csv'

# Export the matrix to a CSV file
np.savetxt(output_file, coorZ_matrix, delimiter=',', fmt='%.6f')

#Import loads 
if Aeroload == 1: 
    print('Custom Loads')
    input_LESFx = r'C:\Abaqus_temp\scripts\CSV Files\Fx_LES_9.CSV'
    input_LESFz = r'C:\Abaqus_temp\scripts\CSV Files\Fz_LES_9.CSV'

    LESFx =  np.loadtxt(input_LESFx, delimiter=',', skiprows=1)
    LESFz =  np.loadtxt(input_LESFz, delimiter=',', skiprows=1)

    Fx = LESFx[:,1]*1000
    Fz = LESFz[:,1]*1000

    RadiusFx = LESFx[:,0]*89.15
    RadiusFz = LESFz[:,0]*89.15

else:
    print('Using DTU10MW Aeroloads')
    RadiusFx    = data2[:,0]    # Metres from 4-89, 101 points
    RadiusFz    = data2[:,0]
    Fz          = data2[:,1]
    Fx          = data2[:,2]


# Intepret Values
Fx_interpolated = np.interp(coorZ_matrix, RadiusFx, Fx)
Fz_interpolated = np.interp(coorZ_matrix, RadiusFz, Fz)

areaFx = abs(np.trapz(Fx, RadiusFx))
areaFz = abs(np.trapz(Fz, RadiusFz))

#print(coorZ_matrix)
print()
#print(Fx_interpolated)
print('########### Unadjusted Values ###########')
print('Total Force, Area Fx =' + str(areaFx))
print('Total Force, Area Fz =' + str(areaFz))

print('Sum of Fx =' + str(sum(Fx_interpolated)))
print('Sum of Fz =' + str(sum(Fz_interpolated)))

print('########### Adjusted Values ###########')
FxAdjustRatio = areaFx/sum(Fx_interpolated)
FzAdjustRatio = areaFz/sum(Fz_interpolated)

Fx_interpolated = Fx_interpolated*FxAdjustRatio
Fz_interpolated = Fz_interpolated*FzAdjustRatio

print('Ajust Fx ratio = '+ str(FxAdjustRatio))
print('Ajust Fz ratio = ' + str(FzAdjustRatio))

print('Total Force, Sum of Fx =' + str(sum(Fx_interpolated)))
print('Total Force, Sum of Fz =' + str(sum(Fz_interpolated)))



# Plot the original data points
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))


ax1.plot(RadiusFx, Fx, marker='o', color='blue', label='Fx')
ax2.plot(RadiusFz, Fz, marker='o', color='blue', label='Fz')

ax1.plot(coorZ_matrix, Fx_interpolated, marker='o', color='red', label='interp Fx')
ax2.plot(coorZ_matrix, Fz_interpolated, marker='o', color='red', label='interp Fz')

# Plot vertical lines 
for z in coorZ_matrix:
    ax1.axvline(x=z, color='g', linestyle='-', linewidth=2)
    ax2.axvline(x=z, color='g', linestyle='-', linewidth=2)

# Add labels and title
ax1.set_title('Loading plot')

plt.xlabel('Radius (m)')
ax1.set_ylabel('Normal Force (N/m)')
ax2.set_ylabel('Tangential Force (N/m)')
ax1.legend()
ax2.legend()


# Show the plot
plt.show()


for ref_no in range(nodes):
    # print('REFPOINT-%03.f_REFPOINT'  %(ref_no+1))
    region = a.sets['REFPOINT-%03.f_REFPOINT' %(ref_no+1)]
    datum = mdb.models['refblade_master'].rootAssembly.instances['PART-1-1'].datums[1082]

    mdb.models['refblade_master'].ConcentratedForce(name='Load-%03.f_REFPOINT'  %(ref_no+2), 
        createStepName='Step-1', region=region, cf1=Fz_interpolated[ref_no], cf2=Fx_interpolated[ref_no],
        distributionType=UNIFORM, field='', localCsys=None, follower=ON)
    #, follower=ON Nodal Rotation setting
    # 
    # From paper, the force is normal and tangent along the span 





# Rotational Loads

region = a.sets['All']
mdb.models['refblade_master'].RotationalBodyForce(name='Load-Rotational', 
    createStepName='Step-1', region=region, magnitude=Omega[row_index], centrifugal=ON, 
    rotaryAcceleration=OFF, point1=(0.0, 0.0, 0.0), point2=(0.0, 01.0, 0.0))




# Gravitational loads
# Rotates anti-clockwise, Starting at bottom dead centre ie blade tip pointed to ground

# Periodic Amplitude
mdb.models['refblade_master'].PeriodicAmplitude(name='Sin', timeSpan=STEP, 
    frequency=Omega[row_index], start=0.0, a_0=0.0, data=((0.0, 1.0), ))
    
mdb.models['refblade_master'].PeriodicAmplitude(name='Cos', timeSpan=STEP, 
    frequency=Omega[row_index], start=0.0, a_0=0.0, data=((1.0, 0.0), ))

#Grav Loading
mdb.models['refblade_master'].Gravity(name='Load-GravSin', createStepName='Step-2',     # Note the -1 Due to inital location of grac vector 
    comp1=-1.0, amplitude='Sin', distributionType=UNIFORM, field='')

mdb.models['refblade_master'].Gravity(name='Load-GravCos', createStepName='Step-2', 
    comp3=1.0, amplitude='Cos', distributionType=UNIFORM, field='')