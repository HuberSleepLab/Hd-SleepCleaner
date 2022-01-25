function [FFTtot, freq] = pwelchEPO(EEG, srate, winlen)

% define variables and pre-allocate
nChan     = size(EEG,1);                            % chanenls
nPnts     = size(EEG,2);                            % sample points
nEpo20    = floor(nPnts/srate/winlen);              % number of 20s epochs
FFTtot    = double(NaN(nChan, 161, nEpo20));   % stores final power values
FFTepoch  = double([]);                             % stores power values per 20s epoch 

% power computation
wb = waitbar(0, 'Compute power ...');
for epo = 1:nEpo20

    % sample points in each 20s window
    from              = (epo-1)*winlen*srate+1;
    to                = (epo-1)*winlen*srate+winlen*srate;

    % pwelch
    [FFTepoch, freq] = pwelch(EEG(:, from:to)', hanning(4*srate), 0, 4*srate, srate);
    FFTepoch         = FFTepoch'; % to get channel x frequency

    % frequencies of interest
    freq40 = freq <= 40; 

    % concatenate 20s epochs
    FFTtot(:, :, epo) = FFTepoch(:, freq40); % in channel x frequency x epoch

    % update waitbar
    waitbar(epo/nEpo20, wb, sprintf('Compute power ... epoch %d/%d', epo, nEpo20));

end  
close(wb); % close waitbar

end