function [devEEG] = deviationEEG(EEG, srate, winlen)

nPnts     = size(EEG,2);                            % sample points
nEpo20    = floor(nPnts/srate/winlen);              % number of 20s epochs
devEEG    = [];

% Identify infinity values and replace values
% Otherwise pwelch won't work
infchans = find(any(isinf(EEG), 2));
if ~isempty(infchans)
    fprintf('Channels %g have a 0 line', infchans)
    EEG(infchans, :) = nan;
end


for epo = 1:floor(nPnts/srate/winlen)
    XT              = epo * winlen * srate + 1 - winlen*srate : epo * winlen * srate;         
    devEEG(:, epo)  = max( abs( EEG(:, XT) - mean(EEG(:, XT), 'omitnan') ).^2, [], 2);   
end

end