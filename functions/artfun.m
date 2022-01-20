function artout = artfun(artndxn, stages, varargin)
   
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
    % ndx_chansbad:     Bad channels 
    %                   These are those channels that have less clean
    %                   epochs than defined in "cleanThresh"
    % ndx_chansexcl:    Bad channels + excluded channels
    %                   Excluded channels are channels that were not taken
    %                   into account when defining clean epochs, usually
    %                   the outer ring of the HD-EEG net because they are
    %                   often more noisy and as such you would loose more
    %                   data than maybe necessary, especially if you don't
    %                   analyze the outer ring anyway
    % ndx_cleanNREM:    Artifact free sleep (N2 + N3) epochs
    % ndx_clean:        Artifact free epochs (usually N1 + N2 + N3 but it
    %                   depends whether REM and WAKE were set to 0 during
    %                   artifact correction).
    % ndx_NREM:         Sleep epochs (N2 + N3) with and without artifacts
    % ndx_cleanMANUAL   Sleep epochs (N1 + N2 + N3) that are labeled as
    %                   clean during sleep scoring



    % Input parser
    p = inputParser;
    addParameter(p, 'visgood', [], @isnumeric)       % Epochs that are labelled as clean during sleep scoring (manual artifact rejection), corresponds to: find(sum(vistrack') == 0);
    addParameter(p, 'cleanThresh', 98, @isnumeric)   % Percentage of epochs that need to be clean in each channel before it gets labelled as "bad"
    addParameter(p, 'plotFlag', 1, @isnumeric)       % Do you want a plot?
    addParameter(p, 'exclChans', [43 48 49 56 63 68 73 81 88 94 99 107 113 119 120 125 126 127 128], @isnumeric) % Indices of channels to NOT consider when deciding which epochs are clean and which not (usually corresponds to the outer ring)
    addParameter(p, 'ON_win', {}, @iscell)           % ON windows from SleepLoop
    addParameter(p, 'OFF_win', {}, @iscell)          % OFF windows from SleepLoop
    addParameter(p, 'T', [], @isnumeric)             % Trigger latencies from SleepLoop    
    parse(p, varargin{:});
        
    % Assign variables
    visgood     = p.Results.visgood;    
    cleanThresh = p.Results.cleanThresh;
    exclChans   = p.Results.exclChans;
    plotFlag    = p.Results.plotFlag;
    ON_win      = p.Results.ON_win;
    OFF_win     = p.Results.OFF_win;
    T           = p.Results.T;
    
    

    
    % **********************
    %   Find bad channels
    % **********************
    
    if isempty(visgood)
        % If no manual artifact rejection
        % Pretend that during manual artifact rejection all epochs were good
        visgood = find(ones(1, numel(stages)));
    end

    % For the computation of the percentage of clean epochs, compute how
    % many N1/N2/N3 epochs that were classified as clean during manual
    % sleep scoring are also clean after semi-automatic artifact rejection,
    % so in the variable "artndxn"

    % Clean sleep epochs after manual artifact rejection
    ndx_cleanMANUAL = intersect(visgood, find(stages <= -1)); 
     
    % Percentage of clean sleep epochs after semi-automatic artifact remoal
    prcnt_cleanEPO  = sum(artndxn(:, ndx_cleanMANUAL), 2) ./ size(artndxn(:, ndx_cleanMANUAL), 2) * 100;
    
    % Compute bad channels
    ndx_chansBAD  = find(prcnt_cleanEPO < cleanThresh)';     % Bad channels < "98%" good epochs
    ndx_chansEXCL = unique([ndx_chansBAD, exclChans]);       % Bad channels + excluded channels

   
    % *************************
    %   Figure: bad channels
    % *************************

    if plotFlag

        % Pre-allocate
        prcnt_epolow  = prcnt_cleanEPO;
        prcnt_epoexcl = prcnt_cleanEPO;        
      
        % Set to nan, so that bars have right color
        prcnt_cleanEPO(prcnt_cleanEPO == 0)                             = nan;  
        prcnt_epolow(prcnt_epolow >= cleanThresh)                       = nan;  
        prcnt_epoexcl(setdiff(1:size(prcnt_cleanEPO, 1), exclChans), :) = nan;     
            
        % Open figure
        figure('color', 'w', 'OuterPosition', [250 250 700 900]);

        % Plot bars
        barh(prcnt_cleanEPO, 'DisplayName', 'Good channels'); hold on;
        barh(prcnt_epoexcl, 'FaceColor', uint8([200 200 200]), 'DisplayName', 'Excl. channels');
        barh(prcnt_epolow, 'r', 'DisplayName', 'Bad channels');
        
        % Make pretty
        xlim([min([prcnt_cleanEPO; cleanThresh])-1 100]); xlabel('(%) in of N1 N2 N3'); ylabel('Channel ID'); yticks(4:4:128); ylim([1 size(artndxn, 1)]);
        % xline(cleanThresh, ':', 'LineWidth', 2, 'DisplayName', 'Threshold');
        plot(repmat(cleanThresh, 1, length(prcnt_cleanEPO)), 1:length(prcnt_cleanEPO),  ':', 'LineWidth', 2, 'DisplayName', 'Threshold')
        legend('Location', 'NorthOutside', 'Orientation','horizontal');    
    end


    % ***************************
    %   Find clean NREM epochs
    % ***************************
           
    % Do not consider excluded epochs to determine which epochs are clean
    artndxn(ndx_chansEXCL, :) = [];    

    % Index of clean epochs
    bin_ndxgood    = sum(artndxn, 1) == size(artndxn, 1);  % binary format
    ndx_cleanEPO   = find(bin_ndxgood);                    % actual index

    % N2 + N3 epochs
    ndx_NREM = find(stages <= -2);    
    
    % Clean N2 + N3 epochs
    ndx_cleanNREM = intersect(ndx_cleanEPO, ndx_NREM); 


    % *********************************
    %   Print some useful information
    % *********************************

    % Print number of epochs
    fprintf('\n*** #Epochs (#Clean epochs) \n')    
    fprintf('#W: %d (%d)\n',   sum(stages ==  1), sum(stages ==   1  & bin_ndxgood))    
    fprintf('#REM: %d (%d)\n', sum(stages ==  0), sum(stages ==   0  & bin_ndxgood))        
    fprintf('#N1: %d (%d)\n',  sum(stages == -1), sum(stages ==  -1  & bin_ndxgood))
    fprintf('#N2: %d (%d)\n',  sum(stages == -2), sum(stages ==  -2  & bin_ndxgood))    
    fprintf('#N3: %d (%d)\n',  sum(stages == -3), sum(stages ==  -3  & bin_ndxgood))
    fprintf('#Clean N2 + N3: %d\n', numel(ndx_cleanNREM))

    % Print bad channels    
    if ~isempty(ndx_chansBAD)
        fprintf('*** Channels \n')
        fprintf(['Channel(s) '])    
        fprintf('%g ', ndx_chansBAD)    
        fprintf(' do(es) not fullfil the %.2f criterium: %d\n', cleanThresh) 
    end
                
    % Create output variable
    artout.chansBAD    = ndx_chansBAD;
    artout.chansEXCL   = ndx_chansEXCL;
    artout.cleanNREM   = ndx_cleanNREM;
    artout.cleanEPO    = ndx_cleanEPO;
    artout.allNREM     = ndx_NREM;
    artout.cleanMANUAL = ndx_cleanMANUAL;    
    artout.cleanTHRESH = cleanThresh;



    % ***  Windows and Trigger       

    % ******************************
    %   Find clean ON/OFF windows
    % ****************************** 

    if ~isempty(ON_win)

        % Windows to 20s epoch
        epoON   = cellfun(@(x) unique(ceil(x/125/20)), ON_win, 'Uni', 0);
        epoOFF  = cellfun(@(x) unique(ceil(x/125/20)), OFF_win, 'Uni', 0);
               
        % Artifact free windows
        artout.cleanON  = find(cellfun(@(x) any(ismember(ndx_cleanNREM, x)), epoON));
        artout.cleanOFF = find(cellfun(@(x) any(ismember(ndx_cleanNREM, x)), epoOFF));
        artout.cleanW   = intersect(artout.cleanON, artout.cleanOFF);
    end



    % ***************************************
    %   Find sleep stage of ON/OFF windows
    % ***************************************   

    % Sleep stage of each sample point
    stages_samples = repmat(stages, 20*125, 1);
    stages_samples = stages_samples(:);
    
    % Unique sleep stages
    stages_lvl = unique(stages_samples);      

    if ~isempty(ON_win)  

        % If sleep scoring is a little shorter than data
        ON_win = cellfun(@(x) x(x <= length(stages_samples)), ON_win, 'Uni', 0);
        OFF_win = cellfun(@(x) x(x <= length(stages_samples)), OFF_win, 'Uni', 0);
     
        % Sleep epoch majority in ON
        counts          = cellfun(@(x) histc(stages_samples(x), stages_lvl), ON_win, 'Uni', 0);
        [~, ndx]        = cellfun(@max, counts);
        ndx(find(cellfun(@(x) all(x == 0), counts))) = 3;   % Assign sleep stage where there was no data to "3" = "END"     
        artout.sleepON  = stages_lvl(ndx);

        % Sleep epoch majority in OFF
        counts          = cellfun(@(x) histc(stages_samples(x), stages_lvl), OFF_win, 'Uni', 0);
        [~, ndx]        = cellfun(@max, counts);
        ndx(find(cellfun(@(x) all(x == 0), counts))) = 3;   % Assign sleep stage where there was no data to "3" = "END"     
        artout.sleepOFF = stages_lvl(ndx);  

        % Sleep epoch majority in ON + OFF
        counts          = cellfun(@(x, y) histc(stages_samples([x, y]), stages_lvl), ON_win, OFF_win, 'Uni', 0);
        [~, ndx]        = cellfun(@max, counts);
        artout.sleepW   = stages_lvl(ndx);         
    end
        


    % *************************
    %   Find clean Trigger
    % ************************* 

    if ~isempty(T)
    
        % Trigger to 20s epoch
        epoT            = ceil(T/125/20);
        artout.cleanT   = find(ismember(epoT, ndx_cleanNREM));   
        artout.sleepT   = stages_samples(T);    
    end    
    
    % Print windows  
    if ~isempty(ON_win)
        fprintf('\n*** Windows\n')
        fprintf('#Clean ON win: %d\n', numel(artout.cleanON))
        fprintf('#Clean OFF win: %d\n', numel(artout.cleanOFF))
        fprintf('#Clean T: %d\n', numel(artout.cleanT)) 
        fprintf('#W win: %d (%d)\n',   sum(artout.sleepW ==  1), numel(intersect(find(artout.sleepW ==  1),  artout.cleanW)))      
        fprintf('#REM win: %d (%d)\n', sum(artout.sleepW ==  0), numel(intersect(find(artout.sleepW ==  0),  artout.cleanW)))              
        fprintf('#N1 win: %d (%d)\n',  sum(artout.sleepW == -1), numel(intersect(find(artout.sleepW ==  -1), artout.cleanW)))      
        fprintf('#N2 win: %d (%d)\n',  sum(artout.sleepW == -2), numel(intersect(find(artout.sleepW ==  -2), artout.cleanW)))
        fprintf('#N3 win: %d (%d)\n',  sum(artout.sleepW == -3), numel(intersect(find(artout.sleepW ==  -3), artout.cleanW)))
    end    
end

