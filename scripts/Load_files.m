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
    visnum = load(fileVIS);                  % Load sleep scoring
    if isstruct(visnum)
        if numel(fieldnames(visnum)) == 1
            fn_visnum   = fieldnames(visnum);    % Fieldnames of structure  
            visnum      = visnum.(fn_visnum{1}); % Access first subfield
        end
    end
    % .mat file as a structure
    if isstruct(visnum)                      % If your data is stored in 
                                             % a matlab structure
        fn_visnum = fieldnames(visnum);      % Fieldnames of structure    
        for ifn = 1:numel(fn_visnum)
            if all( ismember( stages, visnum.(fn_visnum{ifn}) ));
                % Look for a subfield that contains a vector that contains
                % all the sleep stages you want to look at
                break
            end
        end
        visnum = visnum.(fn_visnum{ifn});    % Get subfield containing 
                                             % sleep scoring
    end
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

% Recode scoring
if ~isempty(visnum)
    visnum( ismember(visnum, N1) )  = -1;    
    visnum( ismember(visnum, N2))   = -2;    
    visnum( ismember(visnum, N3))   = -3;    
    visnum( ismember(visnum, N4))   = -4;    
    visnum( ismember(visnum, W))    =  1;    
    visnum( ismember(visnum, REM))  =  0;    

    stages_recode = stages;
    stages( ismember(stages_recode, N1) )  = -1;    
    stages( ismember(stages_recode, N2))   = -2;    
    stages( ismember(stages_recode, N3))   = -3;    
    stages( ismember(stages_recode, N4))   = -4;    
    stages( ismember(stages_recode, W))    =  1;    
    stages( ismember(stages_recode, REM))  =  0;     
end


% ### Load manual artifact rejection
% #####################################

% *** Load manual artifact rejection
fileMAN = fullfile(pathMAN, nameMAN);         % Manual artifact rejection file

if endsWith(fileMAN, '.mat')
    % .mat file
    visgood = load(fileMAN);                  % Load manual artifact rejection
    if isstruct(visgood) 
        if numel(fieldnames(visgood)) == 1   
            fn_visgood  = fieldnames(visgood);    % Fieldnames of structure  
            visgood     = visgood.(fn_visgood{1});% Access first subfield
        end
    end    
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
EEG = load(fullfile(pathEEG, nameEEG));       % Load EEG structure
if isstruct(EEG) 
    if numel(fieldnames(EEG)) == 1   
        fn_EEG = fieldnames(EEG);    % Fieldnames of structure  
        EEG    = EEG.(fn_EEG{1});    % Access first subfield
    end
end 

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
    outART          = nameART;                   % Filename of output file        
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

% Evaluation plot name
[~, namePLOT]   = fileparts(outART);        % Filename of plot  
namePLOT        = [namePLOT, '.png'];       % Filename of plot  

% *** Convert to single to save space
visgood     = single(visgood);
visnum      = single(visnum);