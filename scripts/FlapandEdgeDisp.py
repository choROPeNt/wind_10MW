import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os as os 

# Current Working Directory
print("Current working directory = " + os. getcwd())
print()

# Load the CSV files
# Edgewise and Flapwise results for U = 10
input_Edgewise_Pre = r'..\wind_10MW\scripts\CSV Files\Displacements\Edgewise-U10-Precone.csv'
input_Flapwise_Pre = r'..\wind_10MW\scripts\CSV Files\Displacements\Flapwise-U10-Precone.CSV'
EdgeDisp_Pre = np.loadtxt(input_Edgewise_Pre, delimiter=',')
FlapDisp_Pre = np.loadtxt(input_Flapwise_Pre, delimiter=',')


input_Edgewise_NPre = r'..\wind_10MW\scripts\CSV Files\Displacements\Edgewise-U10-NoPrecone.CSV'
input_Flapwise_NPre = r'..\wind_10MW\scripts\CSV Files\Displacements\Flapwise-U10-NoPrecone.CSV'
EdgeDisp_NPre = np.loadtxt(input_Edgewise_NPre, delimiter=',')
FlapDisp_NPre = np.loadtxt(input_Flapwise_NPre, delimiter=',')

# Results from papers 
input_Horcas    = r'..\wind_10MW\scripts\CSV Files\Displacements\Horcas et al.CSV'
input_Kang      = r'..\wind_10MW\scripts\CSV Files\Displacements\Kang et al.CSV' 
input_SPWing    = r'..\wind_10MW\scripts\CSV Files\Displacements\SP Wing.CSV'
Horcas  = np.loadtxt(input_Horcas, delimiter=',', skiprows=1)
Kang    = np.loadtxt(input_Kang, delimiter=',', skiprows=1)
SPWing  = np.loadtxt(input_SPWing, delimiter=',', skiprows=1)

input_CFDEdge = r'..\wind_10MW\scripts\CSV Files\Displacements\CFD_Study_U10 Edge.CSV'
CFDEdge = np.loadtxt(input_CFDEdge, delimiter=',', skiprows=1)

input_Horcas11Flap = r'..\wind_10MW\scripts\CSV Files\Displacements\CFD_study_U11 Flap.CSV'
input_Horcas11Edge = r'..\wind_10MW\scripts\CSV Files\Displacements\CFD_study_U11 Edge.CSV'
Horcas11Edge = np.loadtxt(input_Horcas11Edge, delimiter=',', skiprows=1)
Horcas11Flap = np.loadtxt(input_Horcas11Flap, delimiter=',', skiprows=1)

# # Z coordinate CSV file
input_z = r'..\wind_10MW\scripts\CSV Files\coorZ_matrix.CSV'
CoorZ = np.loadtxt(input_z, delimiter=',')

EdgeDisp_Pre = EdgeDisp_Pre[:,1]
FlapDisp_Pre = FlapDisp_Pre[:,1]

EdgeDisp_NPre = EdgeDisp_NPre[:,1]
FlapDisp_NPre = FlapDisp_NPre[:,1]

# print(EdgeDisp_Pre.shape)
# print()
# print(FlapDisp_Pre.shape)
# print(CoorZ.shape)

# Create separate plots
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))

# Plot Edgewise Displacement
ax1.plot(CoorZ, EdgeDisp_Pre, marker='o', linestyle='-', color='r', markersize=5, label = 'ABAQUS Results Precone U=10')
ax1.plot(CoorZ, EdgeDisp_NPre, marker='o', linestyle='-', color='m', markersize=5, label = 'ABAQUS Results No Precone U=10')

ax1.plot(CFDEdge[:,0]*89, CFDEdge[:,1], marker='o', linestyle='-', color='g', markersize=5, label = 'Horcas U=10')
ax1.plot(Horcas11Edge[:,0]*89, Horcas11Edge[:,1], marker='o', linestyle='-', color='y', markersize=5, label = 'Horcas U=11')

ax1.set_title('Edgewise Displacement vs. Z Coordinate')
ax1.set_xlabel('Z Coordinate (m)')
ax1.set_ylabel('Edgewise Displacement (m)')
ax1.grid(True)



# Plot Flapwise Displacement
ax2.plot(CoorZ, FlapDisp_Pre, marker='o', linestyle='-', color='r', markersize=5, label = 'ABAQUS Results Precone U=10')
ax2.plot(CoorZ, FlapDisp_NPre, marker='o', linestyle='-', color='m', markersize=5, label = 'ABAQUS Results No Precone U=10')

ax2.set_title('Flapwise Displacement vs. Z Coordinate')
ax2.set_xlabel('Z Coordinate (m)')
ax2.set_ylabel('Flapwise Displacement (m)')
ax2.grid(True)

ax2.plot(Horcas[:,0]*89, Horcas[:,1], marker='o', linestyle='-', color='g', markersize=5, label = 'Horcas U=10')
ax2.plot(Horcas11Flap[:,0]*89, Horcas11Flap[:,1], marker='o', linestyle='-', color='y', markersize=5, label = 'Horcas U=11')
ax2.plot(Kang[:,0]*89, Kang[:,1], marker='o', linestyle='-', color='k', markersize=5, label = 'Kang U=10')
ax2.plot(SPWing[:,0]*89, SPWing[:,1], marker='o', linestyle='-', color='b', markersize=5, label = 'SP wing U=10')




# Adjust layout
ax1.legend()
plt.legend()
plt.tight_layout()
plt.show()
