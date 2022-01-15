% *************************************************************************
%
% Performs semi-automatic artifact rejection as in 
%   Huber et al. (2000). Exposure to pulsed high-frequency electromagnetic 
%   field during waking affects human sleep EEG. Neuroreport 11, 3321–3325. 
%   doi: 10.1097/00001756-200010200-00012
%
% Date: 04.12.2020
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
addpath('C:\PhDScripts\EEGlab2021.1');   % add path to helper-functions

% You need to call eeglab once to load in channel locations
% eeglab; close;

% Channel locations
chanlocs = readlocs('test129.loc');


% ********************
%      Grab files
% ********************

% FFTtot.mat, xxx.vis
[fileFFT, pathFFT]   = uigetfile('*.mat', 'Select FFTtot.mat (containing power values)', 'Select FFTtot.mat file', 'MultiSelect', 'off');                                                    % Select FFTtot.mat file produced in newEGI_ArtCorr_01.m
[fileVIS, pathVIS]   = uigetfile('*.vis', 'Select *.vis file (containing sleep scoring)', fullfile(pathFFT, 'Select .vis file'), 'MultiSelect', 'off');                                    % Select .vis 

% Cancel if you pressed cancel
if ~isstr(fileFFT) | ~isstr(fileVIS)
    error('FFTtot.mat and .vis files are mandatory.'); end

% Impedances, artndxn.mat
[fileEEG,    pathEEG]  = uigetfile('*.mat', 'Select *.mat file (EEG structure)', fullfile(pathFFT, 'Select .mat file (EEG structure)'), 'MultiSelect', 'off');                                    % Select .vis 
[fileImpE,  pathImpE]  = uigetfile({'*.imp; *.txt'}, 'Select impedance file (evening)', fullfile(pathFFT, 'Select .imp or .txt file with impedances in the evening'), 'MultiSelect', 'off'); % Select .imp file
[fileImpM,  pathImpM]  = uigetfile({'*.imp; *.txt'}, 'Select impedance file (morning)', fullfile(pathFFT, 'Select .imp or .txt file with impedances in the morning'), 'MultiSelect', 'off'); % Select .imp file
[fileArt,   pathART]   = uigetfile('*.mat', 'Select artndxn file if you want to continue', fullfile(pathFFT, 'Select artndxn.mat if you want to continue, cancel otherwise'), 'MultiSelect', 'off'); % Select artndxn file if you want to continue
fprintf('** Artndxn will be saved here: "%s"\n', pathFFT)   


% ********************
%      Load files
% ********************

% FFTTot
load(fullfile(pathFFT, fileFFT))
fprintf('** Load %s\n', fileFFT)

% Sleep scoring
[vistrack, vissymb, offs] = visfun.readtrac(fullfile(pathVIS, fileVIS), 1);
[visnum]                  = visfun.numvis(vissymb, offs);
fprintf('** Load %s\n', fileVIS)

% Previous artndxn
conf.artndxn.filename = extractBefore(fileFFT, '_FFTtot.mat');
conf.artndxn.filename = [conf.artndxn.filename, '_artndxnz.mat'];

% Artndxn already exists
if isstr(fileArt)
    load(fullfile(pathART, fileArt))        % Load existing artndx.mat file
    conf.artndxn.filename = fileArt;        % Overwrite this artndx file
    fprintf('** Load %s\n', fileArt)    
    
    % Check if FFTtot matches artndxn
    if size(FFTtot, 3) ~= size(artndxn, 2)
        error('FFTtot file and artndxn file do not match, you probably selected the wrong files.')
    end

else
    pathART = pathFFT;
end

% Load EEG
if isstr(fileEEG)
    load(fullfile(pathEEG, fileEEG), 'EEG')
    fprintf('** Load %s\n', fileEEG)        
else 
    EEG = [];
end

% ********************
%   Load Impedances
% ********************

% Impedances
IMP = [];

