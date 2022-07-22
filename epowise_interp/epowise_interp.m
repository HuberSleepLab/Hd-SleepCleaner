function [EEG] = epowise_interp(EEG, intp, varargin)

    p = inputParser;
    addParameter(p, 'epolen',       20); % Epoch length   
    addParameter(p, 'displayFlag',   0); % Toggle (0|1) to print some info            
    parse(p, varargin{:});  

    % Create variables
    for var = p.Parameters
        eval([var{1} '= p.Results.(var{1});']);
    end  


    % *** Start function    
    for iepo = 1:numel(intp.epo_intp)
        epo  = intp.epo_intp(iepo);

        % Data points
        from = epo * epolen * EEG.srate - epolen * EEG.srate + 1;
        to   = epo * epolen * EEG.srate;

        % Create EEG structure for interpolation
        if epo == intp.epo_intp(1)
            EPO          = makeEEG(EEG.data(:, from:to), EEG.srate);
            EPO.chanlocs = EEG.chanlocs;
        end

        % Extract data
        EPO.data = EEG.data(:, from:to);

        % Interpolate bad channels
        EPO = pop_interp(EPO, intp.chans_bad{iepo}, 'spherical');

        % Plot interpolated signal
        if displayFlag & iepo == 1 
            figure;
            hold on;
            plot(EPO.times/1000, EEG.data(intp.chans_bad{iepo}, from:to)', 'DisplayName', 'Original');
            plot(EPO.times/1000, EPO.data(intp.chans_bad{iepo}, :)', '--', 'DisplayName', 'Interpoalted');

            % Make pretty
            legend; 
            xlabel('Time (s)'); 
            ylabel('Amplitude (\muV)')
            input('Press [ENTER] to continue.')
            close
        end

        % Insert interpolated data
        EEG.data(intp.chans_bad{iepo}, from:to) = EPO.data(intp.chans_bad{iepo}, :);

        % update waitbar
        if iepo == 1
            wb = waitbar(0, 'Epoch-wise interpolation');
        end
        waitbar(iepo/numel(intp.epo_intp), ...
            wb, ...
            sprintf('Epoch-wise interpolation (%d/%d)', iepo, numel(intp.epo_intp)));               
    end

    % close waitbar    
    close(wb);     
end