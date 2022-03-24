function [artndxn] = outlier_routine(EEG, artndxn, ndxsleep, visnum, T1, T2, T3, varargin)


    % Input parser
    p = inputParser;
    addParameter(p, 'scoringlen', 20, @isnumeric)     % Length of epochs used for sleep scoring (in s)
    parse(p, varargin{:});
    
    % Assign variables
    scoringlen = p.Results.scoringlen;    

    
    % ********************
    %  Compute variables
    % ********************   

    % Robust z-standardization of EEG
    fprintf('Robustly Z-Standardize EEG ...\n')
    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));

    % Compute PSD
    fprintf('Compute PSD ...\n')    
    [FFTtot, freq] = pwelchEPO(EEG.data, EEG.srate, scoringlen);

    % Compute PSD (Robustly z-standardizef EEG)
    fprintf('Compute PSD (Robustly z-standardized EEG) ...\n')    
    [FFTtot_RZ, freq] = pwelchEPO(EEG_RZ, EEG.srate, scoringlen);    
    
    % Only show NREM epochs
    NREM = find( ismember( visnum, [-1 -2 -3] ));   

    % Compute SWA
    SWA     = select_band(FFTtot, freq, 0.5, 4.5, ndxsleep, artndxn);
    SWA_RZ  = select_band(FFTtot_RZ, freq, 0.5, 4.5, ndxsleep, artndxn);    

    % Compute BETA
    BETA_RZ = select_band(FFTtot_RZ, freq, 20, 30, ndxsleep, artndxn);    
    
    % How much channel deviate from mean
    devEEG = deviationEEG(EEG.data, EEG.srate, scoringlen, artndxn);    


%     % ********************
%     %         SWA 
%     % ******************** 
% 
%     % Manual artifact rejection
%     % The GUI gets slow when too many epochs are rejected in one go.
%     % Uncomment this part to do the artifact rejection on robustly
%     % z-standardized SWA twice to ease computation load.
%     fprintf('** 0|4: Robustly Z-Standardized SWA ...\n')
%     [ manoutSWA_RAW0 ] = OutlierGUI(SWA_RZ, ...
%         'sleep', visnum, ...
%         'EEG', EEG_RZ, ...
%         'srate', EEG.srate, ...
%         'chanlocs', EEG.chanlocs, ...
%         'topo', SWA, ...
%         'spectrum', FFTtot_RZ, ...
%         'epo_select', NREM, ...
%         'epo_thresh', T1);     
% 
%     % Set artifacts to NaN
%     SWA_RZ(  isnan(manoutSWA_RAW0.cleanVALUES) ) = nan;      


    % ********************
    %         SWA 
    % ********************     
        
    % Manual artifact rejection
    fprintf('** 1|4: Robustly Z-Standardized SWA ...\n')
    [ manoutSWA ] = OutlierGUI(SWA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot_RZ, ...
        'epo_select', NREM, ...
        'main_title', 'Robustly Z-Standardized SWA ', ...
        'epo_len', scoringlen, ...
        'epo_thresh', T1);
    
    
    % ********************
    %         BETA 
    % ********************
        
    % Set artifacts to NaN
    BETA_RZ( isnan(manoutSWA.cleanVALUES) ) = nan;
    SWA_RZ(  isnan(manoutSWA.cleanVALUES) ) = nan;
    
    % Manual artifact rejection
    fprintf('** 2|4: Robustly Z-Standardized BETA ...\n')    
    [ manoutBETA ] = OutlierGUI(BETA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot_RZ, ...
        'epo_select', NREM, ...        
        'main_title', 'Robustly Z-Standardized BETA ', ...
        'epo_len', scoringlen, ...        
        'epo_thresh', T2);
    
    
    % ********************
    %       Deviation 
    % ********************
    
    % Set artifacts to NaN
    devEEG( isnan(manoutBETA.cleanVALUES) )  = nan;
    BETA_RZ( isnan(manoutBETA.cleanVALUES) ) = nan;
    SWA_RZ( isnan(manoutBETA.cleanVALUES) )  = nan;
    
    % Manual artifact rejection
    fprintf('** 3|4: Deviation from Robustly Z-Standardized Average EEG Signal ...\n')            
    [ manoutEEG ] = OutlierGUI(devEEG, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_select', NREM, ...   
        'main_title', 'Deviation from Robustly Z-Standardized Average EEG Signal ', ...
        'epo_len', scoringlen, ...           
        'epo_thresh', T3);


    % ********************
    %    Absolute SWA 
    % ********************     
    
    % Set artifacts to NaN
    devEEG( isnan(manoutEEG.cleanVALUES) )   = nan;
    BETA_RZ( isnan(manoutEEG.cleanVALUES) )  = nan;
    SWA( isnan(manoutEEG.cleanVALUES) )      = nan;  
    SWA_RZ( isnan(manoutEEG.cleanVALUES) )   = nan;        

    % Manual artifact rejection
    fprintf('** 4|4: Raw SWA ...\n ')
    [ manoutSWA_RAW ] = OutlierGUI(SWA, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'srate', EEG.srate, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_select', NREM, ...
        'main_title', 'Raw SWA', ...
        'epo_len', scoringlen, ...           
        'epo_thresh', T1);    


    % *** artndxn
    artndxn = ~isnan(manoutSWA_RAW.cleanVALUES);

end