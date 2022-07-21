function [EEG, artintp] = Call_EpowiseInterp(EEG, artndxn, stages, varargin)
   
    % This function takes the EEG, sleep stages, as well as artifact
    % indices to eventually determine clean epochs in sleep stages of
    % interest. Epochs with bad channels will be interpolated as long as as
    % no clusters of bad channels exist. The output is the interpolated
    % EEG, as well as the indices of clean epochs in different sleep
    % stages.
    %
    % *** INPUT
    % EEG:     EEG structure (as EEGLAB requires)
    % artndxn: Matrix containing output of semi-automatic artifact rejection
    %          That is a matrix (channels x epochs) with
    %          1: good epochs
    %          0: bad epochs
    % stages:  Your sleep stages (must be a vector)
    %          With Kispi's old scoring program it corresponds to
    %          stages = visfun.numvis(vissymb, offs)
    %
    % *** OUTPUT
    % EEG:              EEG Data with interpolated epochs
    % artintp:          A structure containing several subfields. They 
    %                   contain the index of epochs or channels that 
    %                   fullfill certain criteria.
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
    % chansIGNORE:      Ignored channels
    %                   Ignored channels are channels that were not taken
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
    % classicCLEAN:     Conservative clean epochs
    %                   Epochs where all channels except those in exclChans
    %                   were good according to artndxn. In other words, in
    %                   case at least one channel was bad (except it
    %                   belonged to exclChans), it would not be considered
    %                   clean here.
    % cleanN1           Clean N1 epochs    
    %                   Artifact free N1 epochs, so epochs that were either
    %                   clean in all channels or had some bad channels but 
    %                   they all could be interpolated
    % cleanN2           Clean N2 epochs    
    % cleanN3           Clean N3 epochs      
    % *********************************************************************



    % Input parser
    p = inputParser;
    addParameter(p, 'plotFlag', 0, @isnumeric) % Do you want a plot?
    addParameter(p, 'stagesOfInterest', [-2 -3], @isnumeric) % Sleep stages to perform analysis on   
    addParameter(p, 'N1', -1, @isnumeric) % N1 as coded in sleep stages
    addParameter(p, 'N2', -2, @isnumeric) % N2 as coded in sleep stages
    addParameter(p, 'N3', -3, @isnumeric) % N3 as coded in sleep stages    
    addParameter(p, 'REM', 0, @isnumeric) % REM as coded in sleep stages        
    addParameter(p, 'chansToIgnore', [43 48 49 56 63 68 73 81 88 94 99 107 113 119 120 125 126 127 128], @isnumeric) % Indices of channels not taken into account to determine bad epochs
    addParameter(p, 'scoringlen', 20, @isnumeric) % Epoch length of scoring
    addParameter(p, 'visgood', [], @isnumeric) % Epochs that are labelled as clean during sleep scoring (manual artifact rejection), corresponds to: find(sum(vistrack') == 0);    
    parse(p, varargin{:});
        
    % Create variables
    for var = p.Parameters
        eval([var{1} '= p.Results.(var{1});']);
    end  

    % *** Start function
    % Epochs that can be interpolated
    intp = candiate_epos(artndxn, stages, EEG.chanlocs, ...
        'maxNumCloseChans', 2, ...
        'chansToIgnore', [49 56 107 113 126 127], ...
        'stagesOfInterest', stagesOfInterest, ...
        'chanDist', 0.4);    

    % Interpolate EEG
    EEG = epowise_interp(EEG, intp, ...
        'epolen', scoringlen, ...
        'displayFlag', 1);

    % Find clean and lost epochs
    epo = epo_assign(artndxn, stages, ...
        'stagesOfInterest', stagesOfInterest, ...
        'visgood', visgood, ...
        'badChanToNan', 0, ...
        'chansToIgnore', chansToIgnore);   

    % Epochs in different sleep stages
    cleanNREM   = sort(unique([intp.epo_intp epo.clean]));
    cleanN1     = intersect(cleanNREM, find(stages==N1));
    cleanN2     = intersect(cleanNREM, find(stages==N2));
    cleanN3     = intersect(cleanNREM, find(stages==N3));
    cleanREM    = intersect(cleanNREM, find(stages==REM));

    % AR during manual sleep scoring
    cleanMANUAL = intersect(visgood, find(ismember(stages, [N1 N2 N3])));

    % *** Output
    artintp.allNREM     = epo.all;    
    artintp.cleanNREM   = cleanNREM;
    artintp.cleanN1     = cleanN1;    
    artintp.cleanN2     = cleanN2;    
    artintp.cleanN3     = cleanN3;   
    artintp.cleanREM    = cleanREM;          
    artintp.interpNREM  = intp.epo_intp;  
    artintp.lostNREM    = intp.epo_lost;          
    artintp.cleanMANUAL = cleanMANUAL;    
    artintp.chansIGNORE = chansToIgnore;
    artintp.chansBAD    = epo.chans_bad;
        

    % *** Plotflag
    if plotFlag
        % Colors
        black = hex2rgb('#2d3436');
        third = hex2rgb('#d1d8e0');
        pink  = hex2rgb('#fc5c65');      

        % Open figure
        figure('color', 'w'); hold on
        set(gcf, 'Position', [400, 400, 150, 300]) 

        % Barplot
        Y = [numel(epo.clean), numel(intp.epo_intp), numel(intp.epo_lost)];
        b = bar(1, Y, 'stacked');
        b(1).FaceColor = black; 
        b(2).FaceColor = pink; 
        b(3).FaceColor = third;
        legend({'Clean epochs', 'Interpolated epochs', 'Lost epochs'}, 'Location', 'northoutside')
        xlim([.5 1.5]); xticks([]); ylabel('# Epochs (in sleep stages of interest)')
    end
end