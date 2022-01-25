function [devEEG] = deviationEEG(EEG, srate, winlen)

nPnts     = size(EEG,2);                            % sample points
nEpo20    = floor(nPnts/srate/winlen);              % number of 20s epochs
devEEG    = [];

for epo = 1:floor(nPnts/srate/winlen)
    XT              = epo * winlen * srate + 1 - winlen*srate : epo * winlen * srate;         
    devEEG(:, epo)  = max( abs( EEG(:, XT) - mean(EEG(:, XT)) ).^2, [], 2);   
end

end