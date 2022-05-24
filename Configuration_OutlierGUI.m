% Configuration file for "Call_OutlierGUI".
%
% Change variables and paths in this script to your desired settings.
% Thereafter, call the script "Call_OutlierGUI".
%
% Date: 20.05.2022
%
% *************************************************************************

% *** General
chansID    = 1:128;     % Channels you want to perform artifact detection on.
                        % This also determines the size of your output
                        % matrix (the number of rows = channels).
chans_excl  = [107 113 127 128];
                        % Channels that are automatically set to "bad
                        % channels" in your output matrix, meaning that all
                        % epochs are labels as bad. They will not be
                        % included during the artifact removal procedure to
                        % save time, e. g. EMG electrodes.

% *** Sleep Scoring
scoringlen = 20;        % Epoch length of sleep scoring (in sec). If no 
                        % scoring was performed, this will determine the
                        % epoch length during artifact rejection anyway.
N1         = -1;        % Non-rem sleep 1
N2         = -2;        % Non-rem sleep 2
N3         = -3;        % Non-rem sleep 3
N4         = -4;        % Non-rem sleep 4 (outdated)
REM        =  0;        % Rem sleep
W          =  1;        % Wake
stages     = [N1, N2, N3, N4];  
                        % Epochs must belong to those sleep stages, 
                        % otherwise they will be classified as artifacts
                        % automatically. In case no sleep scoring is loaded,
                        % this will be ignored. Your sleep scoring must have
                        % the same epoch length you want to perform the
                        % artifact rejection on.

% *** Manual artifact rejection
manual     = 0;         % Your manual artifact rejection input should be a 
                        % vector of equal length you want to perform the
                        % artifact rejection on. Define here which value
                        % defines that epochs were clean. Will be ignored if
                        % no manual artifact rejection is loaded in.

% *** Frequency limits
L1 = 0.5;               % Lower band: lower limit
                        % During the routine you will screen epochs based 
                        % on spectral power in certain frequency ranges. The
                        % lower frequency range will be screened based on
                        % raw EEG, as well as robustly standardized EEG.
                        % The higher frequency range will be screened only
                        % on robustly standardized EEG.
L2 = 4.5;               % Lower band: upper limit
H1 = 20;                % Higher band: lower limit
H2 = 30;                % Higher band: upper limit


% *** Filenames
fname_chanlocs = 'test129.loc'; % File storing channel locations.
                                % The repository uses the location
                                % of a 129 channel EGI net.

% *** EEGLAB path
pname_eeglab = 'C:\PhDScripts\EEGlab2021.1';
                      % Path to EEGLAB toolbox. This is a free toolbox 
                      % functions of which are used in this GUI. Can be 
                      % downloaded here: https://eeglab.org/download/
addpath(pname_eeglab);% Add EEGLAB to paths


% *** Add helper functions
addpath(genpath(fullfile(pmain, 'chanlocs')));   % Path to channel locations
addpath(genpath(fullfile(pmain, 'colormap')));   % Path to colormap
addpath(genpath(fullfile(pmain, 'functions')));  % Path to functions     
addpath(genpath(fullfile(pmain, 'scripts')));    % Path to scripts                                        