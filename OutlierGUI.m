function [ output ] = manoutGUI(Y, varargin)

% *************************************************************************
%
% This function opens a GUI to manually remove outliers in your input
% data "Y". Your matrix should be in the format (channel x epochs).
%
% You can call the function as follows:
% [ output ] = manoutGUI(SWA);
%
%
%
% Optional input arguments:
% 'sleep', [1 1 0 -2 -2 ..]     To display the hypnogram in a seperate
%                               subplot underneath your data. The vector
%                               needs to have the sleep stages coded as
%                               follows:
%                               1: wake 0: REM -1: N1 -2: N2 -3: N3
% 'X', [1 2 4 6 ..]             Plot your Y values against specific X
%                               values if you want
% 'EEG', chans x samples        A matrix containing EEG Data. Needed if you
%                               want to visualize the actual EEG of brushed
%                               datapoints.
% 'srate', 125                  The Sampling rate of your EEG data, to get
%                               the x axis right (the time axis)
% 'chanlocs', chanlocs          Channel locations if you want to plot a
%                               topoplot 
% 'topo', chans x epochs        You can specify different data for 
%                               topoplots if you prefer. Otherwise input
%                               data Y is used for topoplots
% 'spectrum', ch x freq x epo   You can plot the power spectrum of each
%                               channel if you want
% 'fres', 0.25                  Frequency resolution of power spectrum
%
% Output:
% A structure with the following subfields:
% 'cleanVALUES'                 Same as the input values Y, but all removed
%                               datapoints are set to NaN
% 'cleandxnz'                    Indicates which of the input values Y
%                               survived the artifact rejection
%
% *************************************************************************

close all

% Turn off warnings
warning('off','all')

% Input parser
p = inputParser;
addParameter(p, 'sleep', [], @isnumeric)             % Sleep scoring  
addParameter(p, 'X', 1:size(Y, 2), @isnumeric)       % X Vector for plots
addParameter(p, 'EEG', [], @isnumeric)               % EEG Data
addParameter(p, 'srate', 125, @isnumeric)            % Sampling rate of EEG data
addParameter(p, 'chanlocs', [], @isstruct)           % Channel locations
addParameter(p, 'topo', Y, @isnumeric)               % Data for topoplots
addParameter(p, 'spectrum', [], @isnumeric)          % Data for pwoer spectrum
addParameter(p, 'fres', 0.25, @isnumeric)            % Frequency resolution of power spectrum
addParameter(p, 'epo_thresh', 8, @isnumeric)         % 
addParameter(p, 'epo_select', [], @isnumeric)        % Only show specific epochs
addParameter(p, 'epo_len', 20, @isnumeric)           % Length of epochs (in s)
addParameter(p, 'main_title', 'Main plot', @ischar)  % Title of main plot
addParameter(p, 'amp_ylabel', 'Amplitude', @ischar)  % Title of main plot

parse(p, varargin{:});
    
% Assign variables
sleep       = p.Results.sleep;
X           = p.Results.X;
EEG         = p.Results.EEG;
srate       = p.Results.srate;
chanlocs    = p.Results.chanlocs;
topo        = p.Results.topo;
spectrum    = p.Results.spectrum;
fres        = p.Results.fres;
epo_thresh  = p.Results.epo_thresh;
epo_select  = p.Results.epo_select;
epo_len     = p.Results.epo_len;
main_title  = p.Results.main_title;
amp_ylabel  = p.Results.amp_ylabel;

% Preallocate
cleandxnz = [];
artndxnz = [];

% Variables
markersize = 8;
linewidth  = 0.1;
fmax       = 30;  % Hz
barthresh  = 97;  % Percent
fontsize   = 12;

% Load colormap
L18 = [];
load('L18.mat');


% ********************
%   Specific epochs 
% ********************  

if ~isempty(epo_select)

    % Save original
    YOrigin     = Y;

    % Select specified epochs
    sleep       = sleep(epo_select);
    Y           = Y(:, epo_select);
    topo        = topo(:, epo_select);
    spectrum    = spectrum(:, :, epo_select);
    X           = 1:numel(epo_select);

    % Select specified EEG data
    samples = cell2mat(arrayfun(@(x) x*epo_len*srate - epo_len*srate+1 : x*epo_len*srate, epo_select, 'Uni', 0));
    EEG     = EEG(:, samples);

end

% ********************
%   Set up figure
% ********************

% Open figure
f = figure('color', 'w');

% Set figure size
set(gcf, ...
    'units', 'normalized', ...
    'outerposition', [0.02 0.03 0.96 0.9], ...
    'Position', [0.02,0.1,1,0.82] ...
    );


% ********************
%   Prepare subplots
% ********************

% Variables
left       = 0.10;
bottom_low = 0.05;
bottom_up  = 0.44;
height_low = 0.33;
height_up  = 0.54;
width_left = 0.77;

% Turn brush on
brushf = brush;
set( brushf, ...
    'ActionPreCallback', @fixkeypress, ...
    'enable', 'on' );

% Main plot
s1 = subplot('Position', [left bottom_up+.12 width_left height_up-.12]);
p  = plot_main(X, Y);   

% Hypnogram
if ~isempty(sleep)
    xticklabels({});            
    s2 = subplot('Position', [left bottom_up width_left 0.11]);
    bar(1:1:length(X), sleep); 
    yticks(-2.5:0.5);
    yticklabels({'N3', 'N2', 'N1', 'W'});
    ylim([-3 1]);
    linkaxes([s1, s2], 'x');
%     title('Hypnogram');  
    ylabel('Sleep stages');
    xlim(handles.xlim_original)
end
xlabel('Epoch'); 

% Barplot
s3 = subplot('Position', [0.90 bottom_up 0.08 height_up]); 
plot_bar(Y, zeros(size(Y)));
% barh(repmat(100, 1, size(Y, 1)))
% xlabel('(%) survived epochs'); 
% ylabel('Channel ID');

% Prepare spectral power
s4 = subplot('Position', [left+0.72 bottom_low 0.16 height_low]);
plotPSD = plot_ps2D(spectrum, ~isnan(Y));

% Prepare EEG
s5 = subplot('Position', [left bottom_low width_left-0.27 height_low]);
plotEEG = yline(0, 'HandleVisibility','off');
xline([0 epo_len], 'k:', 'HandleVisibility','off')
legend(); ylabel(amp_ylabel); xlabel('time (s)'); xlim([-10 (epo_len+10)]);
title('EEG (brushed epochs)');  

% Prepare topoplot
s6 = subplot('Position', [left+0.51 bottom_low 0.16 height_low]);
topoplotGUI(zeros(1, size(Y, 1)), [0 1], []);
title('Topoplot (brushed epochs)');    
 
% Aesthethics
set(findobj(gcf,'type','axes'), ...
    'FontSize', 10);


