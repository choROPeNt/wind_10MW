This folder contains a complete description of the DTU 10MW reference 
wind turbine blade's external and internal geometry and composite layup 
in the form of an ABAQUS finite element shell model.
The prebend is not included.

The file refblade_master.inp is the main input file.
The other files with extension .inp a referenced in refblade_master.inp

The shape of the tip of the blade (between r=88.3m and r=89.166) is not 
modeled correctly, as this was judged unimportant for the structural model.

refblade.cae and refblade.jnl are files for the ABAQUS/CAE pre-processor, 
which was used for mesh generation.

The file DTU_10MW_refblade_structural.stp.zip contains the geometry of
the structural model in STEP format. This file was exported from ABAQUS/CAE 
without further checking the quality of the representation.

The file cross_sections.inp contains lists of x-y-coordinates for a number 
of cross-sections. The first line after every *BLADESECTION keyword is the
radial position. Some points are marked as keypoints ("KP"). 
These points are the boundaries between circumferential regions.

Further details about the finite element model can be found in the report.
