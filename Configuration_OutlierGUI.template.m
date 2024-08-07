% Configuration file for "Call_OutlierGUI".
% Make a local copy renaming the file as Configuration_OutlierGUI.m
% and adapt it acording to your personal desired settings (Note, the 
% Configuration_OutlierGUI.m file is not trackt on GitHub)
% Thereafter, call the script "Call_OutlierGUI".
%
% *************************************************************************

% *** General
chansID    = 1:128;      % The EEG data loaded in will be stored in a 
                        % matrix (channels x samples). Define here which
                        % channels you want to perform the artifact
                        % rejection on (the rows in your matrix). The 
                        % number of chosen channels will also determine the
                        % size of your output matrix (number of channels =
                        % number of rows).
chans_excl  = [107 113];       % It makes sense to have an output matrix of the
                        % same size as your EEG data matrix. However, you
                        % can still have channels you want to exclude from
                        % artifact rejection, because they do not capture
                        % brain activity, such as EMG electrodes.
                        % Specifying them here will classify them
                        % automatically as "bad", so that all epochs are
                        % labeled as "bad" = 0. They will not appear in the
                        % artifact removal procedure.
altern_ref = [49 56];   % Alternative reference. With a button press in the
                        % GUI, the EEG data can be re-referenced to these
                        % channels. If several channels are indicated, the
                        % EEG will be referenced to the mean of these 
                        % channels. Only the visualization of the raw EEG
                        % traces is affected by this.
chansAvgRef = setdiff(chansID, [49 56 107 113, 125, 126, 127, 128, 48, 119, 43, 63, 68, 73, 81, 88, 94, 99, 120]); 
                       % Channels used for computing the average reference. 
% Depending on your electrode setup, it may be sensible to exclude specific 
% channels that for example record EMG rather than EEG. Channels prone to artifacts 
% can also be excluded to prevent them from influencing the average reference.

                        

% *** Sleep Scoring
scoringlen = 30;        % The length of sleep scored epochs. This variable 
                        % will only be used when a sleep scoring file is
                        % provided.
epolen = 30;            % The artifact rejection works on epoched data. 
                        % Define here how long those data segments should
                        % be. Usually it makes sense to choose the same
                        % epoch length as during sleep scoring (in case you
                        % have performed sleep scoring). Otherwise the
                        % length of epochs is customizable. Beware though
                        % that spectral power will be computed in 4s
                        % snippets within one epoch with 50% epoch, so
                        % preferably choose an even number greater than 4s. 
                        % Also, the epoch length should be an even fraction
                        % of the length of sleep scored epochs 
                        % (good: e.g.: 30 s --> 30 s; or 30 s --> 10 s)
                        % (bad: e.g.: 30 s --> 7 s)                        