% ********************
%       Handles
% ********************

% Assign handles
handles.Y               = Y;                    % Data to be plotted
handles.X               = X;                    % X Axis
handles.Y0              = Y;                    % Copy of data
handles.brushNDX        = cell(size(Y, 1), 1);  % Brushed data points
handles.sleep           = sleep;                % Sleep scoring
handles.p               = p;                    % Plot handle (black dots)
handles.po              = plot([], []);         % Plot handle (red circles)
handles.EEG             = EEG;                  % EEG Data
handles.srate           = srate;                % Sampling rate
handles.topo            = topo;                 % Topoplot data
handles.topo0           = topo;                 % Copy of topoplot data
handles.spectrum        = spectrum;             % Power spectrum
handles.plotPSD         = plotPSD;              % Plot of power spectrum
handles.plotEEG         = plotEEG;              % Plot of EEG
handles.plotEEG0        = [];                   % Toggle whether EEG was filtered for the first time
handles.firstfilter     = 1;                    % Toggle whether EEG was filtered for the first time
handles.chans_highlighted = [];                 % Highlights these channels in main plot
handles.lpfilter        = [];                   % Initialize filter
handles.hpfilter        = [];                   % Initialize filter

% Channel outlier detection
[handles.Y handles.topo handles.channel_outlier] = channel_outlier(handles.Y, handles.topo, epo_thresh);    
[handles.Y handles.topo handles.movavg_outlier] = movavg_outlier(handles.Y, handles.topo, 8);    
update_main

% Throw handles to figure
guidata(f, handles)


% ********************
%     Set up GUI
% ********************

% Variables
button_width_small  = 0.055;
button_left_small   = 0.0125;
button_height_small = 0.05;
panel_width         = 0.065;
panel_left          = 0.0075;
panelbutton_left    = 0.04;
panelbutton_width   = 0.92;

% Panel properties
panelprops = [];
panelprops.units = 'normalized';

% UI Control properties
UIprops = [];
UIprops.units     = 'normalized';
UIprops.FontUnits = 'normalized';
UIprops.Style     = 'pushbutton';
UIprops.fontsize  = 0.48;

% Panels
panel01 = uipanel(f, panelprops, ...  
    'title', 'Figure manipulation', ...    
    'Position', [panel_left 0.78 panel_width 0.16]);
panel02 = uipanel(f, panelprops, ...  
    'title', 'Plot functions', ...    
    'Position', [panel_left 0.66 panel_width 0.10]);
panelOUT = uipanel(f, panelprops, ...  
    'Position', [panel_left 0.52 panel_width 0.12], ...
    'title', 'Automatic outlier detection');
panelCHAN = uipanel(f, panelprops, ...  
    'Position', [panel_left 0.34 panel_width 0.16], ...
    'title', 'Channel manipulations');
panelFILTER = uipanel(f, panelprops, ...  
    'Position', [panel_left 0.24 panel_width 0.08], ...
    'title', 'Filter EEG');

% Distances (vertical and hortizontal)
D01v = 0.13; D01h = 0.04;
D02v = 0.18; D02h = 0.04;
D03v = 0.22; D03h = 0.04;

% Push buttons panel01 ("Figure manipulation")
uicontrol(f, UIprops, ...
    'string', 'Done', ...
    'position', [button_left_small 0.045 button_width_small button_height_small], ...
    'BackgroundColor', [0 0.4470 0.7410], ...    
    'callback', @cb_done);  
uicontrol(panel01, UIprops, ...
    'string', 'Remove datapoint [R]', ...
    'position', [panelbutton_left D01h+D01v*6 panelbutton_width D01v], ...
    'callback', @cb_del_brushdata);
uicontrol(panel01, UIprops, ...
    'string', 'Restore datapoint ', ...
    'position', [panelbutton_left D01h+D01v*5 panelbutton_width D01v], ...
    'callback', @cb_restore_brushdata);
uicontrol(panel01, UIprops, ...
    'string', 'Restore all/br. epochs [F]', ...
    'position', [panelbutton_left D01h+D01v*4 panelbutton_width D01v], ...
    'callback', @cb_restore_all); 
uicontrol(panel01, UIprops, ...
    'string', 'Restore Y-Axis', ...
    'position', [panelbutton_left D01h+D01v*3 panelbutton_width D01v], ...
    'callback', @cb_yaxis_restore); 
uicontrol(panel01, UIprops, ...
    'string', 'Remove chans (Spectrum)', ...
    'position', [panelbutton_left D01h+D01v*2 panelbutton_width D01v], ...
    'callback', @cb_remove_powerspectrum); 
uicontrol(panel01, UIprops, ...
    'string', 'Show chans (Spectrum)', ...
    'position', [panelbutton_left D01h+D01v*1 panelbutton_width D01v], ...
    'callback', @cb_show_powerspectrum); 
uicontrol(panel01, UIprops, ...
    'string', 'Remove chans (EEG) [H]', ...
    'position', [panelbutton_left D01h panelbutton_width D01v], ...
    'callback', @cb_remove_eeg); 

% Push buttons panel02 ("Plot functions")
UIprops.fontsize  = 0.6;
uicontrol(panel02, UIprops, ...
    'string', 'EEG all channels [G]', ...
    'position', [panelbutton_left D02h+D02v*0 panelbutton_width D02v], ...
    'callback', @cb_plotEEG_allchans); 
uicontrol(panel02, UIprops, ...
    'string', 'EEG [T]', ...
    'position', [panelbutton_left D02h+D02v*1 panelbutton_width D02v], ...
    'callback', @cb_plotEEG); 
uicontrol(panel02, UIprops, ...
    'string', 'Topo (epoch) [Z]', ...
    'position', [panelbutton_left D02h+D02v*2 panelbutton_width D02v], ...
    'callback', @cb_topo_brush); 
uicontrol(panel02, UIprops, ...
    'string', 'Topo (night)', ...
    'position', [panelbutton_left D02h+D02v*3 panelbutton_width D02v], ...
    'callback', @cb_topo_night); 
uicontrol(panel02, UIprops, ...
    'string', 'Topo (video)', ...
    'position', [panelbutton_left D02h+D02v*4 panelbutton_width D02v], ...
    'callback', @cb_topo_video); 

% Other Push buttons
UIprops.fontsize  = 0.5;
uicontrol(panelFILTER, UIprops, ...
    'string', 'Filter currently plotted EEG', ...
    'position', [panelbutton_left D03h+D03v*3 panelbutton_width D03v], ...
    'callback', @push_filter); 

% Other Toggle buttons
UIprops.Style    = 'toggle';
isfilter = uicontrol(panelFILTER, UIprops, ...
    'string', 'Autofilter OFF (click to turn ON)', ...
    'position', [panelbutton_left D03h+D03v*2 panelbutton_width D03v], ...
    'callback', @toggle_filter); 

