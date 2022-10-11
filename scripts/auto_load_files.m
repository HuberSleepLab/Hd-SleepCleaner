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
% if ~any(cellfun(@(x) contains(x, fullfile(pname_eeglab, 'plugins')), addedpaths))
if ~exist('pop_loadset', 'file')
    % Checks if EEGLAB has previously been called in this session. If not,
    % call EEGLAB and close the pop-up window.

    eeglab; close;
end


% *** Grab files

% EEG
pathEEG = eeg_source;
EEG_Content = getContent(eeg_source);
EEG_Content(~contains(EEG_Content, '.mat')) = [];
ART_Content = getContent(destination);
ART_Content(~contains(ART_Content, '.mat')) = [];
ART_Content = extractBefore(ART_Content, '_artndxn');
EEG_Cores = extractBefore(EEG_Content, '.mat');

EEG_Content(ismember(EEG_Cores, ART_Content)) = [];

if isempty(EEG_Content)
    error("You're done!")
end

nameEEG = EEG_Content(randi(numel(EEG_Content)));
  VIS = 0;
  nameVIS = 0;

  pathART = 0;
  nameART = 0;

nameMAN = 0;
pathMAN = 0;


% TODO, search for scoring, if present, use it.
% ### Load sleep scoring
% #########################
nameVISfolder = extractBefore(nameEEG, '_Cutting.mat'); % WANRING: LSM-specific
pathVIS = fullfile(scoring_source, nameVISfolder);
Content = getContent(pathVIS);
Content(~contains(Content, '.vis')) = [];
if any(contains(Content, '_rh'))
    nameVIS = Content(contains(Content, '_rh'));
elseif ~isempty(Content)
     nameVIS = Content(contains(Content, '.vis'));
else
    nameVIS = 0;
end


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

elseif endsWith(fileVIS, '.txt')
    % .txt files
    fid = fopen(fileVIS);
    visnum = textscan(fid, repmat('%s', 1, txtcols), 'HeaderLines', num_header);  % Load scoring file
    visnum = visnum{1, sleepcol};                                                 % Select column containing actual scoring
    fclose(fid);
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

    % Turn vector into cell of strings
    % (and yes that makes life complicated. but some people have their
    % scoring with letters ...)
    if ismatrix(visnum)
        visnum = cellfun(@num2str, num2cell(visnum), 'Uni', 0);
    end

    % recode sleep stages in visnum
    cellstages  = {N1,   N2,   N3,   N4,   W,   REM,  A};
    AASM        = {{-1}  {-2}  {-3}  {-4}  {1}  {0}   {1}};
    for istage = 1:numel(cellstages)
        ndx = cellfun(@(x) isequal(x, cellstages{istage}), visnum, 'Uni', 1);
        visnum(ndx) = AASM{istage};
    end

    % Sometimes last epoch codes "end", get rid of it
    if isstr(visnum{end}) & isnumeric([visnum{1:end-1}])
        visnum(end) = [];
    end

    % Turn to matrix
    visnum = cell2mat(visnum);

    % Recode stages
    stages_recode = stages;
    for istage = 1:numel(cellstages)
        ndx = cellfun(@(x) isequal(x, cellstages{istage}), stages_recode, 'Uni', 1);
        stages(ndx) = AASM{istage};
    end

    % Turn to matrix
    stages = cell2mat(stages);
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
if isempty(EEG.chanlocs)
    EEG.chanlocs = readlocs(fname_chanlocs);      % Channel locations;
end

EEG = eeg_checkset(EEG);

% if no scoring provide it, make it based on EEG
if isempty(visnum)
    % create blanks, so it cleans without scoring
    nEpochs = floor((size(EEG.data, 2)/EEG.srate)/scoringlen);
    visnum = nan(1, nEpochs);
    visgood = 1:nEpochs;
    stages_of_interest = 1:nEpochs;
    vissleep = 1:nEpochs;
end

if ~isempty(visgood)
    % In case manual artifact rejection was loaded in
    stages_of_interest = intersect(visgood, vissleep);
    % Clean sleep epochs
end

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
    artndxn         = [];
else
    % No file
    [~, outART]     = fileparts(nameEEG);        % Filename of output file
    outART          = [outART, '_artndxn.mat'];  % Append filename
    artndxn         = [];
end

outART = strjoin(outART, '');

% identify location to save output
switch destination
    case 'scoring'
        pathART = pathVIS;
    case 'eeg'
        pathART = pathEEG;
    case 'artifacts'
    otherwise
        pathART = destination;
        if ~exist(destination, 'dir')
            mkdir(destination)
        end
end

fprintf('** Artndxn will be saved here: %s\n', pathART)

% Evaluation plot name
namePLOT   = extractBefore(outART, '.');        % Filename of plot
namePLOT        = strjoin([namePLOT, '.png'], '');       % Filename of plot


% *** Convert to single to save space
visgood     = single(visgood);
visnum      = single(visnum);