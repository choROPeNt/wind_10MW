from abaqus import *
from abaqusConstants import *
import os as os 

# Current Working Directory
print("Current Working Directory = " + os.getcwd())
cwd = os.getcwd()


# Open the model
model_name = 'refblade_master'
myModel = mdb.models[model_name]

# Define the part name
part_name = 'PART-1'
part = myModel.parts[part_name]

# Loop through 1 to 100 to create combined sets dynamically
for i in range(1, 101):
    # Format the set names and airfoil set names
    set_names = [
        'BLADE-1_CA%03.f' %(i), 'BLADE-1_LP%03.f' %(i), 
        'BLADE-1_NO%03.f' %(i), 'BLADE-1_TA%03.f' %(i), 
        'BLADE-1_TB%03.f' %(i), 'BLADE-1_TC%03.f' %(i), 
        'BLADE-1_TP%03.f' %(i), 'BLADE-1_TV%03.f' %(i)
    ]
    
    # Collect unique nodes from all the specified sets
    node_ids = set()  # Use a set to avoid duplicate node IDs

    for set_name in set_names:
        if set_name in part.sets:  # Check if the set exists
            my_set = part.sets[set_name]  # Access the set by name
            # Collect node IDs (labels)
            for node in my_set.nodes:
                node_ids.add(node.label)  # Add node ID to the set

    # If nodes were found, create the node set
    if node_ids:
        nodes = part.nodes.sequenceFromLabels(labels=list(node_ids))
        part.Set(name='airfoil_%03.f' %(i), nodes=nodes)



Dist_list = []

# Create new REF points 
# Middle of all the ref ?
for i in range(1, 101):
     
    Point1 = mdb.models['refblade_master'].rootAssembly.sets['REFPOINT-%03.f_REFPOINT' %(i)].nodes[0].coordinates
    Point2 = mdb.models['refblade_master'].rootAssembly.sets['REFPOINT-%03.f_REFPOINT' %(i+1)].nodes[0].coordinates

    Avg = [((Point1[0]+Point2[0])/2),((Point1[1]+Point2[1])/2),((Point1[2]+Point2[2])/2)]

    print( str(i) +" ,"+ str(Avg))

    ref_point = mdb.models['refblade_master'].rootAssembly.ReferencePoint(point=Avg)

    # Name the reference point
 
    mdb.models['refblade_master'].rootAssembly.Set(referencePoints=(mdb.models['refblade_master'].rootAssembly.referencePoints[ref_point.id],), name='airfoil_REF_%03.f' %(i))

    X = Avg[0]
    Y = Avg[1]
    Z = Avg[2]
    #print(CoorZ)
    Dist = sqrt(X**2+Y**2+Z**2)

    Dist_list.append(Dist)

Aero_dist = np.array(Dist_list)
output_file = 'C:\Abaqus_temp\scripts\Aero_coorZ_matrix.csv'
np.savetxt(output_file, Aero_dist, delimiter=',', fmt='%.6f')


# Creating constraints 
a = mdb.models['refblade_master'].rootAssembly

for i in range(1,101):
    region1=a.instances['PART-1-1'].sets['airfoil_%03.f' %(i)]
    region2=a.sets['airfoil_REF_%03.f' %(i)]

    mdb.models['refblade_master'].Coupling(name='aerofoil_Constraint_%03.f' %(i), 
        controlPoint=region2, surface=region1, influenceRadius=WHOLE_SURFACE, 
        couplingType=KINEMATIC, alpha=0.0, localCsys=None, u1=ON, u2=ON, u3=ON, 
        ur1=ON, ur2=ON, ur3=ON)
    
# Create new coor list and name it as a new list 
# Apply the aero loading code here DONT COMBINE TO MAIN CODE