% Text fields panelOUT ("Automatic outlier detection")
UIprops.Style               = 'text';
UIprops.fontsize            = 1;
uicontrol(panelOUT, UIprops, ...
    'string', 'Find outlier channel (per epoch)', ...
    'HorizontalAlignment', 'Left', ...    
    'position', [panelbutton_left 0.82 panelbutton_width 0.07]);  
uicontrol(panelOUT, UIprops, ...
    'fontsize', 0.8, ...
    'string', 'Channel mean (per epoch) + x*sd', ...
    'position', [panelbutton_left 0.58 panelbutton_width 0.07]);  
uicontrol(panelOUT, UIprops, ...
    'fontsize', 0.8, ...
    'string', sprintf('(Default x=%d)', epo_thresh), ...
    'position', [panelbutton_left 0.52 panelbutton_width 0.07]);  
uicontrol(panelOUT, UIprops, ...
    'string', 'Find outlier epoch (per channel)', ...
    'HorizontalAlignment', 'Left', ...    
    'position', [panelbutton_left 0.32 panelbutton_width 0.07]);      
uicontrol(panelOUT, UIprops, ...
    'fontsize', 0.8, ...
    'string', '40 epochs moving average + x*sd', ...
    'position', [panelbutton_left 0.08 panelbutton_width 0.07]);  
uicontrol(panelOUT, UIprops, ...
    'fontsize', 0.8, ...
    'string', sprintf('(Default x=%d)', epo_thresh), ...
    'position', [panelbutton_left 0.02 panelbutton_width 0.07]);  

% Edit buttons panelOUT
UIprops.Style     = 'edit';
UIprops.fontsize  = 0.6;
meanthresh_edit = uicontrol(panelOUT, UIprops, ...
    'string', sprintf('%d', epo_thresh), ...
    'position', [panelbutton_left 0.65 panelbutton_width 0.15], ...
    'callback', @cb_meanthresh);  
movavg_thresh = uicontrol(panelOUT, UIprops, ...
    'string', sprintf('%d', epo_thresh), ...
    'position', [panelbutton_left 0.15 panelbutton_width 0.15], ...
    'callback', @cb_movavg_outlier);  

% Text fields panelCHAN ("Channel manipulations")
UIprops.Style     = 'text';
UIprops.fontsize  = .55;
D01tv=0.33; D01ev=0.33;
uicontrol(panelCHAN, UIprops, ...
    'string', 'Exlude/Include channels', ...
    'HorizontalAlignment', 'Left', ...    
    'position', [panelbutton_left 0.14+D01ev*2 panelbutton_width 0.1]);  
uicontrol(panelCHAN, UIprops, ...
    'HorizontalAlignment', 'Left', ...        
    'string', 'Plot EEG (of brushed epochs)', ...
    'position', [panelbutton_left 0.14+D01ev  panelbutton_width 0.1]);  
uicontrol(panelCHAN, UIprops, ...
    'string', 'Highlight channels (in main plot)', ...
    'HorizontalAlignment', 'Left', ...    
    'position', [panelbutton_left 0.14 panelbutton_width 0.1]);       

% Edit buttons panelCHAN
UIprops.Style    = 'edit';
UIprops.fontsize = 0.4;
chanexcl_edit = uicontrol(panelCHAN, UIprops, ...
    'string', 'Channel IDs', ...
    'position', [panelbutton_left 0.02+D01tv*2 panelbutton_width 0.15], ...
    'callback', @cb_chanexcl);  
eeg_chans = uicontrol(panelCHAN, UIprops, ...
    'string', 'Channel IDs', ...
    'position', [panelbutton_left 0.02+D01tv panelbutton_width 0.15], ...
    'callback', @cb_eeg_chans);  
main_chans = uicontrol(panelCHAN, UIprops, ...
    'string', 'Channel IDs', ...
    'position', [panelbutton_left 0.02 panelbutton_width 0.15], ...
    'callback', @ch_main_onechan); 

% Text fields panelFILTER ("Filter EEG")
UIprops.Style     = 'text';
UIprops.fontsize  = .4;
uicontrol(panelFILTER, UIprops, ...
    'string', 'Lower cut-off (Hz)', ...
    'position', [panelbutton_left 0.13 panelbutton_width/2 0.25]);
uicontrol(panelFILTER, UIprops, ...
    'string', 'Upper cut-off (Hz)', ...
    'position', [panelbutton_left+panelbutton_width/2 0.13 panelbutton_width/2 0.25]);

% Edit buttons panelFILTER ("Filter EEG") 
UIprops.Style    = 'edit';
UIprops.fontsize = 0.4;
low_cutoff = uicontrol(panelFILTER, UIprops, ...
    'string', sprintf('> %.1f', 0), ...
    'position', [panelbutton_left 0.02 panelbutton_width/2 0.25], ...
    'callback', @edit_cutoff); 
up_cutoff = uicontrol(panelFILTER, UIprops, ...
    'string', sprintf('< %.1f', srate/3), ...
    'position', [panelbutton_left+panelbutton_width/2 0.02 panelbutton_width/2 0.25], ...
    'callback', @edit_cutoff); 

% ********************
%   Build Functions
% ********************

% *** Filter functions

% Update EEG with filtered EEG
% if it is already plotted
function push_filter( src, event )
    handles = guidata(src); 

    % Filtered first time?
    if handles.firstfilter

        % EEG Data (plotted)
        YNow = get(handles.plotEEG, 'YData');

        % Save original EEG
        handles.plotEEG0 = YNow; 

        % Toggle
        handles.firstfilter = 0;

    else
        YNow = handles.plotEEG0;
    end

    % Make it a cell
    if ~iscell(YNow)
        YNow = {YNow}; end

    % Length of signal
    L = length(YNow{1});

    % Miror signal to the sides for filter edge artifacts
    YFilter = cellfun(@(x) [flip(x) x flip(x)], YNow, 'Uni', 0);

    % Filter EEG Lines
    if ~isempty(handles.lpfilter)
        YFilter = cellfun(@(x) filtfilt(handles.lpfilter, double(x)), YFilter, 'Uni', 0);
    end
    if ~isempty(handles.hpfilter)
        YFilter = cellfun(@(x) filtfilt(handles.hpfilter, double(x)), YFilter, 'Uni', 0);
    end        

    % Select only real data
    YFilter = cellfun(@(x) x(L+1 : L*2), YFilter, 'Uni', 0);        

    % Update EEG Lines
    for ichannel = 1:size(YFilter, 1)
        set(handles.plotEEG(ichannel), 'YData', YFilter{ichannel});
    end

%     % Adapt Y Axis
%     adjust_ylimEEG(handles) 

    % Update handles
    guidata(gcf, handles);       
