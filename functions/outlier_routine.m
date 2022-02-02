function [artndxn] = outlier_routine(EEG_RZ, FFTtot, freq, artndxn, ndxsleep, visnum, chanlocs, T1, T2, T3)


    % ********************
    %         SWA 
    % ********************    
    
    % Compute SWA
    SWA = select_band(FFTtot, freq, 0.5, 4.5, ndxsleep, artndxn);
    % SWA = ( SWA - median(SWA, 2, 'omitnan') ) ./ (prctile(SWA, 75, 2) - prctile(SWA, 25, 2));    
    
    % Manual artifact rejection
    [ manoutSWA ] = OutlierGUI(SWA, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'chanlocs', chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_thresh', T1);
    
    
    % ********************
    %         BETA 
    % ********************
    
    % Compute BETA
    BETA = select_band(FFTtot, freq, 20, 30, ndxsleep, artndxn);
    % BETA = ( BETA - median(BETA, 2, 'omitnan') ) ./ (prctile(BETA, 75, 2) - prctile(BETA, 25, 2));        
    
    % Set artifacts to NaN
    BETA( isnan(manoutSWA.cleanVALUES) ) = nan;
    SWA(  isnan(manoutSWA.cleanVALUES) ) = nan;
    
    % Manual artifact rejection
    [ manoutBETA ] = OutlierGUI(BETA, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'chanlocs', chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_thresh', T2);
    
    
    % ********************
    %       Deviation 
    % ********************
    
    % How much channel deviate from mean
    devEEG = deviationEEG(EEG_RZ, 125, 20, artndxn);
    % devEEG = ( devEEG - median(devEEG, 2, 'omitnan') ) ./ (prctile(devEEG, 75, 2) - prctile(devEEG, 25, 2));            
    
    % Set artifacts to NaN
    devEEG( isnan(manoutBETA.cleanVALUES) ) = nan;
    BETA( isnan(manoutBETA.cleanVALUES) )   = nan;
    SWA(  isnan(manoutBETA.cleanVALUES) )   = nan;
    
    % Manual artifact rejection
    [ manoutEEG ] = OutlierGUI(devEEG, ...
        'sleep', visnum, ...
        'EEG', EEG_RZ, ...
        'chanlocs', chanlocs, ...
        'topo', SWA, ...
        'spectrum', FFTtot, ...
        'epo_thresh', T3);


    % *** artndxn
    artndxn = ~isnan(manoutEEG.cleanVALUES);

end