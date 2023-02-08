function artndxn = outlier_routine(EEG, M, artndxn, visnum, T1, T2, T3, varargin)


    % Input parser
    p = inputParser;
    addParameter(p, 'scoringlen', 20, @isnumeric)        
    addParameter(p, 'stages_of_interest', [])    
    addParameter(p, 'chans_excl', [107 113 126 127], @isnumeric)        

    parse(p, varargin{:});
    
    % Assign variables
    scoringlen = p.Results.scoringlen;          % Length of epochs used for 
                                                % sleep scoring (in s)
    stages_of_interest = p.Results.stages_of_interest;          
                                                % Epochs corresponding to
                                                % sleep stages of interest.
                                                % If manual artifact
                                                % rejection has been loaded
                                                % in, only clean epochs
                                                % corresponding to those
                                                % sleep stages.
    chans_excl = p.Results.chans_excl;          % Those channels will be 
                                                % set to 0 automatically
                                                
    % Robust z-standardization of EEG
    fprintf('Preparing GUI ...\n')
%    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));


      % *** SWA
%     % The GUI gets slow when too many epochs are rejected in one go.
%     % Uncomment this part to do the artifact rejection on robustly
%     % z-standardized SWA twice to ease computation load.
%     fprintf('** 0|4: Robustly Z-Standardized SWA ...\n')
%     [ manoutSWA_RAW0 ] = OutlierGUI(M.SWA_RZ, ...
%         'sleep', visnum, ...
%         'EEG', EEG_RZ, ...
%         'srate', EEG.srate, ...
%         'chanlocs', EEG.chanlocs, ...
%         'topo', M.SWA, ...
%         'spectrum', M.FFTtot_RZ, ...
%         'epo_select', stages_of_interest, ...
%         'epo_thresh', T1);     
% 
%     % Set artifacts to NaN
%     M.SWA_RZ(  isnan(manoutSWA_RAW0.cleanVALUES) ) = nan;      

    % *** SWA
    fprintf('** 1|2: Raw SWA ...\n')
    [ manoutSWA ] = OutlierGUI(M.SWA, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', M.SWA, ...
        'spectrum', M.FFTtot, ...
        'epo_select', stages_of_interest, ...
        'main_title', sprintf('Power (%.1f - %.1f Hz) from raw EEG', M.L1, M.L2), ...
        'amp_ylabel', 'Amplitude (\muV)', ...
        'main_ylabel', 'Power (\muV^2)', ...                
        'epo_len', scoringlen, ...
        'epo_thresh', T1);
    
    % Set artifacts to NaN
    M.SWA( isnan(manoutSWA.cleanVALUES) )     = nan;    
    M.BETA( isnan(manoutSWA.cleanVALUES) )    = nan;    
    
    % *** BETA         
    fprintf('** 2|2: Raw BETA ...\n')    
    [ manoutBETA ] = OutlierGUI(M.BETA, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', M.BETA, ...
        'spectrum', M.FFTtot, ...
        'epo_select', stages_of_interest, ...        
        'main_title', sprintf('Power (%.1f - %.1f Hz) from raw EEG', M.H1, M.H2), ...
        'amp_ylabel', 'Amplitude (\muV)', ...    
        'main_ylabel', 'Power (\muV^2)', ...                
        'epo_len', scoringlen, ...        
        'epo_thresh', T2);
    


    % *** artndxn
    artndxn = ~isnan(manoutBETA.cleanVALUES);

end