end

% Changes lower cut off of filter
function edit_cutoff( src, event )
    handles = guidata(src);  

    % Filter cut offs
    lc = str2num(get(low_cutoff, 'String'));    
    hc = str2num(get(up_cutoff, 'String'));   

    % Update filter
    if ~isempty(hc)
        handles.lpfilter = build_lpfilter( hc );
    else
        handles.lpfilter = [];
    end
    if ~isempty(lc)
        handles.hpfilter = build_hpfilter( lc );
    else
        handles.hpfilter = [];
    end    

    % Update handles
    guidata(gcf, handles);    

    % Apply filter
    push_filter( src, event )
end

% Build filter to filter EEG that is plotted in the GUI
function hpfilter = build_hpfilter( lc )

    % Build filter
    hpfilter = designfilt( ...
        'highpassiir', ...
        'StopbandFrequency', lc*0.5, ...
        'PassbandFrequency', lc, ...
        'StopbandAttenuation', 60, ...
        'PassbandRipple', 0.1, ...
        'SampleRate', srate, ...
        'DesignMethod', 'cheby2' ...
        );
end
function lpfilter = build_lpfilter( hc )

    % Build filter
    lpfilter = designfilt( ...
        'lowpassiir', ...
        'StopbandFrequency', hc*1.5, ...
        'PassbandFrequency', hc, ...
        'StopbandAttenuation', 60, ...
        'PassbandRipple', 0.1, ...
        'SampleRate', srate, ...
        'DesignMethod', 'cheby2' ...
        );
end

% Toggle filter name
function toggle_filter( src, event )

    if isfilter.Value
        isfilter.String = 'Autofilter ON (click to turn OFF)';
    end
    if ~isfilter.Value
        isfilter.String = 'Autofilter OFF (click to turn ON)';
    end    
end


% *** Power spectrum



function cb_power_spectrum( src, event )
    % Button callback: 
    % plot power spectrum

    handles = guidata(src);                             % Grab handles                  
    handles.plotPSD = plot_ps2D(handles.spectrum, handles.cleandxnz);     % Plot power spectrum
end

function plotPSD = plot_ps2D(ps3D, clean2D)
    % Plots power spectrum of 
    % all channels on top of each other

    % Compute power spectrum 
    ps2D = compute_ps2D(ps3D, clean2D);         
%     ps2D = (ps2D - mean(ps2D, 1)) ./ std(ps2D, [], 1);    

    % Plot power spectrum
    axes(s4);
    plotPSD = plot( 0:fres:fmax, log10(ps2D)', ...
        'LineWidth', linewidth);
        xlabel('Freq (Hz)'); 
        ylabel('Log_{PSD}');
    title('Spectral power (clean epochs)');

    % Rainbowcolor
    rainbow = MapRainbow([chanlocs.X], [chanlocs.Y], [chanlocs.Z], 0);
    colororder(s4, rainbow);   
end

function ps2D = compute_ps2D(ps3D, clean2D)
    % Computes power spectrum
    % for all channels in clean epochs

    clean3D         = clean_3D(clean2D, ps3D);
    ps3D(~clean3D)  = nan;                            % Clean spectrum
    ps2D            = mean(ps3D, 3, 'omitnan');       % Mean over epochs
    ps2D            = ps2D(:, 1:fmax/fres+1);         % Frequencies 1 to 30
end

function clean3D = clean_3D(clean2D, ps3D)
    % Creates 3D matrix to
    % index into 3D PSD matrix

    clean3D  = repmat(clean2D, 1, 1, size(ps3D, 2));  % Add 3rd dimension
    clean3D  = permute(clean3D, [1 3 2]);             % Change dimensions
end

function cb_remove_powerspectrum( src, event )

    handles     = guidata(src);                                                  % Grab handles  
    brushNDX    = cellfun(@find, get(handles.plotPSD, 'BrushData'), 'Uni', 0);   % Gather brushed data

    % Set brushed data to NaN
    for ichan = 1:numel(brushNDX)
        if ~isempty(brushNDX{ichan})
            handles.Y(ichan, :) = nan;
            handles.topo(ichan, :) = nan;  
        end       
    end    

    % Update guidata
    update_main(src, event)
end

function cb_show_powerspectrum( src, event )
    % Highlight channels selected in power spectrum in main plot

    handles     = guidata(src);                                                  % Grab handles  
    brushNDX    = cellfun(@find, get(handles.plotPSD, 'BrushData'), 'Uni', 0);   % Gather brushed data
    chans       = find(~cellfun(@isempty, brushNDX))';                            % Selected channels

    % Highlight channels in main plot
    [handles.p, handles.chans_highlighted] = highlight_chans(handles.X, handles.Y, handles.p, chans);    

    % Update guidata
    guidata(gcf, handles);      % Update handles        
end



% *** Barplot (percentage clean epochs)

function plot_bar(Y0, artndxnz)
    % Plots power spectrum of 
    % all channels on top of each other

    % Percentage correct
    [prc1, prc2] = compute_bar(Y0, artndxnz);   

    % Plot bars
    axes(s3);
    barh(prc1); hold on;          % Good channels
    barh(prc2, 'r'); hold off;     % Bad channels

    % Compute astethics
    xmin = min([prc1; 95]) - 1;
    ymax = length(prc1);
    
    % Make pretty
    xlim( [xmin 100 ] )
    yticks( [4:4:ymax] )
    ylim( [1 ymax] )
    xlabel('(%) survived epochs') 
    ylabel('Channel ID')     
    grid on
end

function [prc1, prc2] = compute_bar(Y0, artndxnz)
    % Computes percentage 
    % correct in each channel

    numNAN   = sum(isnan(Y0));
    nonanEPO = numNAN == min(numNAN);  % Epochs that contained values
    prc1  = sum(~artndxnz(:, nonanEPO), 2, 'omitnan') ...
        ./ sum(nonanEPO, 'omitnan') * 100;      % Percentage of clean sleep epochs
    prc2 = prc1;                       % Percentage of bad sleep epochs
    prc2(prc2 >= barthresh) = nan;          

end

function cb_plot_bar( src, event )
    % Callback:
    % Barplot (percentage clean epochs)

    handles = guidata(src);                    % Grab handles                  
    plot_bar(handles.Y0, handles.artndxnz);    % Plot bar
end



% *** Topoplots

