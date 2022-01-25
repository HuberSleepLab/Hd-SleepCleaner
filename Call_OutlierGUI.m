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
[fileEEG, pathEEG]  = uigetfile('*.mat', 'Select *.mat file (EEG structure)', fullfile(pathVIS, 'Select .mat file (EEG structure)'), 'MultiSelect', 'off');                                    % Select .vis 
[fileART, pathART]  = uigetfile('*.mat', 'Select artndxn file if you want to continue', fullfile(pathVIS, 'Select artndxn.mat if you want to continue, cancel otherwise'), 'MultiSelect', 'off'); % Select artndxn file if you want to continue

% Artndxn filename
if ~isstr(fileART)
    [~, nameART] = fileparts(fileVIS);
    nameART = [nameART, '_artndxn.mat'];    
    pathART = pathVIS;
end

% Load sleep scoring
fprintf('** Load %s\n', fileVIS)
[vistrack, vissymb, offs] = visfun.readtrac(fullfile(pathVIS, fileVIS), 1);
[visnum]                  = visfun.numvis(vissymb, offs);

% Compute sleep parameters
visgood  = find(sum(vistrack') == 0);
vissleep = find(vissymb=='1' | vissymb=='2' | vissymb=='3' | vissymb=='4')';
ndxsleep = intersect(visgood, vissleep);

% Load EEG
fprintf('** Load %s\n', fileEEG)      
load(fullfile(pathEEG, fileEEG), 'EEG')

% Load Artndxn
if isstr(fileART)
    fprintf('** Load %s\n', fileART)      
    load(fullfile(pathART, fileART), 'EEG')
end
fprintf('** Artndxn will be saved here: %s\n', pathART)    


% ********************
%       P Welch
% ********************

% Work with 128 channels
EEG = pop_select(EEG, 'channel', 1:128);

% Robust z-standardization of EEG
EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));

% Compute pwelch
[FFTtot, freq] = pwelchEPO(EEG_RZ, 125, 20);

% ********************
%         SWA 
% ********************

% Compute SWA
SWA = select_band(FFTtot, freq, 0.75, 4.5, ndxsleep);

% Manual artifact rejection
[ manoutSWA ] = OutlierGUI(SWA, ...
    'sleep', visnum, ...
    'EEG', EEG_RZ, ...
    'chanlocs', chanlocs, ...
    'topo', SWA, ...
    'spectrum', FFTtot, ...
    'epo_thresh', 8);


% ********************
%         BETA 
% ********************

% Compute BETA
BETA = select_band(FFTtot, freq, 20, 30, ndxsleep);

% Set artifacts to NaN
BETA( isnan(manoutSWA.cleanVALUES) ) = nan;
SWA(  isnan(manoutSWA.cleanVALUES) ) = nan;

% Manual artifact rejection
[ manoutBETA ] = OutlierGUI(BETA, ...
    'sleep', visnum, ...
    'EEG', EEG_RZ, ...
    'chanlocs', chanlocs, ...
    'topo', SWA, ...
    'spectrum', FFTtot, ...
    'epo_thresh', 10);


% ********************
%       Deviation 
% ********************

% How much channel deviate from mean
devEEG = deviationEEG(EEG_RZ, 125, 20);

% Set artifacts to NaN
devEEG( isnan(manoutBETA.cleanVALUES) ) = nan;
BETA( isnan(manoutBETA.cleanVALUES) )   = nan;
SWA(  isnan(manoutBETA.cleanVALUES) )   = nan;

% Manual artifact rejection
[ manoutEEG ] = OutlierGUI(devEEG, ...
    'sleep', visnum, ...
    'EEG', EEG_RZ, ...
    'chanlocs', chanlocs, ...
    'topo', SWA, ...
    'spectrum', FFTtot, ...
    'epo_thresh', 8);


% ********************
%     Save output
% ********************

% Artndxn correspondence
artndxn = ~isnan(manoutEEG.cleanVALUES);

% Convert to single
artndxn     = logical(artndxn);
visgood     = single(visgood);
visnum      = single(visnum);
% IMP.evening = single(IMP.evening);
% IMP.morning = single(IMP.morning);    

% % save
save(fullfile(pathART, nameART), 'artndxn', 'visnum', 'visgood')

artout = artfun(artndxn, visnum, ...
    'visgood', visgood, 'exclChans', [107 113, 126, 127], 'cleanThresh', 97, 'plotFlag', 1);
            