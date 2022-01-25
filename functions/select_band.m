function SWA = select_band(FFTtot, freq, f1, f2, ndxSleep)

    % Select frequency band of interest
    SWA = FFTtot(:, freq >= f1 & freq <= f2, :);
    SWA = squeeze(mean(SWA, 2));
    SWA(:, setdiff( 1:end, ndxSleep ))  = nan;

end