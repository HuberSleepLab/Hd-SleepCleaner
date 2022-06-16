function SWA = select_band(FFTtot, freq, f1, f2, ndxSleep, artndxn, chansEXCL)

    % Select frequency band of interest
    SWA = FFTtot(:, freq >= f1 & freq <= f2, :);
    % SWA = squeeze(mean(SWA, 2));
    SWA = squeeze( sum(SWA, 2) * unique(diff(freq)));

    % One channel only
    if ~isrow(SWA) & size(SWA, 2) == 1
        SWA = SWA';
    end

    if ~isempty(ndxSleep)
        SWA(:, setdiff( 1:end, ndxSleep ))  = nan;
    end

    if ~isempty(artndxn)
        SWA(~artndxn) = nan;
    end

    % Set excluded electrodes to NaN
    for chEXCL = chansEXCL
        if chEXCL <= size(SWA, 1)
            % Only set to nan when included in matrix
            SWA(chEXCL, :) = nan;
        end
    end
end