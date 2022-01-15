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

% Main plot
s1 = subplot('Position', [left bottom_up+.12 width_left height_up-.12]);
p  = plot(X, Y', 'k.:', ...
     'MarkerSize',  markersize, ...
     'LineWidth',  linewidth); 
ylabel('Values (e. g. z-values)');
xlim_original = get(s1, 'XLim');
ylim_original = get(s1, 'YLim');
title('Main plot');    

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
xline([0 20], 'k:', 'HandleVisibility','off')
legend(); ylabel('Amplitude (\muV)'); xlabel('time (s)'); xlim([-20 40]);
title('EEG (brushed epochs)');  

% Prepare topoplot
s6 = subplot('Position', [left+0.51 bottom_low 0.16 height_low]);
topoplotGUI(zeros(1, size(Y, 2)), [0 1], []);
title('Topoplot (brushed epochs)');    
 

% Turn brush on
% brush on  
brushf = brush;
set( brushf, ...
    'ActionPreCallback', @fixkeypress, ...
    'enable', 'on' );


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

% Channel outlier detection
[handles.Y handles.topo] = channel_outlier(handles.Y, handles.topo, 8);    
[handles.Y handles.topo] = movavg_outlier(handles.Y, handles.topo, 8);    
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
fontsize_button     = 9;

% Push buttons
done_button = uicontrol(f, ...
    'Style', 'pushbutton', ...
    'fontsize', 10, ...,
    'string', 'Done', ...
    'units', 'normalized', ...
    'position', [button_left_small 0.045 button_width_small button_height_small], ...
    'BackgroundColor', [0 0.4470 0.7410], ...    
    'callback', @cb_done);  


% Figure manipulation
panel_restorebuttons = uipanel(f, ...
    'units', 'normalized', ...
    'title', 'Figure manipulation', ...    
    'Position', [panel_left 0.78 panel_width 0.16]);
ph1=0.18; ph0=0.04;
cb_del_brushdata_button = uicontrol(panel_restorebuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Remove epochs [R]', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*4 panelbutton_width ph1], ...
    'callback', @cb_del_brushdata);
cb_restore_brushdata_button = uicontrol(panel_restorebuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Restore epochs [F]', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*3 panelbutton_width ph1], ...
    'callback', @cb_restore_brushdata);
cb_restore_all_button = uicontrol(panel_restorebuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Restore all data', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*2 panelbutton_width ph1], ...
    'callback', @cb_restore_all); 
cb_restore_yaxis = uicontrol(panel_restorebuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Restore Y Axis', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1 panelbutton_width ph1], ...
    'callback', @cb_yaxis_restore); 
cb_restore_yaxis = uicontrol(panel_restorebuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Clean spectrum [P]', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0 panelbutton_width ph1], ...
    'callback', @cb_remove_powerspectrum); 


% Plot buttons
ph1=0.23; ph0=0.04;
panel_plotbuttons = uipanel(f, ...
    'units', 'normalized', ...
    'title', 'Plots', ...    
    'Position', [panel_left 0.66 panel_width 0.10]);
cb_plotEEG_button = uicontrol(panel_plotbuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'EEG [T]', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*0 panelbutton_width ph1], ...
    'callback', @cb_plotEEG); 
cb_topo_brush_button = uicontrol(panel_plotbuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Topo (epoch) [Z]', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*1 panelbutton_width ph1], ...
    'callback', @cb_topo_brush); 
cb_topo_night_button = uicontrol(panel_plotbuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Topo (night)', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*2 panelbutton_width ph1], ...
    'callback', @cb_topo_night); 
cb_topo_video_button = uicontrol(panel_plotbuttons, ...
    'Style', 'pushbutton', ...
    'fontsize', fontsize_button, ...,
    'string', 'Topo (video)', ...
    'units', 'normalized', ...
    'position', [panelbutton_left ph0+ph1*3 panelbutton_width ph1], ...
    'callback', @cb_topo_video); 



% Automatic outlier detection
panel_channels = uipanel(f, ...
    'units', 'normalized', ...
    'Position', [panel_left 0.55 panel_width 0.04], ...
    'title', 'Channel outlier (per epoch)');
