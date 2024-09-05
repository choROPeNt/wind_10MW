This directory contains the input files for the cross section analsis tool 
BECAS. 

The BECAS input files used to compute the cross section stiffness 
and mass properties are in becas_input_stiffness.zip. 

The input files used for strength analysis ("stress recovery") are 
in becas_input_strength.zip.

Both zip-files also contain a file called shellexpander_sections.log, which
contains the name of the cross section (column 1), the radial position 
(column 2) and the path to the directory holding the BECAS input files 
(column 4).

The file runBECAS_stiffness.m is an example Matlab file running BECAS
for all cross sections in becas_input_stiffness.zip.

More information is also available at http://www.becas.dtu.dk
