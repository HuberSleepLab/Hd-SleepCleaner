function [EEG] = prep_avgref(EEG, srate, chansID, winlen, artndxn)

% define variables and pre-allocate
nChan     = size(EEG,1);                            % channels
nPnts     = size(EEG,2);                            % sample points
nEpo20    = floor(nPnts/srate/winlen);              % number of 20s epochs

% Original EEG
EEG0 = EEG;

% power computation
fprintf('\n Average referencing ...\n')
wb = waitbar(0, 'Prepare average reference ...');
for epo = 1:nEpo20

    % sample points in each 20s window
    from              = (epo-1)*winlen*srate+1;
    to                = (epo-1)*winlen*srate+winlen*srate;

    % Set artifacts to nan
    EEG( ~artndxn(:, epo), from:to ) = nan;

    % update waitbar
    waitbar(epo/(nEpo20*2), wb, sprintf('Prepare average reference ... epoch %d/%d', epo, nEpo20*2));

end  

% Average reference
chansAVG = setdiff(chansID, [49 56 107 113, 125, 126, 127, 128, 48, 119, 43, 63, 68, 73, 81, 88, 94, 99, 120]);
EEG      = EEG - mean(EEG(chansAVG, :), 1, 'omitnan');

% Insert values again
for epo = 1:nEpo20

    % sample points in each 20s window
    from              = (epo-1)*winlen*srate+1;
    to                = (epo-1)*winlen*srate+winlen*srate;

    % Set artifacts to nan
    EEG( ~artndxn(:, epo), from:to ) = EEG0( ~artndxn(:, epo), from:to );

    % update waitbar
    waitbar((epo+nEpo20)/(nEpo20*2), wb, sprintf('Prepare average reference ... epoch %d/%d', epo+nEpo20, nEpo20*2));

end  
close(wb); % close waitbar

end