N1         = '-1';      % Non-rem sleep 1
N2         = '-2';      % Non-rem sleep 2
N3         = '-3';      % Non-rem sleep 3
N4         = '-4';      % Non-rem sleep 4 (outdated)
REM        =  '0';      % Rem sleep
W          =  '1';      % Wake
A          =  'A';      % Artifacts (some labs score epochs with artifacts 
                        % with a distinct label, indicate it here. Other
                        % labs score those epochs with the respective sleep
                        % stage, then ignore this value.
stages     = {N1, N2, N3};
                        % In case you load in your sleep scoring file, the
                        % artifact rejectino routine will only be performed
                        % in epochs belonging to those sleep stages. All
                        % other epochs will be classified as "bad" = 0
                        % automatically. This can be useful in case you
                        % want to perform your analysis specific to certain
                        % sleep stages, e. g. NREM sleep.
txtcols = 2;            % Only for when your scoring file is stored as a 
                        % .txt file: to correctly load your scoring, please
                        % indicate how many columns your .txt files has.
                        % 1: one column, 2: two columns ...
sleepcol = 2;           % Only for when your scoring file is stored as a 
                        % .txt file: please indicate which column stores 
                        % the actual sleep scoring. 
num_header = 0;         % Only for when your scoring file is stored as a 
                        % .txt file: in case your file has a header,
                        % meaning that the first X rows are column names or
                        % contain other explanations, indicate how many
                        % header lines your file contains. Those will be
                        % skipped when loading in your scoring file.
lookup_eeg = 'I:\Sara\Studies\EPISL\Pilot\Data\Scoring\scoring\test';        % Define folder to which Matlab points to by 
                        % default when displaying the pop-up to load in the
                        % EEG data. In case it stays empty, it points to
                        % the "example_data" folder of the repository.
lookup_scoring = 'I:\Sara\Studies\EPISL\Pilot\Data\Scoring\scoring\test';    % Same for sleep scoring file.         
lookup_artndxn = '';    % Same for sartifact rejection file.                        


% *** Manual artifact rejection
manual = [1];            % In case you have identified artifacts in advance
                        % in one or few channels, e.g. during sleep
                        % scoring, you can load in another file that stores
                        % this information. This file needs to be a vector
                        % of two numbers. Define here which number
                        % corresponds to clean epochs. Only those epochs
                        % will be taken into account for the artifact
                        % rejection. All other epochs will be classified as
                        % "bad". In case you leave it empty, no manual
                        % artifact rejection will be imported.

% *** Frequency limits for spectral power computation
L1 = 0.5;               % Lower band: lower limit
L2 = 4.5;               % Lower band: upper limit
H1 = 20;                % Higher band: lower limit
H2 = 30;                % Higher band: upper limit
                        % During the routine you will screen epochs based 
                        % on spectral power in certain frequency ranges. The
                        % lower frequency range will be screened based on
                        % raw EEG, as well as robustly standardized EEG.
                        % The higher frequency range will be screened only
                        % on robustly standardized EEG.


% *** Preprocessing
is_preprocessing = 0;   % Toggle whether you want to preprocess your EEG 
                        % before artifact correction. This low- and
                        % high-pass filters your data (pass-band: 0.5 - 30 
                        % Hz) and down-samples it to a lower sampling rate. 
                        % Yes: 1, No: 0.
srate_down = 125;       % Down-sample EEG to this sampling rate. Will only
                        % be considered when is_preprocessing = 1.
is_sweat = 0;           % Toggle whether you want to apply a stricter high-
                        % pass filter to handle sweat artifacts. Sometimes
                        % sleep EEG is full of sweat artifacts and many
                        % epochs would be rejected due to high-amplitude,
                        % low-frequency sinusoidal waves. The higher
                        % cut-off removes frequencies until 0.9 Hz. 
                        % Yes: 1, No: 0.


% *** Filenames
fname_chanlocs = 'locs128.loc'; % File storing channel locations.
                                % The repository uses the location
                                % of a 129 channel EGI net.

% *** EEGLAB path
pname_eeglab = 'D:\Sara\Matlab\backup_Git\GitHub\toolboxes\eeglab_current\eeglab2021.1';
                        % Path to EEGLAB toolbox. This is a free toolbox 
                        % functions of which are used in this GUI. Can be 
                        % downloaded here: https://eeglab.org/download/
addpath(pname_eeglab);  % Add EEGLAB to paths

% *** Output path
destination = 'eeg';    % Specify where you want the final output saved. 
                        % You can either choose one of the following
                        % options or give a specific filepath. A filepath
                        % example would be 'C:\PhDScripts\SleepEEG\'.
                        % Options are:
                        % 'eeg':        same folder as EEG data                        
                        % 'scoring':    same folder as sleep scoring
                        % 'artndxn':    same folder as artndxn
                        % Any other string will be interpreted as a
                        % filepath.


% *** Add helper functions
addpath(genpath(fullfile(pmain, 'chanlocs')));   % Path to channel locations
addpath(genpath(fullfile(pmain, 'colormap')));   % Path to colormap
addpath(genpath(fullfile(pmain, 'functions')));  % Path to functions     
addpath(genpath(fullfile(pmain, 'scripts')));    % Path to scripts                                        