function topoplotGUI(vTopo1, limits, chanstopo)
    % Plots a nice topoplot

    % 'plotchans', setdiff(1:129, [49 56 107 113, 126, 127]), ...
    topoplot( vTopo1, chanlocs, ...
        'plotchans', 1:128, ...
        'maplimits', limits, ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'electrodes','numbers', 'headrad',.5, 'intrad',.7, 'plotrad',.7, 'colormap', L18);
    topoplot( vTopo1, chanlocs, ...
        'plotchans', 1:128, ...
        'maplimits', limits, ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'emarker2', {chanstopo,'.','k',16}, ...   
        'electrodes','on', 'headrad',.5, 'intrad',.7, 'plotrad',.7, 'colormap', L18); title('All values');         
        xlim([-.55 .55]) % To show the whole nose
        ylim([-.55 .6])  % To show the whole ear   

    % Colorbar
    p1=get(gca, 'Position'); 
    cbar=colorbar();
    set(gca, 'Position', p1);          
end

function cb_topo_night( src, event )
    % Callback:
    % Plot topoplot

    % Create new figure
    figure('color', 'w', ...
        'units', 'normalized', ...
        'outerposition', [0.3 0.4 0.4 0.25], ...
        'Position', [0.3 0.4 0.4 0.25] ...
        ); 
 
    % Original topoplot
    vTopo1 = mean(handles.topo0, 2, 'omitnan');

    % Without outliers
    vTopo2 = handles.topo0;
    vTopo2(isnan(handles.Y)) = nan;
    vTopo2 = mean(vTopo2, 2, 'omitnan');   

    % Colorbar limits
    % limits = [prctile([vTopo1; vTopo2], 1)  prctile([vTopo1; vTopo2], 99)];
    limits1 = [prctile([vTopo1], 1)  prctile([vTopo1], 99)];
    limits2 = [prctile([vTopo2], 1)  prctile([vTopo2], 99)];
    
    % Topoplots
    subplot(121); topoplotGUI(vTopo1, limits1, []); title('All values');          
    subplot(122); topoplotGUI(vTopo2, limits2, []); title('Clean values');      
end

function cb_topo_brush( src, event )
    % plot topoplot

    % Brushed data
    handles    = guidata(src);                  % Grab handles  
    brushNDX   = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);  % Gather brushed data
    chansNDX   = find(cellfun(@isempty, brushNDX) == 0);                % Gather brushed channels

    % Compute values
    vTopo1 = max(handles.topo(:, [brushNDX{:}]), [], 2, 'omitnan');
    limits = [min(vTopo1) max(vTopo1)];

    % Black dots
    chanstopo = chansNDX;
    for ich = 1:length(chanstopo)      
        chanstopo(ich) = chansNDX(ich) - sum( find(isnan(vTopo1)) <= chansNDX(ich) );
    end    
   
    % Topoplot
    axes(s6);
    cla(s6, 'reset');   
    topoplotGUI(vTopo1, limits, chanstopo); title('Topoplot (brushed epochs)');         
end

function cb_topo_video( src, event )
    % plot topoplot

    % Create new figure
    fvideo = figure('color', 'w', ...
        'units', 'normalized', ...
        'outerposition', [0.3 0.4 0.25 0.3], ...
        'Position', [0.3 0.4 0.25 0.3], ...
        'Tag', 'fvideo'...
        ); 
    vTopo = handles.topo;
    epos  =  find(sum(isnan(vTopo)) < size(vTopo, 1));

    % Brushed data
    brushNDX   = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);  % Gather brushed data    
    brushEPO   = unique([brushNDX{:}]);

    % Intersect
    if ~isempty(brushEPO)
        epos = intersect(epos, brushEPO);
    end
     
    % Compute values
    for epo = epos
        vTopo = handles.topo(:, epo);
        limits = [prctile([vTopo], 1)  prctile([vTopo], 99)];
        if ishandle(fvideo)
            cla            
            topoplotGUI(vTopo, limits, []); title(sprintf('Epo %d', epo)); 
            drawnow();
            pause(0.01);                
        else
            fprintf('Closed Topo (video)')
            break
        end       
    end
    try
        close(fvideo)
    end
end



% *** Plot EEG

