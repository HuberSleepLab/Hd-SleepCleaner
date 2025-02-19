function artndxn = outlier_routine(EEG, M, artndxn, visnum, T1, T2, T3, varargin)


    % Input parser
    p = inputParser;
    addParameter(p, 'scoringlen', 20, @isnumeric)        
    addParameter(p, 'stages_of_interest', [])    
    addParameter(p, 'chans_excl', [107 113 126 127], @isnumeric)        
    addParameter(p, 'altern_ref', [49 56], @isnumeric)        

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
    altern_ref = p.Results.altern_ref;          % Alternative reference 
                                                % channels used in the GUI                                               
                                                
    % Robust z-standardization of EEG
    fprintf('Preparing GUI ...\n')
    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));


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
    fprintf('** 1|4: Robustly Z-Standardized SWA ...\n')
    [ manoutSWA ] = OutlierGUI(M.SWA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', M.SWA_RZ, ...
        'spectrum', M.FFTtot_RZ, ...
        'epo_select', stages_of_interest, ...
        'main_title', sprintf('Power (%.1f - %.1f Hz) from robustly Z-Standardized EEG', M.L1, M.L2), ...
        'amp_ylabel', 'Amplitude (z-value)', ...
        'main_ylabel', 'Power (n. a.)', ...                
        'epo_len', scoringlen, ...
        'epo_thresh', T1, ...
        'altern_ref', altern_ref);
    
    % Set artifacts to NaN
    M.SWA( isnan(manoutSWA.cleanVALUES) )     = nan;    
    M.BETA( isnan(manoutSWA.cleanVALUES) )    = nan;    
    M.BETA_RZ( isnan(manoutSWA.cleanVALUES) ) = nan;
    M.SWA_RZ(  isnan(manoutSWA.cleanVALUES) ) = nan;
    
    % *** BETA         
    fprintf('** 2|4: Robustly Z-Standardized BETA ...\n')    
    [ manoutBETA ] = OutlierGUI(M.BETA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', M.BETA_RZ, ...
        'spectrum', M.FFTtot_RZ, ...
        'epo_select', stages_of_interest, ...        
        'main_title', sprintf('Power (%.1f - %.1f Hz) from robustly Z-Standardized EEG', M.H1, M.H2), ...
        'amp_ylabel', 'Amplitude (z-value)', ...    
        'main_ylabel', 'Power (n. a.)', ...                
        'epo_len', scoringlen, ...        
        'epo_thresh', T2, ...
        'altern_ref', altern_ref);
    
    % Set artifacts to NaN
    M.devEEG( isnan(manoutBETA.cleanVALUES) )  = nan;
    M.BETA_RZ( isnan(manoutBETA.cleanVALUES) ) = nan;
    M.SWA_RZ( isnan(manoutBETA.cleanVALUES) )  = nan;
    M.SWA( isnan(manoutSWA.cleanVALUES) )      = nan;        
    
    % *** Deviation
    fprintf('** 3|4: Deviation from average EEG Signal ...\n')            
    [ manoutEEG ] = OutlierGUI(M.devEEG, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', M.devEEG, ...
        'spectrum', M.FFTtot, ...
        'epo_select', stages_of_interest, ...   
        'main_title', 'Deviation from average EEG Signal ', ...
        'amp_ylabel', 'Amplitude (\muV)', ...        
        'main_ylabel', 'Amplitude (\muV)', ...        
        'epo_len', scoringlen, ...           
        'epo_thresh', T3, ...
        'altern_ref', altern_ref);

    % Set artifacts to NaN
    M.devEEG( isnan(manoutEEG.cleanVALUES) )   = nan;
    M.BETA_RZ( isnan(manoutEEG.cleanVALUES) )  = nan;
    M.SWA( isnan(manoutEEG.cleanVALUES) )      = nan;  
    M.SWA_RZ( isnan(manoutEEG.cleanVALUES) )   = nan;        

    % *** Raw SWA
    fprintf('** 4|4: Raw SWA ...\n ')
    [ manoutSWA_RAW ] = OutlierGUI(M.SWA, ...
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
        'epo_thresh', T1, ...
        'altern_ref', altern_ref);  

    % *** artndxn
    artndxn = ~isnan(manoutSWA_RAW.cleanVALUES);

end