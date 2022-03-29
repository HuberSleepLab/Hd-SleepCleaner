% *************************************************************************
%
% Performs semi-automatic artifact rejection based on 
%   Huber et al. (2000). Exposure to pulsed high-frequency electromagnetic 
%   field during waking affects human sleep EEG. Neuroreport 11, 3321–3325. 
%   doi: 10.1097/00001756-200010200-00012
%
% Performs artifact rejection on all channels at once with robustly
% Z-Standardized EEG signals.
%
% Date: 25.01.2021
%
% *************************************************************************

clear all; 
close all;
clc;

% Variables to specify
scoringlen = 20;          % window length of sleep scoring (in seconds)

% add paths
filenamepath = fileparts(mfilename('fullpath'));        % path to this script
addpath(genpath(fullfile(filenamepath, 'chanlocs')));   % add path to channel locations
addpath(genpath(fullfile(filenamepath, 'colormap')));   % add path to colormap
addpath(genpath(fullfile(filenamepath, 'functions')));  % add path to functions
addpath('C:\PhDScripts\EEGlab2021.1');                  % add path to helper-functions

% You need to call eeglab once to load in channel locations
% eeglab; close;

% Channel locations
chanlocs = readlocs('test129.loc');



% ********************
%      Grab files
% ********************

% Grab files
[fileVIS, pathVIS]  = uigetfile('*.vis', 'Select *.vis file (containing sleep scoring)', 'Select .vis file', 'MultiSelect', 'off');                                    % Select .vis 
[fileART, pathART]  = uigetfile('*.mat', 'Select artndxn file if you want to continue', fullfile(pathVIS, '..', 'Select artndxn.mat if you want to continue, cancel otherwise'), 'MultiSelect', 'off'); % Select artndxn file if you want to continue
[fileEEG, pathEEG]  = uigetfile('*.mat', 'Select *.mat file (EEG structure)', fullfile(pathVIS, '..', 'Select .mat file (EEG structure)'), 'MultiSelect', 'off');                                    % Select .vis 

% Artndxn filename
if ~isstr(fileART)
    [~, nameART] = fileparts(fileVIS);
    nameART = [nameART, '_artndxn.mat'];    
    pathART = pathVIS;
else
    nameART = fileART;
end

% Load sleep scoring
fprintf('** Load %s\n', fileVIS)
[vistrack, vissymb, offs] = visfun.readtrac(fullfile(pathVIS, fileVIS), 1);
[visnum]                  = visfun.numvis(vissymb, offs);

if ~isrow(visnum) 
    visnum = visnum';
end

% Compute sleep parameters
visgood  = find(sum(vistrack') == 0);
vissleep = find(vissymb=='1' | vissymb=='2' | vissymb=='3' | vissymb=='4')';
ndxsleep = intersect(visgood, vissleep);

% Load EEG
fprintf('** Load %s\n', fileEEG)      
load(fullfile(pathEEG, fileEEG), 'EEG')

EEG.chanlocs = chanlocs;

% Load Artndxn
if isstr(fileART)
    fprintf('** Load %s\n', fileART)      
    load(fullfile(pathART, fileART), 'artndxn')
else
    artndxn = [];
end
fprintf('** Artndxn will be saved here: %s\n', pathART)    



% ********************
%    CZ referenced
% ********************

% Work with 128 channels
EEG = pop_select(EEG, 'channel', 1:128);

% Outlier routine
artndxn = outlier_routine(EEG, artndxn, ndxsleep, visnum, 8, 10, 8, ...
    'scoringlen', scoringlen);


% ***********************
%   Average referenced
% ***********************

% Set artifacts to nan and then average reference
[EEG.data] = prep_avgref(EEG.data, EEG.srate, scoringlen, artndxn);

% Outlier routine
artndxn = outlier_routine(EEG, artndxn, ndxsleep, visnum, 10, 12, 10, ...
    'scoringlen', scoringlen);


% ********************
%     Save output
% ********************

% Convert to single
artndxn     = logical(artndxn);
visgood     = single(visgood);
visnum      = single(visnum);
% IMP.evening = single(IMP.evening);
% IMP.morning = single(IMP.morning);   

% save
save(fullfile(pathART, nameART), 'artndxn', 'visnum', 'visgood')


% ************
%    Plots
% ************

% Open figure
figure('color', 'w') 
hold on;

% Compute PSD
[FFTtot, freq] = pwelchEPO(EEG.data, EEG.srate, scoringlen);

% Compute SWA
SWA = select_band(FFTtot, freq, 0.5, 4.5, ndxsleep, artndxn);

% Plot SWA
plot(SWA', 'k.:')
ylabel('SWA (\muV^2)')
xlabel('Epoch')

% Channel survival
artout = artfun(artndxn, visnum, ...
    'visgood', visgood, 'exclChans', [107 113, 126, 127], 'cleanThresh', 97, 'plotFlag', 1);




% % *** Call for debugging
% [ manoutSWA ] = OutlierGUI(SWA, ...
%     'sleep', visnum, ...
%     'EEG', EEG.data, ...
%     'chanlocs', chanlocs, ...
%     'topo', SWA, ...
%     'spectrum', FFTtot, ...
%     'epo_select', find( ismember( visnum, [-1 -2 -3] )), ...
%     'epo_thresh', 12);
            