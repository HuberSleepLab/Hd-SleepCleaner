function [EEG0, artout] = interpEPO(EEG, artndxn, stages, varargin)
   
    % *********************************************************************
    % INPUT
    %
    % EEG:     Your EEG structure
    % artndxn: Matrix containing output of semi-automatic artifact rejection
    %          That is a matrix (channels x epochs) with
    %          1: good epochs
    %          0: bad epochs
    % stages:  Your sleep stages (sometimes called visnum)
    %          Sleep stages must be coded as follows
    %          W:   1
    %          R:   0
    %          N1: -1
    %          N2: -2
    %          N3: -3
    %          With Kispi's old scoring program it corresponds to
    %          stages = visfun.numvis(vissymb, offs)
    %
    %
    % OUTPUT
    %
    % EEG0:             EEG Data with interpolated epochs
    % artout:           A structure containing several subfields. They 
    %                   contain the index of epochs or channels that 
    %                   fullfill certain criteria.
    %
    % ** Subfields **
    % cleanNREM:        Clean NREM epochs
    %                   Artifact free sleep (N2 + N3) epochs, so epochs
    %                   that were either clean in all channels or had some
    %                   bad channels but they all could be interpolated
    % allNREM:          All NREM epochs
    %                   Sleep epochs (N2 + N3) with and without artifacts    
    % cleanMANUAL       Clean NREM epochs from scoring
    %                   Sleep epochs (N1 + N2 + N3) that are labeled as
    %                   clean during sleep scoring    
    % chansEXCL:        Excluded channels
    %                   Excluded channels are channels that were not taken
    %                   into account when defining clean epochs, usually
    %                   the outer ring of the HD-EEG net because they are
    %                   often more noisy and as such you would loose more
    %                   data than maybe necessary, especially if you don't
    %                   analyze the outer ring anyway    
    % chansBAD:         Bad channels 
    %                   These are those channels that are bad in all NREM
    %                   epochs in which at least one other channel was good   
    % interpNREM        Interpoalted epochs
    %                   Epochs in which at least one channel was
    %                   interpolated.    
    % savedNREM         Saved NREM epochs
    %                   Epochs that were interpolated and would have been
    %                   rejected in classicCLEAN can be considered "saved"
    % classicCLEAN:     Conservative clean epochs
    %                   Epochs where all channels except those in chansEXCL
    %                   were good according to artndxn. In other words, in
    %                   case at least one channel was bad (except it
    %                   belonged to chansEXCL), it would not be considered
    %                   clean here.
    % cleanN1           Clean N1 epochs    
    %                   Artifact free N1 epochs, so epochs that were either
    %                   clean in all channels or had some bad channels but 
    %                   they all could be interpolated
    % cleanN2           Clean N2 epochs    
    % cleanN2           Clean N3 epochs    
    % cleanEPO:         Artifact free epochs (usually N1 + N2 + N3 but it
    %                   depends whether REM and WAKE were set to 0 during
    %                   artifact correction).    



    % Input parser
    p = inputParser;
    addParameter(p, 'visgood', [], @isnumeric)       % Epochs that are labelled as clean during sleep scoring (manual artifact rejection), corresponds to: find(sum(vistrack') == 0);
    addParameter(p, 'plotFlag', 0, @isnumeric)       % Do you want a plot?
    addParameter(p, 'exclChans', [43 48 49 56 63 68 73 81 88 94 99 107 113 119 120 125 126 127 128], @isnumeric) % Indices of channels to NOT consider when deciding which epochs are clean and which not (usually corresponds to the outer ring)
    addParameter(p, 'WT', [], @isstruct)                % Structure window and trigger information
    addParameter(p, 'scoringlen', 20, @isnumeric)    % Epoch length of scoring
    addParameter(p, 'srate', 125, @isnumeric)        % Sampling rate
    parse(p, varargin{:});
        
    % Assign variables
    visgood     = p.Results.visgood;    
    chansEXCL   = p.Results.exclChans;
    plotFlag    = p.Results.plotFlag;
    WT          = p.Results.WT;
    scoringlen  = p.Results.scoringlen;
    srate       = p.Results.srate;







    % ***************************
    %   Percentage clean epochs
    % ***************************

    % For the computation of the percentage of clean epochs, compute how
    % many N1/N2/N3 epochs that were classified as clean during manual
    % sleep scoring are also clean after semi-automatic artifact rejection,
    % so in the variable "artndxn"

    if isempty(visgood)
        % If no manual artifact rejection
        % Pretend that during manual artifact rejection all epochs were good
        visgood = find(ones(1, numel(stages)));
    end    

    % Clean sleep epochs after manual artifact rejection
    cleanMANUAL = intersect(visgood, find(stages <= -1)); 
     
    % Percentage of clean sleep epochs after semi-automatic artifact remoal
    prcnt_cleanEPO  = sum(artndxn(:, cleanMANUAL), 2) ./ size(artndxn(:, cleanMANUAL), 2) * 100;
    



    % ***************************
    %    Interpolate channels
    % ***************************

    % Channels that are not EEG
    chansRMV = [49 56 107 113 126 127];

    % Adapt chansEXCL
    exclBIN = zeros(1, size(artndxn, 1));
    exclBIN(chansEXCL) = 1;
    exclBIN(chansRMV)  = [];

    % Remove chin & earlobes
    % EEG.data( [49 56 107 113], : ) = nan;
    EEG0    = EEG;
    EEG     = pop_select(EEG, 'nochannel', chansRMV);
    artndxn = artndxn(setdiff(1:end, chansRMV), :);

    % Epochs with at least 1 clean channel
    workEPO = find( ...
        sum(artndxn) ~= 0 & ...
        sum(artndxn) < size(artndxn, 1) & ...
        ismember(stages, [-2 -3]) ...
        );

    % Distances between channels
    D       = get_distances( [EEG.chanlocs.X], [EEG.chanlocs.Y], [EEG.chanlocs.Z] );   
    DClose  = D <= 0.4;

    % Reject epochs
    rejEPO  = [];
    
    % Loop through
    wb = waitbar(0, 'Inteprolate channels per epoch ...');
    for iepo = 1:numel(workEPO)
        epo  = workEPO(iepo);

        % Find bad channel
        chansBAD = find(artndxn(:, epo) == 0);

        % Find close channels
        if numel(chansBAD) > 1
            chansCOMB = nchoosek(chansBAD, 2);
            numCLOSE  = sum( diag( DClose( chansCOMB(:,1), chansCOMB(:,2) ) ) );

            if numCLOSE >= 3
                rejEPO = [ rejEPO epo ];
                continue
            end
        end

        % Are theree too many bad neighbouring channels?

        % Data points
        from = epo * scoringlen * EEG.srate - scoringlen * EEG.srate + 1;
        to   = epo * scoringlen * EEG.srate;

        % Extract data
        % EPO = pop_select(EEG, 'point', [from to]);
        EPO      = EEG;
        EPO.data = EPO.data(:, from:to);

        % Interpolate bad channels
        EPO = pop_interp(EPO, chansBAD, 'spherical');

%         figure;
%         hold on;
%         plot(EEG.data(chansBAD, from:to)');
%         plot(EPO.data(chansBAD, :)', '--')

        % Insert interpolated data
        EEG.data(chansBAD, from:to) = EPO.data(chansBAD, :);
    
        % update waitbar
        waitbar(iepo/numel(workEPO), wb, sprintf('Inteprolate channels per epoch ... %d/%d', iepo, numel(workEPO)));
        
    end
    close(wb); % close waitbar

    % Replace interpolated values in 129 channel structure
    EEG0.data(setdiff(1:end, chansRMV), :) = EEG.data;




    % ***************************
    %   Find clean NREM epochs
    % ***************************

    % Channels that are constantly bad
    chansDEAD = sum(artndxn, 2)' == 0;

    % Classically bad epochs
    classicCLEAN = find( sum( artndxn( ~exclBIN & ~chansDEAD, : )) == size(artndxn, 1) - sum(exclBIN) );

    % Saved epochs are interpolated 
    savedEPO = workEPO;
    savedEPO = setdiff( savedEPO, classicCLEAN );

    % Are rejected epochs only bad in excluded channels?
    % exceptions          = sum ( artndxn( ~exclBIN, rejEPO ) ) == size(artndxn, 1) - sum(exclBIN);
    % rejEPO(exceptions)  = [];
    rejEPO = setdiff( rejEPO, classicCLEAN );

    % All NREM epochs
    allNREM = find(ismember(stages, [-2 -3]));

    % Epochs with at least 1 clean channel
    cleanNREM = find( ...
        sum(artndxn) ~= 0 & ...
        ismember(stages, [-2 -3]) ...
        );

    % Channels that had to be interpolated in all epochs
    chansBAD = find( sum( artndxn(:, cleanNREM) == 0, 2) == numel(cleanNREM) );    

    % Remove rejected epochs during interpolation
    cleanNREM = setdiff( cleanNREM, rejEPO );

    % Epochs with at least 1 clean channel
    cleanEPO = find( ...
        sum(artndxn) ~= 0 ...
        );

    % Remove rejected epochs during interpolation
    cleanEPO = setdiff( cleanEPO, rejEPO );

    % Clean sleep stages
    cleanN1 = intersect( find(stages == -1), cleanNREM);    
    cleanN2 = intersect( find(stages == -2), cleanNREM);
    cleanN3 = intersect( find(stages == -3), cleanNREM);    


    % *********************************
    %      Clean W and T from SL2
    % *********************************

    if ~isempty(WT)

        % *** Clean windows
        % Windows to 20s epoch
        epoON   = cellfun(@(x) unique(ceil(x/srate/scoringlen)), WT.W.ON.samples, 'Uni', 0);
        epoOFF  = cellfun(@(x) unique(ceil(x/srate/scoringlen)), WT.W.OFF.samples, 'Uni', 0);
               
        % Artifact free windows
        artout.WT.W.ON.cleanNREM        = find(cellfun(@(x) any(ismember(cleanNREM, x)), epoON));
        artout.WT.W.OFF.cleanNREM       = find(cellfun(@(x) any(ismember(cleanNREM, x)), epoOFF));
        artout.WT.W.Entire.cleanNREM    = intersect(artout.WT.W.ON.cleanNREM, artout.WT.W.OFF.cleanNREM);      


        % *** Sleep stage of windows
        % Sleep stage of each sample point
        stages_samples = repmat(stages, scoringlen*srate, 1);
        stages_samples = stages_samples(:);
    
        % Unique sleep stages
        stages_lvl = unique(stages_samples);      

        % If sleep scoring is a little shorter than data
        ON_win  = cellfun(@(x) x(x <= length(stages_samples)), WT.W.ON.samples, 'Uni', 0);
        OFF_win = cellfun(@(x) x(x <= length(stages_samples)), WT.W.OFF.samples, 'Uni', 0);
     
        % Sleep epoch majority in ON
        counts                  = cellfun(@(x) histc(stages_samples(x), stages_lvl), ON_win, 'Uni', 0);
        [~, ndx]                = cellfun(@max, counts);
        ndx(find(cellfun(@(x) all(x == 0), counts))) = 3;   % Assign sleep stage where there was no data to "3" = "END"     
        artout.WT.W.ON.sleep    = stages_lvl(ndx);

        % Sleep epoch majority in OFF
        counts                  = cellfun(@(x) histc(stages_samples(x), stages_lvl), OFF_win, 'Uni', 0);
        [~, ndx]                = cellfun(@max, counts);
        ndx(find(cellfun(@(x) all(x == 0), counts))) = 3;    
        artout.WT.W.OFF.sleep   = stages_lvl(ndx);  

        % Sleep epoch majority in ON + OFF
        counts                  = cellfun(@(x, y) histc(stages_samples([x, y]), stages_lvl), ON_win, OFF_win, 'Uni', 0);
        [~, ndx]                = cellfun(@max, counts);
        ndx(find(cellfun(@(x) all(x == 0), counts))) = 3; 
        artout.WT.W.Entire.sleep= stages_lvl(ndx);         


        % *** Clean Trigger
        epoT                    = ceil(WT.T.ON.samples/srate/scoringlen);
        artout.WT.T.ON.cleanNREM= find(ismember(epoT, cleanNREM));   
        artout.WT.T.ON.sleep    = stages_samples(WT.T.ON.samples);      


        % Clean

        % ***  Print windows  
        fprintf('\n*** #W (#Clean) \n')    
        fprintf('#ON: %d (%d)\n',  numel(WT.W.ON.samples),  numel(artout.WT.W.ON.cleanNREM))        
        fprintf('#OFF: %d (%d)\n', numel(WT.W.OFF.samples), numel(artout.WT.W.OFF.cleanNREM))
        fprintf('#W: ON: %d (%d) OFF: %d (%d)\n', ...
            sum(artout.WT.W.ON.sleep == 1),  numel(intersect(find(artout.WT.W.ON.sleep ==  1),  artout.WT.W.ON.cleanNREM)), ...
            sum(artout.WT.W.OFF.sleep == 1), numel(intersect(find(artout.WT.W.OFF.sleep ==  1), artout.WT.W.OFF.cleanNREM)))      
        fprintf('#REM: ON: %d (%d) OFF: %d (%d)\n', ...
            sum(artout.WT.W.ON.sleep == 0),  numel(intersect(find(artout.WT.W.ON.sleep ==  0),  artout.WT.W.ON.cleanNREM)), ...
            sum(artout.WT.W.OFF.sleep == 0), numel(intersect(find(artout.WT.W.OFF.sleep ==  0), artout.WT.W.OFF.cleanNREM)))          
        fprintf('#N1: ON: %d (%d) OFF: %d (%d)\n', ...
            sum(artout.WT.W.ON.sleep == -1),  numel(intersect(find(artout.WT.W.ON.sleep ==  -1),  artout.WT.W.ON.cleanNREM)), ...
            sum(artout.WT.W.OFF.sleep == -1), numel(intersect(find(artout.WT.W.OFF.sleep ==  -1), artout.WT.W.OFF.cleanNREM)))
         fprintf('#N2: ON: %d (%d) OFF: %d (%d)\n', ...
            sum(artout.WT.W.ON.sleep == -2),  numel(intersect(find(artout.WT.W.ON.sleep ==  -2),  artout.WT.W.ON.cleanNREM)), ...
            sum(artout.WT.W.OFF.sleep == -2), numel(intersect(find(artout.WT.W.OFF.sleep ==  -2), artout.WT.W.OFF.cleanNREM)))
        fprintf('#N3: ON: %d (%d) OFF: %d (%d)\n', ...
            sum(artout.WT.W.ON.sleep == -3),  numel(intersect(find(artout.WT.W.ON.sleep ==  -3),  artout.WT.W.ON.cleanNREM)), ...
            sum(artout.WT.W.OFF.sleep == -3), numel(intersect(find(artout.WT.W.OFF.sleep ==  -3), artout.WT.W.OFF.cleanNREM)))
    end


    % *********************************
    %   Print some useful information
    % *********************************

    % All epochs that were not rejected
    cleanBIN = sum(artndxn) ~= 0 ;
    cleanBIN( rejEPO ) = 0;    

    % Interpolated epochs
    interpBIN           = zeros(1, numel(stages));
    interpBIN(workEPO)  = 1;
    interpBIN(rejEPO)   = 0;

    % Saved epochs
    savedBIN           = zeros(1, numel(stages));
    savedBIN(savedEPO) = 1;
    savedBIN(rejEPO)   = 0;    

    % Print number of epochs
    fprintf('\n*** #Epochs (#Clean epochs) [#Interpolated] {#Saved by interp.}\n')    
    fprintf('#W: %d (%d) [%d] {%d}\n',   sum(stages ==  1), sum(stages ==   1  & cleanBIN), sum(stages ==    1  & interpBIN), sum(stages ==    1  & savedBIN))    
    fprintf('#REM: %d (%d) [%d] {%d}\n', sum(stages ==  0), sum(stages ==   0  & cleanBIN), sum(stages ==    0  & interpBIN), sum(stages ==    0  & savedBIN))        
    fprintf('#N1: %d (%d) [%d] {%d}\n',  sum(stages == -1), sum(stages ==  -1  & cleanBIN), sum(stages ==   -1  & interpBIN), sum(stages ==   -1  & savedBIN))
    fprintf('#N2: %d (%d) [%d] {%d}\n',  sum(stages == -2), sum(stages ==  -2  & cleanBIN), sum(stages ==   -2  & interpBIN), sum(stages ==   -2  & savedBIN))    
    fprintf('#N3: %d (%d) [%d] {%d}\n',  sum(stages == -3), sum(stages ==  -3  & cleanBIN), sum(stages ==   -3  & interpBIN), sum(stages ==   -3  & savedBIN))
    fprintf('#Clean N2 + N3: %d\n', numel(cleanNREM))   

    % Create output variable
    artout.cleanNREM   = cleanNREM;
    artout.allNREM     = allNREM;
    artout.cleanMANUAL = cleanMANUAL;    
    artout.chansEXCL   = chansEXCL;
    artout.chansBAD    = chansBAD;
    artout.interpNREM  = find(interpBIN);
    artout.savedNREM   = find(savedBIN);    
    artout.classicCLEAN= classicCLEAN;    
    artout.cleanN1     = cleanN1;    
    artout.cleanN2     = cleanN2;    
    artout.cleanN3     = cleanN3;          
    artout.cleanEPO    = cleanEPO;    



    % *********************************
    %   Print some useful information
    % *********************************

    if plotFlag

        Y = [ ...;
         sum(stages ==  1), sum(stages ==   1  & cleanBIN), sum(stages ==    1  & interpBIN), sum(stages ==    1  & savedBIN); ...    
         sum(stages ==  0), sum(stages ==   0  & cleanBIN), sum(stages ==    0  & interpBIN), sum(stages ==    0  & savedBIN); ...        
         sum(stages == -1), sum(stages ==  -1  & cleanBIN), sum(stages ==   -1  & interpBIN), sum(stages ==   -1  & savedBIN); ...
         sum(stages == -2), sum(stages ==  -2  & cleanBIN), sum(stages ==   -2  & interpBIN), sum(stages ==   -2  & savedBIN); ...    
         sum(stages == -3), sum(stages ==  -3  & cleanBIN), sum(stages ==   -3  & interpBIN), sum(stages ==   -3  & savedBIN); ...
         ];        

        % Open figure
        figure('color', 'w') 
        hold on; 

        % Barplot
        b = bar(Y,'FaceColor','flat');

        % Make pretty
        b(1).CData = repmat(hex2rgb('#0a3d62'), 5, 1); 
        b(2).CData = repmat(hex2rgb('#3c6382'), 5, 1); 
        b(3).CData = repmat(hex2rgb('#60a3bc'), 5, 1); 
        b(4).CData = repmat(hex2rgb('#82ccdd'), 5, 1); 
        legend({'#Epochs', '#Clean epochs', '#Thereof interpolated', '#Thereof saved'}, 'Location', 'Northwest')
        xticks(1:5)
        xticklabels({'W', 'REM', 'N1', 'N2', 'N3'})  
        ylabel('#Epochs')
        grid on

        % Save
        set(gcf, 'Position', [400, 400, 500, 300]); tightfig();
    end
end