% Variable to loop through impedances both in the evenining + morning
iter.path = {pathImpE, pathImpM};
iter.file = {fileImpE, fileImpM};
iter.fld  = {'evening', 'morning'};
fprintf('** Load %s\n', fileImpE)    
fprintf('** Load %s\n', fileImpM)    


for iIMP = 1:length(iter.path)
    if isstr(iter.file{iIMP})
        
        % Load impedance file here, whether it is an .imp or .txt file
        fileID    = fopen(fullfile(iter.path{iIMP}, iter.file{iIMP}), 'r');
        imp_cell  = textscan(fileID, '%s%s%s%[^\n\r]', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'ReturnOnError', false);         
    
        % Depending on whether impedances were saved as an .imp file or
        % .txt file, the header information is different. Account for that
        % here.
        if contains(iter.file{iIMP}, '.imp') 
            fVal = find(cellfun(@(x) strcmp(x, '01'), {imp_cell{1}{:}}, 'UniformOutput', 1)); 
        elseif contains(iter.file{iIMP}, '.txt')
            fVal = find(cellfun(@(x) strcmp(x, '1'), {imp_cell{1}{:}}, 'UniformOutput', 1)); 
        end         
        
        % Assign impedance values to structure
        IMP.(iter.fld{iIMP})(:,1) = cellfun(@str2num, imp_cell{1}(fVal : end));
        IMP.(iter.fld{iIMP})(:,2) = cellfun(@str2num, imp_cell{3}(fVal : end));        
       
    end
end

% If no impedances were loaded, assign nan
if ~isfield(IMP, 'evening')
    IMP.evening = nan(numel(conf.FFTtot.chans), 2);
end
if ~isfield(IMP, 'morning')
    IMP.morning = nan(numel(conf.FFTtot.chans), 2);
end



% ********************
%  Prepare variables
% ********************

% Sleep parameters
visgood  = find(sum(vistrack') == 0);
vissleep = find(vissymb=='1' | vissymb=='2' | vissymb=='3' | vissymb=='4')';
ndxSleep = intersect(visgood,vissleep);
ndxNREM  =  find(vissymb=='2' | vissymb=='3');

% Compute SWA
SWA = FFTtot(:, freq >= 0.75 & freq <= 4.5, :);
SWA = squeeze(mean(SWA, 2));
SWAZ = ( SWA - mean(SWA, 2) ) ./ std(SWA, [], 2);
SWAZ(:, setdiff( 1:end, ndxSleep )) = nan;
SWA(:, setdiff( 1:end, ndxSleep ))  = nan;

% Manual artifact rejection
[ manoutSWA ] = manoutGUI(SWAZ, ...
    'sleep', visnum, ...
    'EEG', EEG.data, ...
    'chanlocs', chanlocs, ...
    'topo', SWA, ...
    'spectrum', FFTtot);

% Compute Beta
BETA = FFTtot(:, freq >= 20 & freq <= 30, :);
BETA = squeeze(mean(BETA, 2));
BETAZ = ( BETA - mean(BETA, 2) ) ./ std(BETA, [], 2);
BETAZ( isnan(manoutSWA.cleanVALUES) ) = nan;
SWA( isnan(manoutSWA.cleanVALUES) ) = nan;

% Manual artifact rejection
[ manoutBETA ] = manoutGUI(BETAZ, ...
    'sleep', visnum, ...
    'EEG', EEG.data, ...
    'chanlocs', chanlocs, ...
    'topodata', SWA);

% Artndxn correspondence
artndxnz = ~isnan(manoutBETA.cleanVALUES) ;

% ********************
%     Save output
% ********************

% Convert to single
artndxnz    = logical(artndxnz);
visgood     = single(visgood);
visnum      = single(visnum);
IMP.evening = single(IMP.evening);
IMP.morning = single(IMP.morning);    

% % save
save(fullfile(pathART, conf.artndxn.filename), 'artndxnz', 'conf', 'visnum', 'visgood', 'IMP')

artout = artfun(artndxnz, visnum, ...
    'visgood', visgood, 'exclChans', [107 113, 126, 127], 'cleanThresh', 97, 'plotFlag', 1);
            