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

clear all; 
close all;
clc;

% *** Call configuration file
pmain = fileparts(mfilename('fullpath'));           % Path to this script
run(fullfile(pmain, 'Configuration_OutlierGUI.m'))  % Calls configurations

% *** Call script that loads files
run('Load_files.m')



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
artndxn = outlier_routine(EEG, M1, artndxn, visnum, 8, 10, 8, ...
    'stages', stages, ...    
    'stages_of_interest', stages_of_interest, ...
    'chans_excl', chans_excl);


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
artndxn = outlier_routine(EEG, M2, artndxn, visnum, 10, 12, 10, ...
    'stages', stages, ...        
    'stages_of_interest', stages_of_interest, ...
    'chans_excl', chans_excl);

% Save
save(fullfile(pathART, outART), 'artndxn', 'visnum', 'visgood')

% Evaluation plots
run('Evaluation_plots.m')

save(fullfile(pathART, 'M'), 'M')

% % *** Call for debugging
% [FFTtot, freq] = pwelchEPO(EEG.data, EEG.srate, scoringlen);
% SWA = select_band(FFTtot, freq, 0.5, 4.5, stages_of_interest, artndxn, chans_excl);
% [ manoutSWA ] = OutlierGUI(SWA, ...
%     'sleep', visnum, ...
%     'EEG', EEG.data, ...
%     'chanlocs', chanlocs, ...
%     'topo', SWA, ...
%     'spectrum', FFTtot, ...
%     'epo_select', find( ismember( scoring, [-1 -2 -3] )), ...
%     'epo_thresh', 12);
            