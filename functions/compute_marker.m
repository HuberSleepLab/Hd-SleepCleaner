function M = compute_marker(EEG, scoringlen, stages_of_interest, artndxn, chans_excl, varargin)

    % Optional input parameters
    %
    % reference         A vector containing vaules for each sample point
    %                   that will be subtracted from all EEG channels. This 
    %                   can serve as a new reference. If left empty, no
    %                   re-refering will be performed
    % L1, L2            Frequency limits of your first marker, which you
    %                   will screen based on robustly standardized EEG, as
    %                   well as on raw EEG data. In this routine we will
    %                   by default focus on slow-wave activity (0.5-4.5 Hz).
    % H1, H2            Frequency limits of your second marker, which you
    %                   will screen based on robustly standardized EEG. In
    %                   this routine we will by default focus on muscle 
    %                   power (20-30 Hz).
    
    % Input parser
    p = inputParser;
    addParameter(p, 'reference', [], @isnumeric)      
    addParameter(p, 'L1', 0.5, @isnumeric)     
    addParameter(p, 'L2', 4.5, @isnumeric)              
    addParameter(p, 'H1', 20, @isnumeric)              
    addParameter(p, 'H2', 30, @isnumeric)                
    parse(p, varargin{:});
    
    % Assign variables
    reference = p.Results.reference;
    L1 = p.Results.L1;
    L2 = p.Results.L2;
    H1 = p.Results.H1;
    H2 = p.Results.H2;    

    % Re-reference
    if ~isempty(reference)
        EEG.data = EEG.data - reference;
    end

    % Robust z-standardization of EEG
    fprintf('Robustly Z-Standardize EEG ...\n')
    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));

    % Compute PSD
    fprintf('Compute PSD ...\n')    
    [FFTtot, freq] = pwelchEPO(EEG.data, EEG.srate, scoringlen);

    % Compute PSD (Robustly z-standardized EEG)
    fprintf('Compute PSD (Robustly z-standardized EEG) ...\n')    
    [FFTtot_RZ, freq] = pwelchEPO(EEG_RZ, EEG.srate, scoringlen);        

    % Compute SWA
    SWA     = select_band(FFTtot, freq, L1, L2, stages_of_interest, artndxn, chans_excl);
    SWA_RZ  = select_band(FFTtot_RZ, freq, L1, L2, stages_of_interest, artndxn, chans_excl);    

    % Compute BETA
    BETA    = select_band(FFTtot, freq, H1, H2, stages_of_interest, artndxn, chans_excl);        
    BETA_RZ = select_band(FFTtot_RZ, freq, H1, H2, stages_of_interest, artndxn, chans_excl);    
    
    % How much channel deviate from mean
    devEEG = deviationEEG(EEG.data, EEG.srate, scoringlen, artndxn, chans_excl);

    % max raw voltage of each epoch/channel
    [voltEEG] = voltageEEG(EEG.data, EEG.srate, scoringlen, artndxn, chans_excl);

    % Assign to output structure
    M.FFTtot    = single(FFTtot);
    M.FFTtot_RZ = single(FFTtot_RZ);
    M.SWA       = single(SWA);
    M.SWA_RZ    = single(SWA_RZ);
    M.BETA      = single(BETA);
    M.BETA_RZ   = single(BETA_RZ);
    M.devEEG    = single(devEEG);
    M.voltEEG   = single(voltEEG);
    M.freq      = single(freq);
    M.L1        = single(L1);    
    M.L2        = single(L2);    
    M.H1        = single(H1);    
    M.H2        = single(H2);    
    

end