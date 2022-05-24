% Configuration file for "Call_OutlierGUI".
%
% Change variables and paths in this script to your desired settings.
% Thereafter, call the script "Call_OutlierGUI".
%
% Date: 20.05.2022
%
% *************************************************************************

% *** General
chansID    = 1:128;     % The EEG data loaded in will be stored in a 
                        % matrix (channels x samples). Define here which
                        % channels you want to perform the artifact
                        % rejection on (the rows in your matrix). The 
                        % number of chosen channels will also determine the
                        % size of your output matrix (number of channels =
                        % number of rows).
chans_excl  = [107 113 127 128];
                        % It makes sense to have an output matrix of the
                        % same size as your EEG data matrix. However, you
                        % can still have channels you want to exclude from
                        % artifact rejection, because they do not capture
                        % brain activity, such as EMG electrodes.
                        % Specifying them here will classify them
                        % automatically as "bad", so that all epochs are
                        % labeled as "bad" = 0. They will not appear in the
                        % artifact removal procedure.

% *** Sleep Scoring
scoringlen = 20;        % The artifact rejection works on epoched data. 
                        % Define here how long those data segments should
                        % be. Usually it makes sense to choose the same
                        % epoch length as during sleep scoring (in case you
                        % have performed sleep scoring). Otherwise the
                        % length of epochs is customizable. Beware though
                        % that spectral power will be computed in 4s
                        % snippets within one epoch with 50% epoch, so
                        % preferably choose an even number greater than 4s.
N1         = -1;        % Non-rem sleep 1
N2         = -2;        % Non-rem sleep 2
N3         = -3;        % Non-rem sleep 3
N4         = -4;        % Non-rem sleep 4 (outdated)
REM        =  0;        % Rem sleep
W          =  1;        % Wake
stages     = [N1, N2, N3, N4];  
                        % In case you load in your sleep scoring file, the
                        % artifact rejectino routine will only be performed
                        % in epochs belonging to those sleep stages. All
                        % other epochs will be classified as "bad" = 0
                        % automatically. This can be useful in case you
                        % want to perform your analysis specific to certain
                        % sleep stages, e. g. NREM sleep.

% *** Manual artifact rejection
manual     = 0;         % In case you have identified artifacts in advance
                        % in one or few channels, e.g. during sleep
                        % scoring, you can load in another file that stores
                        % this information. This file needs to be a vector
                        % of two numbers. Define here which number
                        % corresponds to clean epochs. Only those epochs
                        % will be taken into account for the artifact
                        % rejection. All other epochs will be classified as
                        % "bad" = 0.

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