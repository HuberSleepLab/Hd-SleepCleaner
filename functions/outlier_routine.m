function [artndxn] = outlier_routine(EEG, artndxn, ndxsleep, visnum, T1, T2, T3)

    
    % ********************
    %  Compute variables
    % ********************   

    % Robust z-standardization of EEG
    fprintf('Robustly Z-Standardize EEG ...\n')
    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));

    % Compute PSD
    fprintf('Compute PSD ...\n')    
    [FFTtot, freq] = pwelchEPO(EEG.data, EEG.srate, 20);

    % Compute PSD (Robustly z-standardizef EEG)
    fprintf('Compute PSD (Robustly z-standardized EEG) ...\n')    
    [FFTtot_RZ, freq] = pwelchEPO(EEG_RZ, EEG.srate, 20);    
    
    % Only show NREM epochs
    NREM = find( ismember( visnum, [-1 -2 -3] ));   


    % ********************
    %         SWA 
    % ********************     
    
    % Compute SWA
    SWA     = select_band(FFTtot, freq, 0.5, 4.5, ndxsleep, artndxn);
%     SWA_RZ  = ( SWA - median(SWA, 2, 'omitnan') ) ./ (prctile(SWA, 75, 2) - prctile(SWA, 25, 2));  
    SWA_RZ  = select_band(FFTtot_RZ, freq, 0.5, 4.5, ndxsleep, artndxn);
    
    
    % Manual artifact rejection
    fprintf('** 1|4: Robustly Z-Standardized SWA ...\n')
    [ manoutSWA ] = OutlierGUI(SWA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot_RZ, ...
        'epo_select', NREM, ...
        'epo_thresh', T1);
    
    
    % ********************
    %         BETA 
    % ********************
    
    % Compute BETA
%     BETA    = select_band(FFTtot, freq, 20, 30, ndxsleep, artndxn);
%     BETA_RZ = ( BETA - median(BETA, 2, 'omitnan') ) ./ (prctile(BETA, 75, 2) - prctile(BETA, 25, 2)); 
    BETA_RZ = select_band(FFTtot_RZ, freq, 20, 30, ndxsleep, artndxn);
        
    % Set artifacts to NaN
    BETA_RZ( isnan(manoutSWA.cleanVALUES) ) = nan;
    SWA_RZ(  isnan(manoutSWA.cleanVALUES) ) = nan;
    
    % Manual artifact rejection
    fprintf('** 2|4: Robustly Z-Standardized BETA ...\n')    
    [ manoutBETA ] = OutlierGUI(BETA_RZ, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot_RZ, ...
        'epo_select', NREM, ...        
        'epo_thresh', T2);
    
    
    % ********************
    %       Deviation 
    % ********************
    
    % How much channel deviate from mean
    devEEG = deviationEEG(EEG.data, 125, 20, artndxn);
    
    % Set artifacts to NaN
    devEEG( isnan(manoutBETA.cleanVALUES) )  = nan;
    BETA_RZ( isnan(manoutBETA.cleanVALUES) ) = nan;
    SWA_RZ( isnan(manoutBETA.cleanVALUES) )  = nan;
    
    % Manual artifact rejection
    fprintf('** 3|4: Deviation from Robustly Z-Standardized Average EEG Signal ...\n')            
    [ manoutEEG ] = OutlierGUI(devEEG, ...
        'sleep', visnum, ...
        'EEG', EEG.data, ...
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_select', NREM, ...        
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
        'chanlocs', EEG.chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_select', NREM, ...
        'epo_thresh', T1);    


    % *** artndxn
    artndxn = ~isnan(manoutSWA_RAW.cleanVALUES);

end