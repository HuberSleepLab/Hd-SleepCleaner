function [voltEEG] = voltageEEG(EEG, srate, winlen, artndxn, chans_excl)

    [nCh, nPnts] = size(EEG);                           % sample points
    nEpochs      = floor(nPnts/srate/winlen);
    voltEEG       = zeros(nCh, nEpochs);
    
    % Identify infinity values and replace values
    % Otherwise pwelch won't work
    infchans = find(any(isinf(EEG), 2));
    if ~isempty(infchans)
        fprintf('Channels %g have a 0 line', infchans)
        EEG(infchans, :) = nan;
    end
    
    for epo = 1:nEpochs
        XT              = epo * winlen * srate + 1 - winlen*srate : epo * winlen * srate;     
        voltEEG(:, epo)  = max(abs(EEG(:, XT)), [], 2);
    end
    
    if ~isempty(artndxn)
        voltEEG(~artndxn) = nan;
    end


    % set to nan all channels to exclude
    voltEEG(chans_excl, :) = nan;

end