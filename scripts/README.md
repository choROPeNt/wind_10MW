# Scripts
## AeroloadComparison.py 
This script is used to verify and plot out the loading that will be applied to the blade compared to the loads provided in the DTU 10 MW master file 

The CSV file format of the input loads for flapwise and edgewise displacement should x(length along radius) and y(N/m). The x axis is from 0 m to 89.15 m.  

If there is a label at the top of the csv use ", skiprows=1" in the np.genfromtxt function

```python
np.genfromtxt(file_path1, comments='#', delimiter=None, skiprows=1)
```

## FlapandEdgeDisp.py
This is a post processing script used to compare the data gathered from the loads imputted on to the DTU 10 MW ABAQUS model. The displacements are taken from the REF_POINT nodes on the model. 

To get the displacements from ABAQUS; 
1. Create a set called REF_ALL which is the set of all the REF_POINT
2. In the XY Data Manager, create from ODB field output
3. Position = Unique nodal , Variables = U1 or U2 (But do 1 at a time) , Node sets = REF_ALL , Active Steps/frames = choose the last step only. Save As = as is
4. Create XY Data = Operate on XY Data, click append the Operators and choose append setting and add all the U values into the append. 
5. Final output would be a [2 X No_of_REF_POINTS] matrix
6. Plug-ins -> Tools -> Excel Utilities -> Save as CSV


## LoadDATA2Abaqus.py
The script would automatically input these loads on the DTU 10 MW ABAQUS model
1. Aerodynamic loads
2. Rotational loads
3. Gravitational loads

The Aerodynamic loads and Rotational loads are based off the DTU 10 MW controller from DTU 10 MW Master -> 3D -> ellipse -> Baseline -> Turb/Tran folder. But custom inputs are able to be inputted for both. Use the AeroloadComparison.py to verify loading before. 

Gravitational loads are applied in 2 vectors with sinusodial loading in both vectors. The starting location of the blade in pointing bottom dead centre, 6 o'clock. 

The Aerodynamic, Rotational and Downward pointing Gravitational loads are applied in **Step 1**. This is beacause these loads are static and are applied as a ramp function. 

The cyclic loads Gravitational are then applied in **Step 2**.

### For rotor only simulations
Only have the **Rotational and Aerodynamic loads** on the blade and only have **step 1**.

### Running the script 
Once the script has been requested to run from ABAQUS. A graph would appear with the input aerodynamic loads and corrected aerodyanmic loads with futher details in the report. 

The Message Area would then  output the current settings as a verification step to ensure the inputs have been inputted correctly.

etc.
########### Input Data ###########
Flow type = turb
Windspeed (m/s) = 9
()
Rotational Speed (Rad/s) = 0.757036
Blade angle = -6e-05
Precone angle = 0
()
Using Custom Loading
Angle of the blade now = 6e-05
############# Step #############
Time for 1 cycle =8.299717988549535
no of cycles = 2
Step time for cyclic loading =16.6
()
############# Loads #############
Custom Loads
()
########### Unadjusted Values ###########
Total Force, Area Fx =350836.12402785954
Total Force, Area Fz =52609.57558176201
Sum of Fx =410822.433926
Sum of Fz =61791.1900782
########### Adjusted Values ###########
Ajust Fx ratio = 0.8539848242353242
Ajust Fz ratio = 0.8514090036976263
Total Force, Sum of Fx =350836.124028
Total Force, Sum of Fz =52609.5755818

:shipit: