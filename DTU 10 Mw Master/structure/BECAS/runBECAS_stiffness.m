% =============================================================
% Computation of cross section stiffness and mass properties
% using BECAS. See http://www.becas.dtu.dk.
% =============================================================

% Clean up
close all; clear all; clc; format short;

% Remember the current working directory
ori_dir = pwd;

% Read shellexpander logfile
fid = fopen('becas_input_stiffness\shellexpander_sections.log');
C = textscan(fid, '%s %f %s','CommentStyle','#');
fclose(fid);
section_names = C{1}; radial_positions = C{2}; directory_names = C{3};

% Setup Paths for BECAS
basepath = 'C:\workdir\BECAS\tags\BECASv2.3.LiteRotor.1\src\matlab';
addpath(genpath(basepath));

% Show a waitbar
wb = waitbar(0,'');

% Run BECAS for all cross-sections
for i=1:length(section_names)
    
    % Update waitbar
    waitbar(i/length(section_names),wb,sprintf('Running BECAS: Section %d of %d',i,length(section_names)));
    
    % Load data and set element type
    cd(fullfile(ori_dir,directory_names{i}));
    options.foldername=fullfile(ori_dir,directory_names{i});
    options.etype='Q8';
    
    % Build arrays for BECAS
    [ utils ] = BECAS_Utils( options );
    
    % Call BECAS module for the evaluation of the cross section stiffness matrix
    [constitutive.Ks,solutions] = BECAS_Constitutive_Ks(utils);
    
    % Call BECAS module for the evaluation of the cross section mass matrix
    [constitutive.Ms] = BECAS_Constitutive_Ms(utils);
      
    % Call BECAS module for the evaluation of the cross section properties
    [csprops] = BECAS_CrossSectionProps(constitutive.Ks,utils);
    
    % Overwrite orientation of principle axis if r<10m (the root)
    r_overwrite_princ_axis = 10.0;
    if radial_positions(i)<r_overwrite_princ_axis
        csprops.AlphaPrincipleAxis_ElasticCenter = 0.0;
        csprops.AlphaPrincipleAxis = 0.0;
    end
    
    % Write results to text file 
    BECAS_PrintResults( constitutive, csprops, utils );

    close all;
    
    %Generate figures based on BECAS input
    %savefig_flag=1;
    %BECAS_PlotInput( savefig_flag, utils );

    %Generate figures based on BECAS output
    savefig_flag=1;
    BECAS_PlotOutput(savefig_flag, utils,csprops);

    % Output results to PARAVIEW
    % BECAS_PARAVIEW( 'paraview', utils, csprops);
        
    % Back to original directory
    cd(ori_dir);
 
    % Write output in HAWC2 format
    %OutputFilename='BECAS2HAWC2.out'; 
    %BECAS_Becas2Hawc2(OutputFilename,radial_positions(i),constitutive,csprops,utils);
   
end

% Close the waitbar
close(wb);

% Close all files and figures that might still be open...
fclose('all');
close all;