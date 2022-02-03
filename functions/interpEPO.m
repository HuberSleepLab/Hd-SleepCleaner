function [EEG0, artout] = interpEPO(EEG, artndxn, stages, varargin)
   
    % *********************************************************************
    % INPUT
    %
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
    % chansBAD:         Bad channels 
    %                   These are those channels that are bad in all NREM
    %                   epochs in which at least one other channel was good
    % chansEXCL:        Excluded channels
    %                   Excluded channels are channels that were not taken
    %                   into account when defining clean epochs, usually
    %                   the outer ring of the HD-EEG net because they are
    %                   often more noisy and as such you would loose more
    %                   data than maybe necessary, especially if you don't
    %                   analyze the outer ring anyway
    % cleanNREM:        Artifact free sleep (N2 + N3) epochs
    % cleanEPO:         Artifact free epochs (usually N1 + N2 + N3 but it
    %                   depends whether REM and WAKE were set to 0 during
    %                   artifact correction).
    % allNREM:          Sleep epochs (N2 + N3) with and without artifacts
    % cleanMANUAL       Sleep epochs (N1 + N2 + N3) that are labeled as
    %                   clean during sleep scoring

    % Input parser
    p = inputParser;
    addParameter(p, 'visgood', [], @isnumeric)       % Epochs that are labelled as clean during sleep scoring (manual artifact rejection), corresponds to: find(sum(vistrack') == 0);
    addParameter(p, 'plotFlag', 0, @isnumeric)       % Do you want a plot?
    addParameter(p, 'exclChans', [43 48 49 56 63 68 73 81 88 94 99 107 113 119 120 125 126 127 128], @isnumeric) % Indices of channels to NOT consider when deciding which epochs are clean and which not (usually corresponds to the outer ring)
    addParameter(p, 'ON_win', {}, @iscell)           % ON windows from SleepLoop
    addParameter(p, 'OFF_win', {}, @iscell)          % OFF windows from SleepLoop
    addParameter(p, 'T', [], @isnumeric)             % Trigger latencies from SleepLoop    
    parse(p, varargin{:});
        
    % Assign variables
    visgood     = p.Results.visgood;    
    chansEXCL   = p.Results.exclChans;
    plotFlag    = p.Results.plotFlag;
    ON_win      = p.Results.ON_win;
    OFF_win     = p.Results.OFF_win;
    T           = p.Results.T;







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
        from = epo * 20 * EEG.srate - 20 * EEG.srate + 1;
        to   = epo * 20 * EEG.srate;

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


    % Classically bad epochs
    classicCLEAN = find( sum( artndxn( ~exclBIN, : )) == size(artndxn, 1) - sum(exclBIN) );

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
    cleanEPO= find( ...
        sum(artndxn) ~= 0 ...
        );

    % Remove rejected epochs during interpolation
    cleanNREM = setdiff( cleanNREM, rejEPO );




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
    % artout.cleanEPO    = cleanEPO;    



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