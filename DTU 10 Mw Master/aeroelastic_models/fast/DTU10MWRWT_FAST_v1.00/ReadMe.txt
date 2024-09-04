%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Readme file for LIFES50+ Deliverable 1.2 Wind Turbine Model Directory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Michael Borg, DTU Wind Energy, borg@dtu.dk

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

List of directories:
*ReferenceModal
	**10MWRWT
	**BModes
	**control

*TestRuns
	**TestRun1
	**TestRun2
	**TestRun3

Three test cases of the DTU 10MW Reference Wind Turbine FAST model v1.00 are
supplied with the LIFES50+ Deliverable 1.2 report.

TestRun1: Free decay simulation. Initial fore-aft tower top displacement = 5 metres

TestRun2: Wind turbine operation at rated conditions in steady, uniform wind (11.4m/s)

TestRun3: Wind turbine operation at rated conditions in turbulent wind conditions 
	  (11.4m/s), see TurbSim input file (TurbSim_DTU_10MW.inp) for turbulence 
          parameters

Notes: 
  (1) For TestRun3, reviewers will need to generate turbulent wind time series as it 
      is impractical to supply this with the FAST model. The latest version of TurbSim
      available from NREL may be used
  (2) The 32-bit version of FAST v8.12.00a-bjj  is required to run the DTU 10MW
      Reference Wind Turbine model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%