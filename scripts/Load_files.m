%  This script calls a GUI that asks the user to load the EEG, sleep
%  scoring, manual artifact rejection as well as previously performed
%  semi-autoatic artifact rejection files. They will be loaded subsequently.
%  Only the EEG is manadatory to load. The rest is optional.
%
%  Important variables:

%  EEG:         EEG structure containing your EEG data. This structure
%               needs to have subfields correspondings to EEGLAB's EEG 
%               structure.
%  visnum:      A vector storing your sleep scoring
%  visgood:     A vectore storing clean epochs from any form of previously
%               performed (manual) artifact rejection
%  artndxn      A channel x epoch matrix storing results from previously
%               performed semi-automatic artifact rejection using this
%               procedure
%
% #########################################################################

% *** Add EEGLAB's functions correctly to MATLAB
addedpaths = strsplit(path(), pathsep); % All paths in Matlab's set path
if ~any(cellfun(@(x) contains(x, fullfile(pname_eeglab, 'plugins')), addedpaths))
    
    % Checks if EEGLAB has previously been called in this session. If not,
    % call EEGLAB and close the pop-up window.
    eeglab; close;
end


% *** Grab files
[nameEEG, pathEEG]  = uigetfile({'*.mat','EEG file (*.mat)'}, ...
    'Select file containing EEG structure', ...
    'Select .mat file with EEG structure', ...
    'MultiSelect', 'off');   
[nameVIS, pathVIS]  = uigetfile({'*.mat;*.vis','Scoring file (*.mat, *.vis)'}, ...
    'Select file containing sleep scoring', ...
    fullfile(pathEEG, '..', '..', 'Select file containing sleep scoring'), ...    
    'MultiSelect', 'off');
[nameART, pathART]  = uigetfile({'*.mat','Artndxn file (*.mat)'}, ...
    'Do you want to modify an alerady existing artifact rejection output?', ...
    fullfile(pathEEG, '..', '..', 'Select an artndxn.mat file to modify, cancel otherwise'), ...
    'MultiSelect', 'off');
[nameMAN, pathMAN]  = uigetfile({'*.mat','Manual artifact rejection file (*.mat)'}, ...
    'Manual artifact rejection', ...
    fullfile(pathEEG, '..', '..', 'Select file containing manual artifact rejection, cancel otherwise'), ...
    'MultiSelect', 'off');


% ### Load sleep scoring
% #########################

% *** Load sleep scoring
fileVIS = fullfile(pathVIS, nameVIS);        % Sleep scoring file

if endsWith(fileVIS, '.mat')
    % .mat files
    visnum = load(fileVIS, vname_visnum);    % Load sleep scoring
    visnum = visnum.(vname_visnum)           % Rename sleep scoring
    fprintf('** Load %s\n', nameVIS)
elseif endsWith(fileVIS, '.vis')
    % .vis files
    [vistrack, vissymb, offs] = visfun.readtrac(fileVIS, 1);     % Load manual artifact rejection
    visnum                    = visfun.numvis(vissymb, offs);    % Load sleep scoring
    fprintf('** Load %s\n', nameVIS)
% elseif endsWith(fileVIS, '.txt')
% add case of sleep scoring saved as .txt file
else 
    visnum = [];  % No sleep scoring
end

% Transverse column vector to row vector.
if ~isrow(visnum) & ~isempty(visnum)
    % Sleep scoring must be a vector of one row.
    visnum = visnum';
end


% ### Load manual artifact rejection
% #####################################

% *** Load manual artifact rejection
fileMAN = fullfile(pathMAN, nameMAN);         % Manual artifact rejection file

if endsWith(fileMAN, '.mat')
    % .mat file
    visgood = load(fileMAN, vname_visgood);   % Load manual artifact rejection
    visgood = visgood.(vname_visgood)         % Rename manual artifact rejection
    fprintf('** Load %s\n', nameMAN)    
elseif endsWith(fileVIS, '.vis')
    %. vis file
    visgood = find(sum(vistrack') == manual); % Manual artifact detection     
else
    visgood = [];   % No manual artifact detection
end


% *** Get clean sleep epochs
if ~isempty(visnum)
    % In case sleep scoring was loaded in
    vissleep = find(ismember(visnum, stages)); % Epochs within sleep stages of interest
    stages_of_interest = vissleep;             % All corresponding sleep Stages

else
    stages_of_interest = [];
end
if ~isempty(visnum) & ~isempty(visgood) 
    % In case manual artifact rejection was loaded in 
    stages_of_interest = intersect(visgood, vissleep);  
                                               % Clean sleep epochs 
end
                         

% ### Load EEG
% ################

% *** Load EEG
fprintf('** Load %s\n', nameEEG)      
load(fullfile(pathEEG, nameEEG), vname_eeg)   % Load EEG structure

% *** Channel locations
EEG.chanlocs = readlocs(fname_chanlocs);      % Channel locations;


% ### Load Artndxn
% ###################

% *** Load Artndxn
fileART = fullfile(pathART, nameART);         % Load artndxn

if endsWith(fileART, '.mat')
    % .mat file
    load(fileART, 'artndxn');                    % Load artifact rejection
    fprintf('** Load %s\n', nameART)    
    [~, outART]     = fileparts(nameART);        % Filename of output file    
    outART          = [outART '_modified.mat'];  % To indicate it was modified
elseif isstr(nameVIS)
    % Sleep scoring exists
    [~, outART]     = fileparts(nameVIS);        % Filename of output file
    outART          = [outART, '_artndxn.mat'];  % Append filename
    pathART         = pathVIS;                   % Output path
    artndxn         = [];
else
    % No file
    [~, outART]     = fileparts(nameEEG);        % Filename of output file
    outART          = [outART, '_artndxn.mat'];  % Append filename
    pathART         = pathEEG;                   % Output path
    artndxn         = [];    
end
fprintf('** Artndxn will be saved here: %s\n', pathART)    


% *** Convert to single to save space
visgood     = single(visgood);
visnum      = single(visnum);