function [epo] = epo_assign(artndxn, stages, varargin)

    p = inputParser;
    addParameter(p, 'chansToIgnore',    [107 113 126 127]); % Channels that are not EEG
    addParameter(p, 'stagesOfInterest', [-2 -3]); % Sleep stages of interest
    addParameter(p, 'visgood',          []); % Artifact rejection during sleep scoring into account
    addParameter(p, 'badChanToNan',     1); % Toggle (0|1) to set bad channels to nan       
    parse(p, varargin{:});  

    % Create variables
    for var = p.Parameters
        eval([var{1} '= p.Results.(var{1});']);
    end  


    % *** Start function
    % Take artifact rejection during sleep scoring into account
    if ~isempty(visgood)
        stages(setdiff(1:end, visgood)) = nan; 
    end

    % Bad channels
    epo.chans_bad = find(sum(artndxn, 2) == 0)'; 

    % Channels bad in all epochs
    if badChanToNan
        chansToIgnore = unique([chansToIgnore, epo.chans_bad]); 
    end

    % Set channels that are not EEG to nan
    artndxn = single(artndxn);
    artndxn(chansToIgnore, :) = nan;        

    % Epochs bad in all channels
    epo.awful = find( ...
        sum(artndxn, 'omitnan') == 0 & ...
        ismember(stages, stagesOfInterest) ...
        );    

    % Epochs bad in some channels
    epo.messy = find( ...
        sum(artndxn, 'omitnan') > 0 & ...
        sum(artndxn, 'omitnan') < size(artndxn, 1) - numel(chansToIgnore) & ...
        ismember(stages, stagesOfInterest) ...
        );    

    % Epochs good in all channels
    epo.clean = find( ...
        sum(artndxn, 'omitnan') == size(artndxn, 1) - numel(chansToIgnore) & ...
        ismember(stages, stagesOfInterest) ...
        );    

    % Generally bad epochs
    epo.bad = sort([epo.messy epo.awful]);
    epo.all = sort([epo.clean epo.bad]);
end