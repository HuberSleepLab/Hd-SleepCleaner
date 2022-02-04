# What this repository is about

This is an advanced semi-automatic artifact removal procedure based on [Huber et al., 2000](https://journals.lww.com/neuroreport/Fulltext/2000/10200/Exposure_to_pulsed_high_frequency_electromagnetic.12.aspx?casa_token=rmSXsQLiWZcAAAAA:9g0JXdXUpAJycVWzDSCLXKynmKeGpbXGJvZkrRGzSw5tifqkBLWYyfESIq4814-SpcqtBomfWBGnYf1-wyrbWbak) using a Maltab GUI specifically designed for the identification of artifacts in HD-EEG. As for sleep scoring, the procedure segmented the EEG into 20 s epochs. For each channel in each sleep staged N1, N2, and N3 epoch, spectral power as well as the maximum squared deviation in amplitude from the average EEG signal was computed. Values from all channels and all NREM epochs were then visualized in one figure and outliers were identified, both manually and automatically. Visualizing all channels and epochs altogether has the advantage that extreme values can be both identified in respect to values of neighboring epochs, as well as values from other channels in the same epoch.

Most artifacts are present either in the delta (0.5 – 4.5 Hz) or beta (20 – 30 Hz) frequency range, which is why we used both frequency ranges to identify artifacts. Power spectral density (PSD) values, from which spectral power was computed, were first robustly Z-standardized over epochs (separately for each channel and frequency bin). Doing so adjusts the scale of PSD values across channels and frequency bins which allows 1) to compare spectral power values of different channels altogether and 2) removes the bias of lower frequencies to predominate spectral power values. Robust Z-standardization uses the median and inter-quartile-range (IQR) instead of the mean and standard deviation and is therefore robust towards extreme values which are naturally present in artifact-contaminated spectral power values. PSD was computed using the pwelch() function in Matlab (Welch method, 4 s Hanning windows, 50% overlap, frequency resolution 0.25 Hz). 

Remaining artifacts outside of those frequency ranges were thereafter identified based on the maximum squared deviation in amplitude of one channel from the average EEG signal. To do so, the EEG was robustly Z-standardized over sample points (separately for each channel) to compare the deviation in amplitude of different channels altogether.

Eventually, a channel was removed in a respective epoch when artifacts were identified. Firstly, artifacts attracted our attention when they deviated in robustly Z-standardized delta power, thereafter in robustly Z-standardized beta power, and finally in the maximum squared deviation in amplitude from the average robustly Z-standardized EEG signal. To confirm the presence of artifacts, the EEG and topography of channels and epochs was checked in parallel. In the end, we evaluated normal delta power and removed any remaining artifacts. 

Before performing this routine on average referenced data, we performed it on Cz referenced data (reference as during recording). We did this to remove a good amount of artifacts before average referencing as average referencing is susceptible to large artifacts itself. More specifically, we set 20 s epochs of EEG in artifact-contaminated channels to NaN before average referencing. 

In the background, two automatic outlier detection procedures supported the artifact removal routine. More specifically, outliers were automatically detected 1) channel-wise when epochs deviated more than x standard deviations from a moving average of 40 epochs and 2) epoch-wise, when channels deviated more than x standard deviations from the average of all channels. Thresholds were adapted for each night but were usually situated between 8 and 12 standard deviations.

Thereafter, channels were interpolated in those epochs in which they were labeled as bad. In case more than 3 neighboring channels were classified as bad, however, the entire epoch was rejected instead. With this method, only a minimal amound of NREM epochs needed to be rejected due to poor data quality. Epochs in which only certain channels show artifacts can be inlcuded in the analysis by interpolating those channels in the respective epoch.
