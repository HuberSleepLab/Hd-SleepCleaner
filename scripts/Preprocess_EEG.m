% *** Preprocesses EEG Data

if is_preprocessing

    % ### % Low-pass filter
    % ########################

    % FIR filter 35 Hz - kaiser (attenuated 50 Hz perfectly)
    srateFilt    = EEG.srate;
    passFrq      = 30;
    stopFrq      = 49.75;
    passRipple   = 0.02;     
    stopAtten    = 60; 
    LoPassFilt   = designfilt('lowpassfir','PassbandFrequency',passFrq,'StopbandFrequency',stopFrq,'PassbandRipple',passRipple,'StopbandAttenuation',stopAtten, 'SampleRate',srateFilt, 'DesignMethod','kaiser','MinOrder','Even');         

    % Low-pass filter
    fprintf('** Low-pass filter starts attenuating signal at %.2f Hz and reaches maximum attenuation of %d dB at %.2f Hz\n', LoPassFilt.PassbandFrequency, LoPassFilt.StopbandAttenuation, LoPassFilt.StopbandFrequency)
    EEG = firfilt(EEG, LoPassFilt.Coefficients); 
    
    % Down sample
    EEG = pop_resample(EEG, srate_down);

    % ### % High-pass filter
    % ########################    
    
    % High-pass filter
    if ~is_sweat

        % FIR filter 0.5 Hz - kaiser (removes low frequency artifacts and DC offset when combined with the EGI filter)
        srateFilt  = srate_down;
        passFrq    = 0.5;
        stopFrq    = 0.25;
        passRipple = 0.05;     
        stopAtten  = 30; 
        HiPassFilt = designfilt('highpassfir','PassbandFrequency',passFrq,'StopbandFrequency',stopFrq,'StopbandAttenuation',stopAtten,'PassbandRipple',passRipple,'SampleRate',srateFilt,'DesignMethod','kaiser','MinOrder','Even');
              
        % High-pass filter
        fprintf('** High-pass filter starts attenuating signal at %.2f Hz and reaches maximum attenuation of %d dB at %.2f Hz\n', HiPassFilt.PassbandFrequency, HiPassFilt.StopbandAttenuation, HiPassFilt.StopbandFrequency)        
        EEG = firfilt(EEG, HiPassFilt.Coefficients); 
    else

        % FIR filter 0.9 Hz - kaiser (higher cut-off to remove sweat artifacts)
        srateFilt    = srate_down;
        passFrq      = 0.9;
        stopFrq      = 0.6;
        passRipple   = 0.05;     
        stopAtten    = 30; 
        HiPassFilt09 = designfilt('highpassfir','PassbandFrequency',passFrq,'StopbandFrequency',stopFrq,'StopbandAttenuation',stopAtten,'PassbandRipple',passRipple,'SampleRate',srateFilt,'DesignMethod','kaiser','MinOrder','Even');
            
        % High-pass filter
        fprintf('** High-pass filter starts attenuating signal at %.2f Hz and reaches maximum attenuation of %d dB at %.2f Hz\n', HiPassFilt09.PassbandFrequency, HiPassFilt09.StopbandAttenuation, HiPassFilt09.StopbandFrequency)                
        EEG = firfilt(EEG, HiPassFilt09.Coefficients); 
    end    
end