function cb_plotEEG( src, event )
    % Callback:
    % Plot Brushed EEG Data

    % Gather brushed data
    brushVAL  = get(handles.p, 'YData');    
    brushNDX = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);

    % Gather brushed data from rejected datapoints
    brushVAL0 = get(handles.po, 'YData');    
    brushNDX0 = cellfun(@find, get(handles.po, 'BrushData'), 'Uni', 0);
    [handles.po.BrushData] = deal([]);    
    
    % Brushed data
    brushNDX2 = [brushNDX, brushNDX0];
    brushNDX2 = arrayfun(@(row) [brushNDX2{row, :}], (1:size(brushNDX2,1))', 'Uni', false);

    % Rainbowcolor
    rainbow = MapRainbow([chanlocs.X], [chanlocs.Y], [chanlocs.Z], 0);

    % Plot brushed data    
    axes(s5);
    hold off    
    handles.plotEEG = [];
    for ch = 1:numel(brushNDX2)
        epos = brushNDX2{ch};
        for epo = epos
            if epo == 1 
                X    = linspace(0, (epo_len+10), (epo_len+10)*handles.srate);
                XT   = epo * epo_len * handles.srate - handles.srate * epo_len + 1 : epo * epo_len * handles.srate + 10 * handles.srate;                   
            elseif epo == size(handles.Y, 2)
                X    = linspace(-10, epo_len, (epo_len+10)*handles.srate);  
                XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 0 * handles.srate;                   
            else               
                X    = linspace(-10, (epo_len+10), (epo_len+20)*handles.srate);
                XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 10 * handles.srate;   
            end
            EEG  = handles.EEG(ch, XT);
            Y    = brushVAL{ch}(epo);
            plot(X, EEG, ...
                'LineWidth', .8, ...
                'DisplayName', sprintf('Ch %d, EPO %d, Y=%.2f', ch, epo, Y), ...
                'color', rainbow(ch, :));
            hold on;
        end
    end
    handles.plotEEG = s5.Children;
    handles.firstfilter = 1;
    xline([0 epo_len], 'k:', 'HandleVisibility','off')
    legend(); ylabel(amp_ylabel); xlabel('time (s)')
    title('EEG (brushed epochs)');

    % Filter EEG Toggle
    if isfilter.Value
        guidata(gcf, handles); 
        push_filter( src, event )
    end

    % Adjust Y ylimits
    adjust_ylimEEG(handles)

    guidata(gcf, handles);     % Update handles       
end

function adjust_ylimEEG(handles)
        ydata = get(handles.plotEEG, 'YData');
        if ~isempty(ydata)
            if ~iscell(ydata)
                ydata = {ydata};
            end
            data20s = cellfun(@(x) x( 10*handles.srate : (epo_len+10)*handles.srate ), ydata, 'Uni', 0);
            ylim2 = max(cellfun(@max, data20s)) + max(cellfun(@max, data20s)) / 20;
            ylim1 = min(cellfun(@min, data20s)) - min(cellfun(@max, data20s)) / 20;
            ylim([ylim1, ylim2])   
        end
    end

function cb_plotEEG_allchans( src, event )
    % Callback:
    % Plot Brushed Epochs all channels EEG Data

    % Gather brushed data
    brushVAL  = get(handles.p, 'YData');    
    brushNDX  = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);

    % Gather brushed data from rejected datapoints
    brushVAL0 = get(handles.po, 'YData');    
    brushNDX0 = cellfun(@find, get(handles.po, 'BrushData'), 'Uni', 0);
    [handles.po.BrushData] = deal([]);
    
    % Brushed data
    brushNDX2 = [brushNDX, brushNDX0];
    brushNDX2 = arrayfun(@(row) [brushNDX2{row, :}], (1:size(brushNDX2,1))', 'Uni', false);
    
    % Gather epos
    epos      = unique([brushNDX2{:}]);

    % Plot brushed data    
    axes(s5);
    hold off    
    handles.plotEEG = [];
    for ch = 1:size(handles.Y, 1)
        for epo = epos
            if ~isnan(handles.Y(ch, epo))
                if epo == 1 
                    X    = linspace(0, (epo_len+10), (epo_len+10)*handles.srate);
                    XT   = epo * epo_len * handles.srate - handles.srate * epo_len + 1 : epo * epo_len * handles.srate + 10 * handles.srate;                   
                elseif epo == size(handles.Y, 2)
                    X    = linspace(-10, epo_len, (epo_len+10)*handles.srate);  
                    XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 0 * handles.srate;                   
                else               
                    X    = linspace(-10, (epo_len+10), (epo_len+20)*handles.srate);
                    XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 10 * handles.srate;   
                end
                EEG  = handles.EEG(ch, XT);
                Y    = brushVAL{ch}(epo);
                plot(X, EEG, 'LineWidth', .8, 'DisplayName', sprintf('Ch %d, EPO %d, Y=%.2f', ch, epo, Y));
                hold on;
            end
        end
    end
    handles.plotEEG = s5.Children;
    handles.firstfilter = 1;
    xline([0 epo_len], 'k:', 'HandleVisibility','off')
    legend(); ylabel(amp_ylabel); xlabel('time (s)')
    title('EEG (brushed epochs)')

    % Filter EEG Toggle
    if isfilter.Value
        guidata(gcf, handles); 
        push_filter( src, event )
    end    

    % Rainbowcolor
    rainbow = MapRainbow([chanlocs.X], [chanlocs.Y], [chanlocs.Z], 0);
    colororder(s5, rainbow);  

    % Adjust Y ylimits
    adjust_ylimEEG(handles)    

    guidata(gcf, handles);     % Update handles       
end

function cb_eeg_chans( src, event )
    % Callback:
    % Plot Brushed EEG Data of specific channels only

    % Gather brushed data
    brushVAL  = get(handles.p, 'YData');    
    brushNDX  = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);
    epos      = unique([brushNDX{:}]);

    % Channels to plot
    chans = str2num(get(eeg_chans, 'String'));    

    % Plot brushed data    
    axes(s5);
    hold off    
    handles.plotEEG = [];    
    for ch = chans
        for epo = epos
            if epo == 1 
                X    = linspace(0, (epo_len+10), (epo_len+10)*handles.srate);
                XT   = epo * epo_len * handles.srate - handles.srate * epo_len + 1 : epo * epo_len * handles.srate + 10 * handles.srate;                   
            elseif epo == size(handles.Y, 2)
                X    = linspace(-10, epo_len, (epo_len+10)*handles.srate);  
                XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 0 * handles.srate;                   
            else               
                X    = linspace(-10, (epo_len+10), (epo_len+20)*handles.srate);
                XT   = epo * epo_len * handles.srate - handles.srate * (epo_len+10) + 1 : epo * epo_len * handles.srate + 10 * handles.srate;   
            end
            EEG  = handles.EEG(ch, XT);
            Y    = brushVAL{ch}(epo);
            if ~isnan(Y)
                handles.plotEEG = plot(X, EEG, 'LineWidth', .8, 'DisplayName', sprintf('Ch %d, EPO %d, Y=%.2f', ch, epo, Y));
            end
            hold on;
        end
    end
    handles.plotEEG  = s5.Children;  
    handles.firstfilter = 1;
    xline([0 epo_len], 'k:', 'HandleVisibility','off')
    legend(); ylabel(amp_ylabel); xlabel('time (s)')
    title('EEG (brushed epochs)')

    % Filter EEG Toggle
    if isfilter.Value
        guidata(gcf, handles); 
        push_filter( src, event )
    end    

    % Adjust Y ylimits
    adjust_ylimEEG(handles)    

    guidata(gcf, handles);     % Update handles       
end

function cb_remove_eeg( src, event )

    handles     = guidata(src);                                                  % Grab handles  
    try 
        % When >1 channel was plotted it's a cell array
        brushNDX    = cellfun(@find, get(handles.plotEEG, 'BrushData'), 'Uni', 0);   % Gather brushed data
        lines       = find(~cellfun(@isempty, brushNDX));
        N           = cellfun(@(x) regexp(x, '\d+', 'match'), get(handles.plotEEG, 'DisplayName'), 'Uni', 0);          
    catch
        % Otherwise it's a vector
        lines       = 1;
        N           = {regexp(get(handles.plotEEG, 'DisplayName'), '\d+', 'match')};                  
    end          
    
    % Set brushed data to NaN
    for line = lines'
        ch  = str2num(N{line}{1});
        epo = str2num(N{line}{2});
        handles.Y(ch, epo) = nan;
        handles.topo(ch, epo) = nan;  
    end    

    delete(s5.Children(lines));       
    handles.plotEEG = s5.Children;    

    % Adjust Y ylimits
    adjust_ylimEEG(handles)    

    % Update guidata
    update_main(src, event)
end


% *** Plot main data

function p = plot_main(X, Y)
    % Main plot in which 
    % you perform manual artifact rejection

    % Get current y and x limits
    axes(s1); hold off;      
    xlim_now = get(gca, 'XLim');
    ylim_now = get(gca, 'YLim');           
   
    % Plot main plot
    p = plot(X, Y', 'k.:', ...
        'MarkerSize',  markersize, ...
        'LineWidth',  linewidth, ...
        'HandleVisibility','on');
    if ~isempty(sleep)
        xticklabels({})
    end
    title(main_title);    
    ylabel('Values (e. g. z-values)');   

    % Restore axis limits if you were in zoom mode
    try
        if ~all(ismember(xlim_now, handles.xlim_original))
            % zoom mode
            xlim(xlim_now)
            ylim(ylim_now)
        else
            % not zoom mode
            dist = ( max(Y(:)) - min(Y(:)) ) / 25;        
            ylim( [ min(Y(:))-dist, max(Y(:))+dist ] );  
            handles.ylim_original = get(s1, 'YLim');    
            xlim([min(X)-(max(X)-min(X))/100 max(X)+(max(X)-min(X))/100])            
        end     
    catch
        xlim([min(X)-(max(X)-min(X))/100 max(X)+(max(X)-min(X))/100])            
        handles.xlim_original = get(s1, 'XLim');
        handles.ylim_original = get(s1, 'YLim');
    end

