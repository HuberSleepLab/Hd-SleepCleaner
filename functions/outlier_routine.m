function artndxn = outlier_routine(EEG, M, artndxn, visnum, T1, T2, T3, outlier_types, varargin)


    % Input parser
    p = inputParser;
    addParameter(p, 'scoringlen', 20, @isnumeric)
    addParameter(p, 'stages_of_interest', [])  
    addParameter(p, 'chans_excl', [107 113 127 128], @isnumeric)        

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
    EEG_RZ = ( EEG.data - median(EEG.data, 2) ) ./ (prctile(EEG.data, 75, 2) - prctile(EEG.data, 25, 2));  


    for indx_type = 1:numel(outlier_types)
    
        type = outlier_types{indx_type};
    
        % get parameters specific to robust z-scoring
        if contains(type, 'RZ')
            type_EEG = EEG_RZ;
            type_spectrum = M.FFTtot_RZ;
            type_amp_ylabel = 'Amplitude (z-value)';
            type_main_ylabel = 'Power (n. a.)';
        else
            type_EEG = EEG.data;
            type_spectrum = M.FFTtot;
            type_amp_ylabel = 'Amplitude (\muV)';
            type_main_ylabel = 'Power (\muV^2)';
        end
    
        % get parameters specific to each type
        switch type
            case 'devEEG'
                type_title = 'Deviation from average EEG Signal ';
                type_threshold = T3;
            case 'SWA'
                type_title = sprintf('Power (%.1f - %.1f Hz) from raw EEG', M.L1, M.L2);
                type_threshold = T1;
            case 'SWA_RZ'
                type_title = sprintf('Power (%.1f - %.1f Hz) from robustly Z-Standardized EEG', M.L1, M.L2);
                type_threshold = T1;
            case 'BETA_RZ'
                type_title = sprintf('Power (%.1f - %.1f Hz) from robustly Z-Standardized EEG', M.H1, M.H2);
                type_threshold = T2;
            case 'voltEEG'
                 type_title = 'Raw voltage';
                type_threshold = inf;
            otherwise
                error('incorrect outlier type')
        end
    
        fprintf(['** ', num2str(indx_type), '|', num2str(numel(outlier_types)), ...
            ': Robustly Z-Standardized SWA ...\n'])
    
        [ manout ] = OutlierGUI(M.(type), ...
            'sleep', visnum, ...
            'EEG', type_EEG, ...
            'srate', EEG.srate, ...
            'chanlocs', EEG.chanlocs, ...
            'topo', M.(type), ...
            'spectrum', type_spectrum, ...
            'epo_select', stages_of_interest, ...
            'main_title', type_title, ...
            'amp_ylabel', type_amp_ylabel, ...
            'main_ylabel',  type_main_ylabel, ...
            'epo_len', scoringlen, ...
            'epo_thresh', type_threshold);
    
        % Set artifacts to NaN
        for indx_t = 1:numel(outlier_types)
            M.(outlier_types{indx_t})( isnan(manout.cleanVALUES) ) = nan;
            disp(outlier_types{indx_t})
        end
    end

    % *** artndxn
    artndxn = ~isnan(manout.cleanVALUES);
end