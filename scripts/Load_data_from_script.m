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


% ### Load sleep scoring
% #########################

% *** Load sleep scoring
if isscoring
    fileVIS = dir(fullfile(SCORINDDIR, VIS_FILE_PATTERN));
    nameVIS = {fileVIS.name};
    if isempty(nameVIS)
        disp('No files found.')
        disp('Check your study folder and file pattern in configuration file.')
        visnum = [];  % No sleep scoring
    end
    
    if length(nameVIS) == 1
        idxVIS = 1;
    elseif length(nameVIS) > 1
        %find the vis file matching EEG input file
        idxVIS = startswith(nameVIS, filename);
    end
    
    if endsWith(nameVIS, '.mat')
        % .mat files
        visnum = load(fullfile(files(idxVIS).folder, files(idxVIS).name));                  % Load sleep scoring
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
        
    elseif endsWith(nameVIS, '.vis')
        % .vis files
        [vistrack, vissymb, offs] = visfun.readtrac(fullfile(files(idxVIS).folder, files(idxVIS).name), 1);     % Load manual artifact rejection
        visnum                    = visfun.numvis(vissymb, offs);    % Load sleep scoring
        fprintf('** Load %s\n', nameVIS)
        
    elseif endsWith(nameVIS, '.txt')
        % .txt files
        fid = fopen(fullfile(files(idxVIS).folder, files(idxVIS).name));
        visnum = textscan(fid, repmat('%s', 1, txtcols), 'HeaderLines', num_header);  % Load scoring file
        visnum = visnum{1, sleepcol};                                                 % Select column containing actual scoring
        fclose(fid);
    end
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
if isartman
    fileARTMAN = dir(fullfile(savefolder, ARTMAN_FILE_PATTERN));
    nameARTMAN = {fileARTMAN.name};
    if isempty(nameARTMAN)
        disp('No files found.')
        disp('Check your study folder and file pattern in configuration file.')
        visgood = [];  % No cleaned epochs
    end
    
    if length(nameARTMAN) == 1
        idxARTMAN = 1;
    elseif length(nameARTMAN) > 1
        %find the file matching EEG input file
        idxARTMAN = startswith(nameART, filename);
    end
    
    if endsWith(nameARTMAN, '.mat')
        % .mat file
        visgood = load(fullfile(fileARTMAN(idxARTMAN).name,fileARTMAN(idxARTMAN).folder));                  % Load manual artifact rejection
        if isstruct(visgood)
            if numel(fieldnames(visgood)) == 1
                fn_visgood  = fieldnames(visgood);    % Fieldnames of structure
                visgood     = visgood.(fn_visgood{1});% Access first subfield
            end
        end
        fprintf('** Load %s\n', nameMAN)
    elseif endsWith(nameARTMAN, '.vis')
        %. vis file
        visgood = find(sum(vistrack') == manual); % Manual artifact detection
    else
        visgood = [];   % No manual artifact detection
    end
else
    visgood = [];
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
if isartdxn
    fileART = dir(fullfile(files(iFile).folder, ARTDXN_FILE_PATTERN));
    nameART = {fileART.name};
    if isempty(nameART)
        disp('No files found.')
        disp('Check your study folder and file pattern in configuration file.')
        artdxn = [];  % No cleaned epochs
    end
    
    if length(nameART) == 1
        idxART = 1;
    elseif length(nameART) > 1
        %find the file matching EEG input file
        idxART = startswith(nameART, filename);
    end
    
    if endsWith(nameART, '.mat')
        % .mat file
        load(fullfile(fileART(idxART).name,fileART(idxART).folder), 'artndxn');                    % Load artifact rejection
        fprintf('** Load %s\n', nameART)
        outART          = nameART;                   % Filename of output file
    elseif isstr(nameVIS)
        % Sleep scoring exists
        [~, outART]     = fileparts(nameVIS);        % Filename of output file
        outART          = [outART, '_artndxn.mat'];  % Append filename
        artndxn         = [];
    end
    
else
    % No file
    %[~, outART]     = fileparts(filename);        % Filename of output file
    outART          = filename;
    outART          = [outART, '_artndxn.mat'];  % Append filename
    artndxn         = [];
end

% identify location to save output
switch destination
    case 'scoring'
        pathART = SCORINGDIR;
    case 'eeg'
        pathART = files(iFile).folder;
    case 'artndxn'
    otherwise
        pathART = destination;
        if ~exist(destination, 'dir')
            mkdir(destination)
        end
end



fprintf('** Artndxn will be saved here: %s\n', pathART)    

% Evaluation plot name
[~, namePLOT]   = fileparts(outART);        % Filename of plot  
namePLOT        = [namePLOT, '.png'];       % Filename of plot  

% *** Convert to single to save space
visgood     = single(visgood);
visnum      = single(visnum);