%     % Rainbowcolor
%     rainbow = MapRainbow([chanlocs.X], [chanlocs.Y], [chanlocs.Z], 0);
%     colororder(s1, rainbow)      
    
    % Turn brush on
    set( brushf, ...
        'ActionPreCallback', @fixkeypress, ...
        'enable', 'on' );    

    % Re-enable key press
    fixkeypress; 

    % Update guidata
    guidata(gcf, handles);      % Update handles     
end

function po = plot_circles(X, Y0, cleandxnz)
    % Plot removed datapoints

    % Find removed data points
    delY = find_delY(Y0, cleandxnz);    

    % Draw them as red circles
    hold on;
    po = plot(X, delY', 'ro', ...
        'MarkerSize',  markersize, ...
        'HandleVisibility','off'); 
    hold off;
end

function delY = find_delY(Y0, cleandxnz)
    % Find removed datapoints

    delY            = Y0;
    delY(cleandxnz) = nan;
end



% *** Update functions

function cb_done( src, event )
    % Callback:
    % Close the GUI

    update_main(src, event)
    uiresume;                   % Come to an end
end

function cb_del_brushdata( src, event )
    % Callback:
    % Delete brushed data

    handles     = guidata(src);                                            % Grab handles  
    brushNDX    = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);   % Gather brushed data

    % Set brushed data to NaN
    for ichan = 1:numel(brushNDX)
        handles.brushNDX{ichan} = unique( [ brushNDX{ichan}, handles.brushNDX{ichan} ] ); 
        handles.Y(ichan, handles.brushNDX{ichan}) = nan;
        handles.topo(ichan, handles.brushNDX{ichan}) = nan;        
    end    

    % Automatic outlier detection removal
    handles.Y(handles.channel_outlier) = nan;
    handles.Y(handles.movavg_outlier)  = nan;
    

    % Update guidata
    update_main(src, event)
end

function cb_restore_brushdata( src, event )
    % Restore brushed datapoints

    % Gather brushed data 
    brushRESTORE = cellfun(@find, get(handles.po, 'BrushData'), 'Uni', 0);     

    % Restore brushed removed data
    for ichan = 1:numel(brushRESTORE)

        % Brushed data point
        bdp = brushRESTORE{ichan};

        if ~isempty(bdp)
            handles.Y(ichan, bdp)       = handles.Y0(ichan, bdp);
            handles.topo(ichan, bdp)    = handles.topo0(ichan, bdp); 

            % Remove from manually detected removals
            tmp_brushNDX                = handles.brushNDX{ichan};
            handles.brushNDX{ichan}     = tmp_brushNDX(~ismember(tmp_brushNDX, bdp));
    
            % Remove from automatically detected removals
            handles.channel_outlier(ichan, bdp) = logical(0);    
            handles.movavg_outlier(ichan, bdp)  = logical(0);    
        end
    end        

    % Update guidata
    update_main(src, event)
end

function cb_restore_all( src, event )
    % Callback:
    % Restore all data points    

    % Gather brushed data 
    brushRESTORE = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);     

    % Restore ALLLL data
    if all(cellfun(@isempty, brushRESTORE))

        % Restore data
        handles.Y          = handles.Y0;                    % Restore all data points    
        handles.brushNDX   = cell(size(handles.Y, 1), 1);   % Delete brushed data
        handles.topo       = handles.topo0;                 % Restore topo
    
        % Remove automatically detected removals
        handles.channel_outlier = logical(zeros(size(handles.Y0)));    
        handles.movavg_outlier = logical(zeros(size(handles.Y0)));   

    % Restore all data in brushed epochs
    else

        % Gather brushed epochs
        epos = unique([brushRESTORE{:}]);

        % Restore data
        handles.Y(:, epos)          = handles.Y0(:, epos) ;    % Restore all data points    
        handles.topo(:, epos)       = handles.topo0(:, epos);  % Restore topo

        % Remove automatically detected removals
        handles.channel_outlier(:, epos)  = 0;    
        handles.movavg_outlier(:, epos)  = 0;     

        % Delete storage of deleted brushed data
        handles.brushNDX = cellfun(@(x) x(~ismember(x, epos)), handles.brushNDX, 'UniformOutput', 0);
    end

    % Update guidata
    update_main(src, event)
end

function cb_yaxis_restore( src, event )
    % restores axis limits

    axes(s1)
    ylim( handles.ylim_original );
    xlim( handles.xlim_original );
end

function artndxnz = compute_artndxz(Y0, Y)
    % Compute artndxz

    % Find removed datapoints 
    artndxnz = isnan(Y) & ~isnan(Y0);       
end

function cleandxnz = compute_cleandxnz(Y0, Y)
    % Compute cleandxnz

    % Find removed datapoints 
    cleandxnz = ~isnan(Y);       
end

function cb_chanexcl( src, event )
   
    % Exclude channels
    chans     = str2num(get(chanexcl_edit, 'String'));
    brushNDX  = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);
    epos      = unique([brushNDX{:}]);

    % Set channels to nan
    for ch = chans
%         epos = brushNDX{ch};
        if isempty(epos)
            if all(isnan(handles.Y(ch, :)))
                handles.Y(ch, :) = handles.Y0(ch, :);
                handles.topo(ch, :) = handles.topo0(ch, :); 
            else
                handles.Y(ch, :) = nan;
                handles.topo(ch, :) = nan;   
            end            
        else
            if all(isnan(handles.Y(ch, epos)))
                handles.Y(ch, epos) = handles.Y0(ch, epos);
                handles.topo(ch, epos) = handles.topo0(ch, epos); 
            else
                handles.Y(ch, epos) = nan;
                handles.topo(ch, epos) = nan;   
            end
        end
    end
    
    % Update
    update_main(src, event)
end


% *** Outlier detection

function ch_main_onechan( src, event )

    % Grab channel
    chans     = str2num(get(main_chans, 'String'));   

    % Highlight channels in main plot
    [handles.p, handles.chans_highlighted] = highlight_chans(handles.X, handles.Y, handles.p, chans);   
   
    % Update guidata
    guidata(gcf, handles);      % Update handles       
end

