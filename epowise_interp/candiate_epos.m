function [intp] = candiate_epos(artndxn, stages, chanlocs, varargin)

    % This function find epochs that can be interpolated, i.e. that suffie
    % the criterium that bad channels do not occur in clusters.
    % Neighbouring bad channels will not be interpolated when more than a
    % defined number of bad channels are neighbours.
    %
    % INPUT
    % artndxn: the output matrix of the outlier removal routine
    % stages: a vector storing sleep stages
    % chanlos: channel locations (as used for EEGLAB)
    %
    % OUTPUT
    % intpEPO1:  epochs that can be interpolated
    % badCH:     corresponding bad channels per epoch
    % intpEPO0:  epochs with too many bad neighbouring channels
    % lostEPO:   epochs which were not even candidates, e.g., because all
    %            channels in that epoch were bad.
    % *********************************************************************


    p = inputParser;
    addParameter(p, 'maxNumCloseChans', 2); % Maximum number of neighbouring channels
    addParameter(p, 'chansToIgnore',    [49 56 107 113 126 127]); % Channels that are not EEG
    addParameter(p, 'stagesOfInterest', [-2 -3]); % Sleep stages of interest
    addParameter(p, 'chanDist',         0.4); % To find neighbouring channels   
    addParameter(p, 'visgood',          []); % Artifact rejection during sleep scoring into account    
    addParameter(p, 'displayFlag',      1); % Toggle (0|1) to print some info        
    parse(p, varargin{:});  

    % Create variables
    for var = p.Parameters
        eval([var{1} '= p.Results.(var{1});']);
    end  


    % *** Start function ***    
    % Set channels that are not EEG to nan
    artndxn = single(artndxn);
    artndxn(chansToIgnore, :) = nan;    

    % Take artifact rejection during sleep scoring into account
    if ~isempty(visgood)
        stages(setdiff(1:end, visgood)) = nan; 
    end    
    
    % Epochs with at least 1 bad channel & at least 1 good channel
    workEPO = find( ...
        sum(artndxn, 'omitnan') ~= 0 & ...
        sum(artndxn, 'omitnan') < size(artndxn, 1) - numel(chansToIgnore) & ...
        ismember(stages, stagesOfInterest) ...
        ); 
    
    % Distances between channels
    D       = get_distances( [chanlocs.X], [chanlocs.Y], [chanlocs.Z] );   
    DClose  = D <= chanDist;

    % Find bad channel
    for iepo = 1:numel(workEPO)
        epo             = workEPO(iepo);        
        badCH{iepo}  = find(artndxn(:, epo) == 0);
    end

    % Epochs with 1 channel are candidates for interpolation
    epos1CHAN      = find(cellfun(@numel, badCH) == 1);    
    eposTOCHECK    = find(cellfun(@numel, badCH) > 1);

    % Epochs with > 1 channel need to be checked for locations
    chansCOMB      = cellfun(@(x) nchoosek(x, 2), badCH(eposTOCHECK), 'Uni', 0);
    numCLOSE       = cellfun(@(x) sum( diag( DClose( x(:,1), x(:,2) ) ) ), chansCOMB);

    % Interpolation candidates
    ndx0 = eposTOCHECK(numCLOSE > maxNumCloseChans);    
    ndx1 = eposTOCHECK(numCLOSE <= maxNumCloseChans);   
    ndx1 = sort([epos1CHAN, ndx1]);

    % Actual epochs and channels to interpolate
    intp.epo_not_intp  = workEPO(ndx0);   % Not interpolated epochs (lost)
    intp.epo_intp      = workEPO(ndx1);   % Interpolated epochs (recovered) 
    intp.chans_bad     = badCH(ndx1);     % Corresponding bad channels

    % Displayflag
    if displayFlag
        fprintf('\nYay! Found %d epochs to recover with epoch-wise interpolation.\n', numel(intp.epo_intp))
    end

    % Epochs bad in all channels
    lostEPO = find( ...
        sum(artndxn, 'omitnan') == 0 & ...
        ismember(stages, stagesOfInterest) ...
        );    
    intp.epo_lost = sort([intp.epo_not_intp lostEPO]);
end