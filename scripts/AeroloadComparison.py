import numpy as np
import matplotlib.pyplot as plt
import os as os 

# Current Working Directory
print("Current working directory = " + os. getcwd())
print()

# Initial variables

flow =  'turb'              # 'turb' or 'tran'
wsp = 9                     # Windspeed [5,6,8,9,10,11,12,16,20,25]
cycles = 2
precone = 2.5
tilt = 5

# .dat files
file_path1 = '..\\wind_10MW\\DTU 10 Mw Master\\CFD\\3D_DTU_10MW_RWT\\baseline\\EllipSys3D\\' + 'turb' + '\\wsp_' + str(wsp) + '_spanwise_loads.dat'
file_path2 = '..\\wind_10MW\\DTU 10 Mw Master\\CFD\\3D_DTU_10MW_RWT\\baseline\\EllipSys3D\\' + 'tran' + '\\wsp_' + str(wsp) + '_spanwise_loads.dat'

data1 = np.genfromtxt(file_path1, comments='#', delimiter=None) 
data2 = np.genfromtxt(file_path2, comments='#', delimiter=None) # Radius, Fx, Fz, localCp, localCt [101x5] 

# fx = data1[0:data1.shape[0],1]
# fz = data1[0:data1.shape[0],2]

input_LESFx = r'..\wind_10MW\scripts\CSV Files\Forces\Fx_LES_9.CSV'
input_LESFz = r'..\wind_10MW\scripts\CSV Files\Forces\Fz_LES_9.CSV'


fx_turb = data1[0:data1.shape[0],1]
fz_turb = data1[0:data1.shape[0],2]

fx_tran = data2[0:data2.shape[0],1]
fz_tran = data2[0:data2.shape[0],2]

Radius = data1[0:data1.shape[0],0]

LESFx =  np.loadtxt(input_LESFx, delimiter=',', skiprows=1)
LESFz =  np.loadtxt(input_LESFz, delimiter=',', skiprows=1)

fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))

ax1.plot(Radius,fz_turb, marker='o', linestyle='-', color='r', markersize=5, label = 'Fz Turb')
ax1.plot(Radius,fz_tran, marker='o', linestyle='-', color='g', markersize=5, label = 'Fz Tran')

ax1.plot(LESFx[:,0]*89.15,LESFx[:,1]*1000, marker='o', linestyle='-', color='b', markersize=5, label = 'Fz LES')

ax1.set_title('Aerodynamic forces at windspeed of 9 m/s')
ax1.set_ylabel('Normal Loading (N)')
ax1.legend()
ax1.grid(True)

ax2.plot(Radius,fx_turb, marker='o', linestyle='-', color='r', markersize=5, label = 'Fx Turb')
ax2.plot(Radius,fx_tran, marker='o', linestyle='-', color='g', markersize=5, label = 'Fx Tran')

ax2.plot(LESFz[:,0]*89.15,LESFz[:,1]*1000, marker='o', linestyle='-', color='b', markersize=5, label = 'Fx LES')
ax2.set_ylabel('Tangential Loading (N)')
ax2.set_xlabel('Radius (m)')

ax2.grid(True)

plt.legend()
plt.show()