function [p, chans_legend] = highlight_chans(X, Y, p, chans)
    % Highlights channels in main plot

    % Rainbowcolor
    rainbow = MapRainbow([chanlocs.X], [chanlocs.Y], [chanlocs.Z], 0);

    % Highlight channel with a different color in main plot
    for chan = chans
        if p(chan).Marker == '.';   
            % Highlight channel
            p(chan).MarkerFaceColor = rainbow(chan, :);
            p(chan).Marker = 's';  
            p(chan).MarkerSize = 7;            
            % p(chan).HandleVisibility = 'on';
            p(chan).DisplayName = sprintf('Channel %d', chan);  
            uistack(p(chan), 'top')

%              % Open new figure
%             fmainchan = figure('color', 'w')
%         
%             % Values to plot
%             Y1 = Y(chan, :);
%         
%             % Plot main plot
%             plot(X, Y1', 'k.:', ...
%                 'MarkerSize',  markersize, ...
%                 'LineWidth',  linewidth);
%             title('Temporary figure (close when done inspecting)');    
%             legend(sprintf('Channel %d', chan))
%             ylabel('Values (e. g. z-values)');   
%             xlabel('Epoch')
        
        else
            % Turn back to normal            
            p(chan).MarkerFaceColor = 'k';
            p(chan).Marker = '.';    
            p(chan).DisplayName = '';               
            p(chan).MarkerSize = markersize;            
            % p(chan).HandleVisibility = 'off';            
        end
    
           
    end

    % Show legend
    chans_legend = find(arrayfun(@(x) ~isempty(x.DisplayName), p, 'UniformOutput', 1))';
    if ~isempty(chans_legend)
        legend(s1, p(chans_legend));  
    end
end

function cb_meanthresh( src, event )
    % Callback:
    % Automatic outlier detection   

    handles  = guidata(src);       % Grab handles                  
    mythresh = str2num(get(meanthresh_edit, 'String'));
    
    % Automatic outlier detection
    [handles.Y handles.topo, handles.channel_outlier] = channel_outlier(handles.Y0, handles.topo, mythresh);    
    guidata(gcf, handles);      % Update handles    

    % Delete prior manually deleted datapoints again
    cb_del_brushdata( src, event )
end

function [Y topo isout] = channel_outlier(Y, topo, mythresh)
    % Function to remove outliers per epoch across channels
    isout           = isoutlier(Y, 'mean', 'ThresholdFactor', mythresh);  % Outlier detection          
    Y(isout)        = nan;
    topo(isout)     = nan;        
end

function cb_movavg_outlier( src, event )
    % Callback:
    % Automatic outlier detection   

    handles    = guidata(src);       % Grab handles                  
    mythresh   = str2num(get(movavg_thresh, 'String'));
    
    % Automatic outlier detection
    [handles.Y handles.topo, handles.movavg_outlier] = movavg_outlier(handles.Y0, handles.topo, mythresh);    
    guidata(gcf, handles);      % Update handles    

    % Delete prior manually deleted datapoints again
    cb_del_brushdata( src, event )
end

function [Y topo isout] = movavg_outlier(Y, topo, mythresh)
    % Function to remove outliers based on moving average
    isout           = isoutlier(Y', 'movmean', 40, 'ThresholdFactor', mythresh);  % Outlier detection  
    isout           = isout';
    Y(isout)        = nan;
    topo(isout)     = nan;        
end



% *** Ultimate update

function update_main(src, event)

    % Update artifact rejection
    handles.artndxnz  = compute_artndxz(handles.Y0, handles.Y);           % Bad epochs
    handles.cleandxnz = compute_cleandxnz(handles.Y0, handles.Y);         % Clean epochs
    
    % Plot and update handles
    handles.p   = plot_main(handles.X, handles.Y);             % Black dots
    handles.po  = plot_circles(handles.X, handles.Y0, handles.cleandxnz); % Red circles
    handles.p   = highlight_chans(handles.X, handles.Y, handles.p, handles.chans_highlighted); % Highlighted channels
    
    % Side plots
    plot_bar(handles.Y0, handles.artndxnz);                              % Barplot
    handles.plotPSD = plot_ps2D(handles.spectrum, handles.cleandxnz);    % Power spectrum
    
    % Update guidata
    guidata(gcf, handles);      % Update handles    
end



% ***********************
%   Keypress shortcuts
% ***********************

function fixkeypress( src, event )
% Fixes zoom keypresses

hManager = uigetmodemanager(f);
[hManager.WindowListenerHandles.Enabled] = deal(false);
set(f, 'WindowKeyPressFcn', @keyPress);
set(f, 'KeyPressFcn', []);
% set(f,'WindowButtonDownFcn',@mousClick)
    
end

fixkeypress()

% % So that function presses also work during zooming in and out
% addToolbarExplorationButtons(f) 
% Button = findall(f, 'Tag', 'Exploration.ZoomIn');
% OldClickedCallback = Button.ClickedCallback;
% Button.ClickedCallback = @(h, e) FixButton(f, OldClickedCallback, f.WindowKeyPressFcn);
% 
% Button = findall(f, 'Tag', 'Exploration.ZoomOut');
% OldClickedCallback = Button.ClickedCallback;
% Button.ClickedCallback = @(h, e) FixButton(f, OldClickedCallback, f.WindowKeyPressFcn);
% 
% function Result = FixButton(Figure, OldCallback, NewCallback)
%     eval(OldCallback);
%     hManager = uigetmodemanager(Figure); % HG 2 version
%     [hManager.WindowListenerHandles.Enabled] = deal(false);
%     Figure.KeyPressFcn = [];
%     Figure.WindowKeyPressFcn = NewCallback;
%     Result = true;
% end

% Keypress shortcuts
function keyPress(src, event)    
    switch event.Key
        case 'r'
            cb_del_brushdata( src, event );       
        case 't'
            cb_plotEEG( src, event ); 
            cb_topo_brush( src, event ); 
        case 'z'
            cb_topo_brush( src, event );   
        case 'f'
            cb_restore_all( src, event );   
        case 'p'
            cb_remove_powerspectrum( src, event );  
        case 'g'
            cb_plotEEG_allchans( src, event );        
        case 'h'
            cb_remove_eeg( src, event );            
    end
end

% Mouseclick
% function mousClick(src, event)    
% 
%     pt = get(s1, 'CurrentPoint');
% 
%     
% end

% Create outputs as soon as "done" button is pressed
uiwait(f)

if ~isempty(epo_select)

    % Only clean input values
    output.cleanVALUES                = YOrigin; 
    output.cleanVALUES(:, epo_select) = handles.Y;

    % Corresponding logical matrix indicating which values died during artifact rejection
    output.artndxnz                   = zeros(size(YOrigin));
    output.artndxnz(:, epo_select)    = handles.artndxnz;

else
    
    output.cleanVALUES  = handles.Y;           % Only clean input values
    output.artndxnz     = handles.artndxnz;    % Corresponding logical matrix indicating which values died during artifact rejection
    
end

% Make logical
output.artndxnz    = logical(output.artndxnz);
close(f);


end