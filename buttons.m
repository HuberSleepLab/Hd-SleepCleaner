% f = uifigure('HandleVisibility', 'on');
clf; clearvars -except f

% Create main grid
grid_main = uigridlayout(f);
grid_main.ColumnWidth = cat(2, 250, repelem({'1x'}, 10));

% Panel height
panel_height = [10 8 10 1];

% =========================================================================
% *** Create first panel
% Create panel 01
panel_props.Title = 'Figure manipulations';
button_props.BackgroundColor = [0 0 0];
panel01 = uipanel(grid_main, panel_props)
panel01.Layout.Row = [1 panel_height(1)];
panel01.Layout.Column = [1];

% Grid in the panel
grid_panel01 = uigridlayout(panel01, [7, 1]);
% grid2.RowHeight = {22,22,22};
% grid2.ColumnWidth = {80,'1x'};

% Create buttons
button_props.Text = '[R] Remove datapoint';
button_props.BackgroundColor = [1 1 1];
uibutton(grid_panel01, button_props)

button_props.Text = 'Restore datapoint';
uibutton(grid_panel01, button_props)

button_props.Text = '[F] Restore selected/all epochs';
uibutton(grid_panel01, button_props)

button_props.Text = 'Restore Y Axis';
uibutton(grid_panel01, button_props)

button_props.Text = 'Remove chans (Spectrum)';
uibutton(grid_panel01, button_props)

button_props.Text = 'Show chans (Spectrum)';
uibutton(grid_panel01, button_props)

button_props.Text = '[H] Remove chans (EEG)';
uibutton(grid_panel01, button_props)

% =========================================================================
% *** Create second panel
% Create panel 02
panel_props.Title = 'Plot functions';
button_props.BackgroundColor = [0 0 0];
panel02 = uipanel(grid_main, panel_props)
panel02.Layout.Row = [panel_height(1)+1 sum(panel_height(1:2))];
panel02.Layout.Column = [1];

% Grid in the panel
grid_panel02 = uigridlayout(panel02, [5, 1]);
% grid2.RowHeight = {22,22,22};
% grid2.ColumnWidth = {80,'1x'};

% Create buttons
button_props.Text = 'Topo (video)';
button_props.BackgroundColor = [1 1 1];
uibutton(grid_panel02, button_props)

button_props.Text = 'Topo (night)';
uibutton(grid_panel02, button_props)

button_props.Text = '[Z] Topo (epoch)';
uibutton(grid_panel02, button_props)

button_props.Text = '[T] EEG';
uibutton(grid_panel02, button_props)

button_props.Text = '[G] EEG all channels';
uibutton(grid_panel02, button_props)


% =========================================================================
% *** Automatic outlier rejection
% Create panel 03 (with tabs)
panel_props.Title = 'Plot functions';
button_props.BackgroundColor = [0 0 0];
tab_miscellaneous = uitabgroup(grid_main)
tab_miscellaneous.Layout.Row = [sum(panel_height(1:2))+1 sum(panel_height(1:3))];
tab_miscellaneous.Layout.Column = [1];

% Create tab (Automatic outlier rejection)
tab_auto_outlier_detection = uitab(tab_miscellaneous);
tab_auto_outlier_detection.Title = 'Automatic outlier rejection';
tab_auto_outlier_detection.Scrollable = 'on'

% Create grid layout
grid_auto_outlier_detection = uigridlayout(tab_auto_outlier_detection, [8, 1]);

% *** Find outlier channel for a given epoch
% Create label
label_props.WordWrap = 'on';
label_props.HorizontalAlignment = 'left';
label_props.VerticalAlignment = 'bottom';
label_props.Interpreter = 'html';
label_props.Text = sprintf('<b>Find outlier channel</b> \nx̄ + x*SD, where x̄ and SD are the mean and standard deviation across channels (for a given epoch).')
label_outlier_channel = uilabel(grid_auto_outlier_detection, label_props)
label_outlier_channel.Layout.Row = [1, 2];

% Create spinner
spinner_outlier_channel = uispinner(grid_auto_outlier_detection, 'ValueDisplayFormat', 'x = %.2f');

% Create slider
slider_outlier_channel = uislider(grid_auto_outlier_detection);