meanthresh_edit = uicontrol(panel_channels, ...
    'Style', 'edit', ...
    'fontsize', fontsize_button, ...,
    'string', 'Mean + x*sd (Default 8)', ...
    'units', 'normalized', ...
    'position', [panelbutton_left 0.05 panelbutton_width 0.8], ...
    'callback', @cb_meanthresh);  

% Exclude channels
panel_channels = uipanel(f, ...
    'units', 'normalized', ...
    'Position', [panel_left 0.60 panel_width 0.04], ...
    'title', 'Exlude/Include channels');
chanexcl_edit = uicontrol(panel_channels, ...
    'Style', 'edit', ...
    'fontsize', fontsize_button, ...,
    'string', 'Channel ID', ...
    'units', 'normalized', ...
    'position', [panelbutton_left 0.05 panelbutton_width 0.8], ...
    'callback', @cb_chanexcl);  

% Moving average
panel_movavg = uipanel(f, ...
    'units', 'normalized', ...
    'Position', [panel_left 0.50 panel_width 0.04], ...
    'title', 'Epoch outlier (per channel)');
movavg_thresh = uicontrol(panel_movavg, ...
    'Style', 'edit', ...
    'fontsize', fontsize_button, ...,
    'string', 'Moving average + x*sd (Default 8)', ...
    'units', 'normalized', ...
    'position', [panelbutton_left 0.05 panelbutton_width 0.8], ...
    'callback', @cb_movavg_outlier);  


% ********************
%   Build Functions
% ********************



% *** Power spectrum

function cb_power_spectrum( src, event )
    % Button callback: 
    % plot power spectrum

    handles = guidata(src);                             % Grab handles                  
    handles.plotPSD = plot_ps2D(handles.spectrum, handles.cleandxnz)      % Plot power spectrum
end

function plotPSD = plot_ps2D(ps3D, clean2D)
    % Plots power spectrum of 
    % all channels on top of each other

    % Compute power spectrum 
    ps2D = compute_ps2D(ps3D, clean2D);         
%     ps2D = (ps2D - mean(ps2D, 1)) ./ std(ps2D, [], 1);

    % Plot power spectrum
    axes(s4)
    plotPSD = plot( 0:fres:fmax, log10(ps2D)', ...
        'LineWidth', linewidth)
        xlabel('Freq (Hz)'); 
        ylabel('Log_{PSD}')
    title('Spectral power (all epochs)');
end

function ps2D = compute_ps2D(ps3D, clean2D)
    % Computes power spectrum
    % for all channels in clean epochs

    clean3D         = clean_3D(clean2D, ps3D);
    ps3D(~clean3D)  = nan;                            % Clean spectrum
    ps2D            = mean(ps3D, 3, 'omitnan');       % Mean over epochs
    ps2D            = ps2D(:, 1:fmax/fres+1)          % Frequencies 1 to 30
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


% *** Barplot (percentage clean epochs)

function plot_bar(Y0, artndxnz)
    % Plots power spectrum of 
    % all channels on top of each other

    % Percentage correct
    [prc1, prc2] = compute_bar(Y0, artndxnz)    

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

    nonanEPO = sum(isnan(Y0)) == 0;  % Epochs that contained values
    prc1  = sum(~artndxnz(:, nonanEPO), 2) ...
        ./ sum(nonanEPO) * 100;      % Percentage of clean sleep epochs
    prc2 = prc1;                     % Percentage of bad sleep epochs
    prc2(prc2 >= barthresh) = nan;          

end

function cb_plot_bar( src, event )
    % Callback:
    % Barplot (percentage clean epochs)

    handles = guidata(src);                    % Grab handles                  
    plot_bar(handles.Y0, handles.artndxnz)     % Plot bar
end



% *** Topoplots

