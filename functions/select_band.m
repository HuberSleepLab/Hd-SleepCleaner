function SWA = select_band(FFTtot, freq, f1, f2, ndxSleep, artndxn, chansEXCL)

    % Select frequency band of interest
    SWA = FFTtot(:, freq >= f1 & freq <= f2, :);
    % SWA = squeeze(mean(SWA, 2));
    SWA = squeeze( sum(SWA, 2) * unique(diff(freq)));

    if ~isempty(ndxSleep)
        SWA(:, setdiff( 1:end, ndxSleep ))  = nan;
    end

    if ~isempty(artndxn)
        SWA(~artndxn) = nan;
    end

    % set muscle electrodes to nan
    %if size(SWA, 1) == 128
        SWA(chansEXCL, :) = nan;
    %end
end