function NewEEG = removeEyes(EEG)
% extra step that uses ICA to remove eye artifacts from data. A window pops
% up, asking the user to input the time window to use for identifying
% blinks with ICA.

EEG.data = double(EEG.data);

%%% manually select around a minute of clean data that includes blinks and
%%% other types of eye movement
Pix = get(0,'screensize');

% plot pre and post data
eegplot(EEG.data, 'spacing', 20, 'srate', EEG.srate, ...
    'winlength', 60, 'position', [0 0 Pix(3) Pix(4)*.97],  'eloc_file', EEG.chanlocs)

T = input('Identify around a minute of clean data with blinks: ');
close

%%% Run ICA

% only use selected time
shortEEG = pop_select(EEG, 'time', T);

% run fast ICA
shortEEG = pop_runica(shortEEG, 'fastica', 'approach', 'symm');


%%% use ICLabel to find eye artifacts
shortEEG = iclabel(shortEEG);

IC = shortEEG.etc.ic_classification.ICLabel.classifications;

% find all components where the eye category is the max
[~, MaxClass] = max(IC');
Eyes = MaxClass == 3;

shortEEG.reject.gcompreject = Eyes;


%%% merge data with component structure
NewEEG = shortEEG; % gets everything from IC structure
NewEEG.data = double(EEG.data); % replaces data
NewEEG.pnts = EEG.pnts; % replaces data related fields
NewEEG.srate = EEG.srate;
NewEEG.xmax = EEG.xmax;
NewEEG.times = EEG.times;
NewEEG.event = EEG.event;
NewEEG.icaact = [];

%%% remove components
NewEEG = pop_subcomp(NewEEG, find(Eyes));


% DEBUG and check output:
% pop_prop(shortEEG, 0, find(Eyes), gcbo, { 'freqrange', [1 40]});