function topoplotGUI(vTopo1, limits, chanstopo)
    % Plots a nice topoplot

    % 'plotchans', setdiff(1:129, [49 56 107 113, 126, 127]), ...
    topoplot( vTopo1, chanlocs, ...
        'plotchans', 1:129, ...
        'maplimits', limits, ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'electrodes','numbers', 'headrad',.5, 'intrad',.7, 'plotrad',.7, 'colormap', L18);
    topoplot( vTopo1, chanlocs, ...
        'plotchans', 1:129, ...
        'maplimits', limits, ...
        'style', 'map', ...
        'whitebk', 'on', ...
        'emarker2', {chanstopo,'.','k',26}, ...   
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
 
    % Compute values
    vTopo1 = mean(handles.topo0, 2, 'omitnan');
    vTopo2 = mean(handles.topo, 2, 'omitnan');
    limits = [prctile([vTopo1; vTopo2], 1)  prctile([vTopo1; vTopo2], 99)];
    
    % Topoplots
    subplot(121); topoplotGUI(vTopo1, limits, []); title('All values');          
    subplot(122); topoplotGUI(vTopo2, limits, []); title('Clean values');      
end

function cb_topo_brush( src, event )
    % plot topoplot

    % Brushed data
    handles    = guidata(src);                  % Grab handles  
    brushNDX   = cellfun(@find, get(handles.p, 'BrushData'), 'Uni', 0);  % Gather brushed data
    chansNDX   = find(cellfun(@isempty, brushNDX) == 0);                % Gather brushed channels

    % Compute values
    vTopo1 = mean(handles.topo(:, [brushNDX{:}]), 2, 'omitnan');
    limits = [min(vTopo1) max(vTopo1)];

    % Black dots
    chanstopo = chansNDX;
    for ich = 1:length(chanstopo)      
        chanstopo(ich) = chansNDX(ich) - sum( find(isnan(vTopo1)) <= chansNDX(ich) );
    end    
   
    % Topoplot
    axes(s6);
    cla(s6, 'reset')    
    topoplotGUI(vTopo1, limits, chanstopo); title('Topoplot (brushed epochs)')          
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
            drawnow() 
            pause(0.01)                 
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

    % Plot brushed data    
    axes(s5);
    hold off    
    for ch = 1:numel(brushNDX)
        epos = brushNDX{ch};
        for epo = epos
            X    = linspace(-20, 40, 60*handles.srate);
            XT   = epo * 20 * handles.srate - handles.srate * 40 + 1 : epo * 20 * handles.srate + 20 * handles.srate;
            EEG  = handles.EEG(ch, XT);
            Y    = brushVAL{ch}(epo);
            plot(X, EEG, 'LineWidth', .8, 'DisplayName', sprintf('Ch %d, EPO %d, Y=%.2f', ch, epo, Y));
            hold on;
        end
    end
    xline([0 20], 'k:', 'HandleVisibility','off')
    legend(); ylabel('Amplitude (\muV)'); xlabel('time (s)')
    title('EEG (brushed epochs)')
    guidata(gcf, handles);     % Update handles       
end



% *** Plot main data

function p = plot_main(X, Y, p)
    % Main plot in which 
    % you perform manual artifact rejection

    % Get current y and x limits
    axes(s1); hold off;       
    xlim_now = get(gca, 'XLim');
    ylim_now = get(gca, 'YLim');     
   
    % Plot main plot
    p = plot(X, Y', 'k.:', ...
        'MarkerSize',  markersize, ...
        'LineWidth',  linewidth);
    if ~isempty(sleep)
        xticklabels({})
    end
    title('Main plot');    
    ylabel('Values (e. g. z-values)');    

    % Restore axis limits if you were in zoom mode
    if ~all(ismember(xlim_now, xlim_original))
        % zoom mode
        xlim(xlim_now)
        ylim(ylim_now)
    else
        % not zoom mode
        dist = ( max(Y(:)) - min(Y(:)) ) / 25;        
        ylim( [ min(Y(:))-dist, max(Y(:))+dist ] )   
        ylim_original = get(s1, 'YLim');        
    end       
    
    % Turn brush on
    set( brushf, ...
        'ActionPreCallback', @fixkeypress, ...
        'enable', 'on' )     

    % Re-enable key press
    fixkeypress; 
end

function po = plot_circles(X, Y0, cleandxnz)
    % Plot removed datapoints

    % Find removed data points
    delY = find_delY(Y0, cleandxnz);    

    % Draw them as red circles
    hold on;
    po = plot(X, delY', 'ro', ...
        'MarkerSize',  markersize); 
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

    % Update guidata
    update_main(src, event)
end

function cb_restore_brushdata( src, event )
    % Restore brushed datapoints

     % Gather brushed data 
    brushRESTORE = cellfun(@find, get(handles.po, 'BrushData'), 'Uni', 0);     

    % Restore brushed removed data
    for ichan = 1:numel(brushRESTORE)
        handles.Y(ichan, brushRESTORE{ichan}) = handles.Y0(ichan, brushRESTORE{ichan});
        handles.topo(ichan, brushRESTORE{ichan}) = handles.topo0(ichan, brushRESTORE{ichan});        
    end        

    % Update guidata
    update_main(src, event)
end

function cb_restore_all( src, event )
    % Callback:
    % Restore all data points    

    % Restore data
    handles.Y          = handles.Y0;                    % Restore all data points    
    handles.brushNDX   = cell(size(handles.Y, 1), 1);   % Delete brushed data
    handles.topo       = handles.topo0                  % Restore topo

    % Update guidata
    update_main(src, event)
end

function cb_yaxis_restore( src, event )
    % restores axis limits

    axes(s1)
    ylim( ylim_original );
    xlim( xlim_original );
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
                handles.Y(ch, :) = handles.Y0(ch, epos);
                handles.topo(ch, :) = handles.topo0(ch, epos); 
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

function cb_meanthresh( src, event )
    % Callback:
    % Automatic outlier detection   

    handles  = guidata(src);       % Grab handles                  
    mythresh = str2num(get(meanthresh_edit, 'String'));
    
    % Automatic outlier detection
    [handles.Y handles.topo] = channel_outlier(handles.Y, handles.topo, mythresh);    
    guidata(gcf, handles);      % Update handles    

    % Delete prior manually deleted datapoints again
    cb_del_brushdata( src, event )
end

function [Y topo] = channel_outlier(Y, topo, mythresh)
    % Function to remove outliers per epoch across channels
    isout           = isoutlier(Y, 'mean', 'ThresholdFactor', mythresh);  % Outlier detection          
    Y(isout)       = nan;
    topo(isout)    = nan;        
end

function cb_movavg_outlier( src, event )
    % Callback:
    % Automatic outlier detection   

    handles    = guidata(src);       % Grab handles                  
    mythresh   = str2num(get(movavg_thresh, 'String'));
    
    % Automatic outlier detection
    [handles.Y handles.topo] = movavg_outlier(handles.Y, handles.topo, mythresh);    
    guidata(gcf, handles);      % Update handles    

    % Delete prior manually deleted datapoints again
    cb_del_brushdata( src, event )
end

function [Y topo] = movavg_outlier(Y, topo, mythresh)
    % Function to remove outliers based on moving average
    isout           = isoutlier(Y', 'movmean', 40, 'ThresholdFactor', mythresh);  % Outlier detection          
    Y(isout')       = nan;
    topo(isout')    = nan;        
end



% *** Ultimate update

function update_main(src, event)

    % Update artifact rejection
    handles.artndxnz  = compute_artndxz(handles.Y0, handles.Y);           % Bad epochs
    handles.cleandxnz = compute_cleandxnz(handles.Y0, handles.Y);         % Clean epochs
    
    % Plot and update handles
    handles.p   = plot_main(handles.X, handles.Y, handles.p);             % Black dots
    handles.po  = plot_circles(handles.X, handles.Y0, handles.cleandxnz); % Red circles
    
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
        case 'z'
            cb_topo_brush( src, event );   
        case 'f'
            cb_restore_brushdata( src, event );   
        case 'p'
            cb_remove_powerspectrum( src, event );               
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
output.cleanVALUES  = handles.Y;           % Only clean input values
output.artndxnz     = handles.artndxnz;    % Corresponding logical matrix indicating which values died during artifact rejection
close(handles.f2)
close(handles.f1)
close(f);


end