% *** Find outlier epoch for a given channel
% Create label
label_props.Text = sprintf('<b>Find outlier epoch</b> \n mov_x̄ + x*SD, where xmov_x̄ is the moving mean of 40 epochs for a given channel.')
label_outlier_epoch = uilabel(grid_auto_outlier_detection, label_props)
label_outlier_epoch.Layout.Row = [5, 6];

% Create spinner
spinner_outlier_epoch = uispinner(grid_auto_outlier_detection, 'ValueDisplayFormat', 'x = %.2f');

% Create slider
slider_outlier_epoch = uislider(grid_auto_outlier_detection);


% =========================================================================
% *** Channel manipulation
% Create tab (Channel manipulation)
tab_channel_manipulation = uitab(tab_miscellaneous);
tab_channel_manipulation.Title = 'Channel manipulation';
tab_channel_manipulation.Scrollable = 'on';

% Create grid layout
grid_channel_manipulation = uigridlayout(tab_channel_manipulation, [6, 1]);


% *** Hightlight channels
% Create label
label_props.Text = sprintf('<b>Highlight values of one or more channels</b>')
label_props.HorizontalAlignment = 'left';
label_props.VerticalAlignment = 'bottom';
label_highlight_channels = uilabel(grid_channel_manipulation, label_props)

% Create editfield
editfield_highlight_channels = uieditfield(grid_channel_manipulation, 'text')
editfield_highlight_channels.Value = 'Channel IDs';


% *** Excl./Incl channels
% Create label
label_props.Text = sprintf('<b>Exclude/Include one or more channels</b>')
label_props.HorizontalAlignment = 'left';
label_props.VerticalAlignment = 'bottom';
label_exclude_include_channels = uilabel(grid_channel_manipulation, label_props)

% Create editfield
editfield_exclude_include_channels = uieditfield(grid_channel_manipulation, 'text')
editfield_exclude_include_channels.Value = 'Channel IDs';


% *** Plot EEG
% Create label
label_props.Text = sprintf('<b>Of selected epochs, plot the EEG of one or more channels</b>')
label_props.HorizontalAlignment = 'left';
label_props.VerticalAlignment = 'bottom';
label_plot_eeg_of_channels = uilabel(grid_channel_manipulation, label_props)

% Create editfield
editfield_plot_eeg_of_channels = uieditfield(grid_channel_manipulation, 'text')
editfield_plot_eeg_of_channels.Value = 'Channel IDs';


% =========================================================================
% *** Filter EEG
% Create tab (Filter EEG)
tab_filter_eeg = uitab(tab_miscellaneous);
tab_filter_eeg.Title = 'Filter EEG';
tab_filter_eeg.Scrollable = 'on';

% Create grid layout
grid_filter_eeg = uigridlayout(tab_filter_eeg, [4, 2]);

% Create button
button_props.Text = 'Online filter currently ploted EEG';
button_props.BackgroundColor = [1 1 1];
button_online_filter = uibutton(grid_filter_eeg, button_props)
button_online_filter.Layout.Column = [1, 2];

button_props.Text = 'Autofilter OFF (click to turn on)';
button_props.BackgroundColor = [1 1 1];
button_auto_filter = uibutton(grid_filter_eeg, button_props)
button_auto_filter.Layout.Column = [1, 2];

% Create label
label_props.Text = sprintf('Lower cut-off (Hz)')
label_props.HorizontalAlignment = 'center';
label_props.VerticalAlignment = 'bottom';
uilabel(grid_filter_eeg, label_props)

label_props.Text = sprintf('Upper cut-off (Hz)')
uilabel(grid_filter_eeg, label_props)

% Create spinner
spinner_props.Limits = [0, 100];
spinner_props.ValueDisplayFormat = '%.1f Hz';
spinner_props.Value = 0;
spinner_lower_cutoff = uispinner(grid_filter_eeg, spinner_props);

spinner_props.Value = 55;
spinner_upper_cutoff = uispinner(grid_filter_eeg, spinner_props);

% =========================================================================
% *** Done button
button_props.Text = 'Done';
button_props.BackgroundColor = [0 0.4470 0.7410];
button_done = uibutton(grid_main, button_props)
button_done.Layout.Row = [sum(panel_height(1:4))];
button_done.Layout.Column = [1];
button_done.FontSize = 20;