%
%   *** ATTENTION ***
%   You need to change settings in ** Configuration_OutlierGUI.m **
%   before running!
%
%   Performs semi-automatic artifact rejection based on 
%   Huber et al. (2000). Exposure to pulsed high-frequency electromagnetic 
%   field during waking affects human sleep EEG. Neuroreport 11, 3321–3325. 
%   doi: 10.1097/00001756-200010200-00012
%
% #########################################################################

clearvars; 
close all;
clc;

% *** Call configuration file
pmain = fileparts(mfilename('fullpath'));           % Path to this script
run(fullfile(pmain, 'Configuration_OutlierGUI.m'))  % Calls configurations

% *** Call script that loads files
run('Load_files.m')

% *** Preprocess EEG
run('Preprocess_EEG.m')


% ### Outlier routine (original reference)
% ###########################################

% Work with pre-defined channels
EEG = pop_select(EEG, 'channel', chansID);

% Compute marker (original reference)
[M1] = compute_marker(EEG, scoringlen, stages_of_interest, artndxn, chans_excl, ...
    'L1', L1, ...
    'L2', L2, ...
    'H1', H1, ...
    'H2', H2);

% % Compute marker (median reference)
% [M2] = compute_marker(EEG, scoringlen, stages_of_interest, artndxn, chans_excl, ...
%     'reference', median(EEG.data), ...
%     'L1', L1, ...
%     'L2', L2, ...
%     'H1', H1, ...
%     'H2', H2);

% Outlier routine on original referenced EEG
artndxn = outlier_routine(EEG, M1, artndxn, visnum, 8, 10, 8, outlier_types, ...
    'stages', stages, ...    
    'stages_of_interest', stages_of_interest, ...
    'chans_excl', chans_excl, ...
    'scoringlen', scoringlen);


% ### Outlier routine (average reference)
% ###########################################

% % Median reference
% EEG.data = EEG.data - median(EEG.data);

% Set artifacts to nan and then average reference
[EEG.data] = prep_avgref(EEG.data, EEG.srate, scoringlen, artndxn);

% Compute marker (median reference)
[M2] = compute_marker(EEG, scoringlen, stages_of_interest, artndxn, chans_excl, ...
    'L1', L1, ...
    'L2', L2, ...
    'H1', H1, ...
    'H2', H2);

% Outlier routine on average referenced EEG
artndxn = outlier_routine(EEG, M2, artndxn, visnum, 10, 12, 10, outlier_types, ...
    'stages', stages, ...        
    'stages_of_interest', stages_of_interest, ...
    'chans_excl', chans_excl, ...
    'scoringlen', scoringlen);

% Save
newART = avoid_overwrite(outART, pathART);
save(fullfile(pathART, newART), 'artndxn', 'visnum', 'visgood', 'scoringlen')

% Evaluation plots
run('Evaluation_plots.m')
print(gcf, fullfile(pathART, namePLOT), '-dpng')


% % *** Call for debugging
% [ manoutSWA ] = OutlierGUI(M.SWA, ...
%     'sleep', visnum, ...
%     'EEG', EEG.data, ...
%     'chanlocs', chanlocs, ...
%     'topo', M.SWA, ...
%     'spectrum', M.FFTtot, ...
%     'epo_select', stages_of_interest, ...
%     'epo_thresh', 12);
