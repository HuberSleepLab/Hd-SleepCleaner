function [] = check_srate(srate1, srate2, is_preprocessing)

% *** EXPLANATION
% This function checks whether the sampling rate high enough to estimate 
% beta power reliably.
%
% INPUT
% srate1: sampling rate of the imported EEG structure
% srate2: sampling rate after down-sampling
% is_preprocessing: toggle determining whether data goes through
%                   preprocessing pipeline

% *** Start function
% Original sampling rate too low
if srate1 < 60
    prompt = sprintf(...
        [ ...
        'The EEG has a sampling rate of %.2f Hz. This is lower than 60 Hz.' ...
        '\n\nAre you certain that the sampling rate is high enough to accurately estimate beta power (20-30 Hz)?' ...
        ], srate1);
    srate_response = questdlg(prompt,'Sampling rate too low','Yes','No','No');
    switch srate_response
        case 'No'
            error('Please import EEG data with a sampling rate of at least 60 Hz.')
    end
end

% Down-sampling rate
if srate2 < 60 & is_preprocessing
    prompt = sprintf(...
        [ ...
        'EEG will be re-sampled from %.2f Hz to %.2f Hz. This is lower than 60 Hz.' ...
        '\n\nAre you certain that the sampling rate is high enough to accurately estimate beta power (20-30 Hz)?' ...
        ], srate1, srate2);
    srate_response = questdlg(prompt,'Sampling rate too low','Yes','No','No');
    switch srate_response
        case 'No'
            error('Please increase the sampling rate in "Configuration_OutlierGUI.m" to at least 60 Hz.')
    end
end

end