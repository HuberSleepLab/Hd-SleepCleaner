% ### Plots
% ############################

% Compute SWA
SWA01  = select_band(M1.FFTtot, M1.freq, L1, L2, stages_of_interest, [], chans_excl);         % Before artifact rejection
SWA02  = select_band(M1.FFTtot, M1.freq, L1, L2, stages_of_interest, artndxn, chans_excl);    % After artifact rejection
SWA03  = select_band(M2.FFTtot, M2.freq, L1, L2, stages_of_interest, artndxn, chans_excl);    % After artifact rejection

% Compute averages
SWA01x = mean(SWA01, 2, 'omitnan');
SWA02x = mean(SWA02, 2, 'omitnan');
SWA03x = mean(SWA03, 2, 'omitnan');

% *** Open figure
figure('color', 'w') 
hold on;
set(gcf, 'Position', [400, 400, 800, 600])

% Figure settings
width  = 0.25;
height = 0.25;


% *** Plot SWA
subplot('Position', [0.40 0.68 width height ]);
plot(SWA01', 'k.:')
ylabel(sprintf('Power (%.1f - %.1f Hz, %cV^2)', L1, L2, 956))

subplot('Position', [0.40 0.38 width height ]);
plot(SWA02', 'k.:')

subplot('Position', [0.40 0.08 width height ]);
plot(SWA03', 'k.:')
xlabel('Epoch')

% Load colormap
load('L18.mat');


% *** Topoplot overnight SWA
if EEG.nbchan > 1
    subplot('Position', [0.001 0.68 width+0.05 height ]);
    topoplot( SWA01x, EEG.chanlocs, ...
        'plotchans', 1:numel(SWA01x), ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'maplimits', [min(SWA01x) max(SWA01x)], ...    
        'electrodes','on', 'headrad','rim', 'intrad',.7, 'plotrad',.7, 'colormap', L18);
    
    % Colorbar
    p1=get(gca, 'Position'); 
    cbar=colorbar();
    set(gca, 'Position', p1);   
    ylabel(cbar, sprintf('Power (%.1f - %.1f Hz, %cV^2)', L1, L2, 956))
    title(sprintf('Whole-night\nRaw, original ref'))
    
    % Topoplot
    subplot('Position', [0.001 0.38 width+0.05 height ]);
    topoplot( SWA02x, EEG.chanlocs, ...
        'plotchans', 1:numel(SWA02x), ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'maplimits', [min(SWA02x) max(SWA02x)], ...    
        'electrodes','on', 'headrad','rim', 'intrad',.7, 'plotrad',.7, 'colormap', L18);
    
    % Colorbar
    p1=get(gca, 'Position'); 
    cbar=colorbar();
    set(gca, 'Position', p1);   
    title(sprintf('Clean, original ref'))
    
    % Topoplot
    subplot('Position', [0.001 0.08 width+0.05 height ]);
    topoplot( SWA03x, EEG.chanlocs, ...
        'plotchans', 1:numel(SWA03x), ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'maplimits', [min(SWA03x) max(SWA03x)], ...    
        'electrodes','on', 'headrad','rim', 'intrad',.7, 'plotrad',.7, 'colormap', L18);
    
    % Colorbar
    p1=get(gca, 'Position'); 
    cbar=colorbar();
    set(gca, 'Position', p1);   
    ylabel(sprintf('Power (%.1f - %.1f Hz, %cV^2)', L1, L2, 956))
    title(sprintf('Clean, average ref'))
end

% *** Clean sleep epochs after manual artifact rejection
cleanThresh     = .97;
exclChans       = [];

% Percentage of clean sleep epochs after semi-automatic artifact remoal
prcnt_cleanEPO  = sum(artndxn(:, stages_of_interest), 2) ./ size(artndxn(:, stages_of_interest), 2) * 100;

% Compute bad channels
ndx_chansBAD  = find(prcnt_cleanEPO < cleanThresh)';     % Bad channels < "98%" good epochs
ndx_chansEXCL = unique([ndx_chansBAD, exclChans]);       % Bad channels + excluded channels

% Pre-allocate
prcnt_epolow  = prcnt_cleanEPO;
prcnt_epoexcl = prcnt_cleanEPO;        

% Set to nan, so that bars have right color
prcnt_cleanEPO(prcnt_cleanEPO == 0)                             = nan;  
prcnt_epolow(prcnt_epolow >= cleanThresh)                       = nan;  
prcnt_epoexcl(setdiff(1:size(prcnt_cleanEPO, 1), exclChans), :) = nan;     
    
% Plot bars
subplot('Position', [0.73 0.08 width 0.85 ]);
barh(prcnt_cleanEPO, 'DisplayName', 'Good channels'); hold on;
barh(prcnt_epoexcl, 'FaceColor', uint8([200 200 200]), 'DisplayName', 'Excl. channels');
barh(prcnt_epolow, 'r', 'DisplayName', 'Bad channels');

% Make pretty
% xlim([min([prcnt_cleanEPO; cleanThresh])*100 100]); 
xlabel(sprintf('Proportion of clean epochs (%%)\nin sleep stages %s', num2str(stages))); ylabel('Channel ID'); yticks(4:4:size(EEG.data, 1)); ylim([1 size(artndxn, 1)]);
plot(repmat(cleanThresh, 1, length(prcnt_cleanEPO)), 1:length(prcnt_cleanEPO), ':', 'LineWidth', 2, 'DisplayName', 'Threshold')
if EEG.nbchan > 1
    ylim([1 size(artndxn, 1)]);
end
% legend('Location', 'North', 'Orientation','horizontal');    