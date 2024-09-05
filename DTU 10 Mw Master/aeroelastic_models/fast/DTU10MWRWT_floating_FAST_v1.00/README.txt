
Welcome! 

This folder contains FAST models of the two floating wind turbines publicly defined in the LIFES50+ project, http://lifes50plus.eu/

The numerical models have been prepared by Antonio Pegalajar-Jurado (ampj@dtu.dk), Freddy Madsen (fjma@dtu.dk) and Michael Borg (borg@dtu.dk) at DTU Wind Energy. 
In case of publication of work resulting from the use of the models, please follow the referencing instructions given in Section 7 of the D4.5 document.

The numerical models have been set up for FAST v8.16.00a-bjj, 32-bit version. You can get the FAST executable and manual from https://nwtc.nrel.gov/FAST8

The folder is distributed as follows:

- The document "LIFES50+ D4.2 Public definition of the two LIFES50+ 10MW floater concepts" describes the two floater concepts.
- The document "LIFES50+ D4.5 State-of-the-art models for the two LIFES50+ floater concepts" describes the numerical implementation in FAST of the two floater concepts.
- The model folder \DTU10MWRWT_NAUTILUS_GoM_FAST_v1.00 contains the FAST model of the DTU10MW RWT mounted on the NAUTILUS-10 floating substructure.
- The model folder \DTU10MWRWT_OO_GoM_FAST_v1.00 contains the FAST model of the DTU10MW RWT mounted on the OO-Star Semi floating substructure.
- The folder \Wind_fields contains TurbSim input files for different mean wind speeds, which were used in TurbSim v1.06.00 to create the *.bts files used in the two models to produce the results in the D4.5 document. The output summary files *.sum are also included. You can get the TurbSim executable from https://nwtc.nrel.gov/TurbSim

Each model folder contains several subfolders:

- The folder \Mooring contains the MoorDyn input file used in all the simulations.
- The folder \Platform contains the WAMIT output files used in all the simulations.
- The folder \Rotor contains the Aerodyn input file, the airfoil files and the ElastoDyn_blades file used in all the simulations.
- The folder \Tower contains the ElastoDyn_tower input file used in all the simulations.
- The rest of folders starting with a number are simulation cases (see Section 4 of the D4.5 document for details). Please note that each simulation folder contains 
  independent InflowWind, ServoDyn, ElastoDyn and HydroDyn files.