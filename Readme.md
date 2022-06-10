# What this repository is about
This is an advanced semi-automatic artifact removal procedure based on [Huber et al., 2000](https://journals.lww.com/neuroreport/Fulltext/2000/10200/Exposure_to_pulsed_high_frequency_electromagnetic.12.aspx?casa_token=rmSXsQLiWZcAAAAA:9g0JXdXUpAJycVWzDSCLXKynmKeGpbXGJvZkrRGzSw5tifqkBLWYyfESIq4814-SpcqtBomfWBGnYf1-wyrbWbak) using a Maltab GUI specifically designed for the identification of artifacts in HD-EEG. 


# How to use it
1. Open "Configuration_OutlierGUI.m", and adjust the parameters according to your data (number of channels, scoring lenth, stages to include, etc.).
2. Run "Call_OutlierGUI.m". This script will ask you to load 1) EEG data, 2) the corresponding sleep scoring, and optionally 3), in case you want to modify previously rejected artifacts, the corresponding artndxn (containing rejected epochs) file from a previous round. Next, power will be computed automatically and the GUI is called. Click "Done" when you have rejected all artifacts. The GUI will be called several times with different inputs (selected in the configurations) so that you find as many artifacts as possible.

### Required data
**EEG**: The EEG data needs to be stored in an [EEG structure as used in EEGLAB](https://eeglab.org/tutorials/ConceptsGuide/Data_Structures.html#eeg-and-alleeg), saved as a .MAT file.

**Sleep scoring**: This can either be a .mat file containing an array of N = number of epochs such that:
N1 = -1
N2 = -2
N3 = -3
N4 = -4
W = 1
REM = 0

Or, this can be one of our .vis files that our lab uses for [sleep scoring](https://github.com/HuberSleepLab/sleep-scoring). 

### output
The final output will be saved as a MAT file in the folder containing the scoring information. There will also be a jpg illustrating the EEG before and after cleaning.
The MAT file will include:
- artndxn which is  channel x epoch logical matrix indicating with 1 if the data is an artifact.
- visnum which is an array indicating the scoring of each epoch
- visgood which lists all the epochs that are artefact free



### Example video
[![IMAGE ALT TEXT](Thumbnail.png)](https://youtu.be/XG-Dh1JqR5E "How to use the GUI")




# How it works
As for sleep scoring, the procedure segmented the EEG (filtered between 0.5 and 30 Hz or 0.9 and 30 Hz when sweat artifacts were present) into 20 s epochs. For each channel in each sleep staged N1, N2, and N3 epoch, spectral power as well as the maximum squared deviation in amplitude from the average EEG signal was computed. Values from all channels and all NREM epochs were then visualized in one figure and outliers were identified, both manually and automatically. Visualizing all channels and epochs altogether has the advantage that extreme values can be both identified in respect to values of neighboring epochs, as well as values from other channels in the same epoch.

Artifacts were identified based on spectral power in the delta (0.5 – 4.5 Hz) and beta (20 – 30 Hz) frequency range. Power spectral density (PSD) values, from which spectral power was calculated, was computed using the pwelch() function in Matlab (Welch method, 4 s Hanning windows, 50% overlap, frequency resolution 0.25 Hz). Beforehand, the EEG was robustly Z-standardized over samples (separately for each channel). Doing so adjusts the amplitude scale across channels which allows to compare spectral power values of different channels altogether. Robust Z-standardization uses the median and inter-quartile-range (IQR) instead of the mean and standard deviation and is therefore robust towards extreme values which are naturally present in EEG data. Remaining artifacts not sensitive to spectral power were thereafter identified using the maximum squared deviation in amplitude of one channel from the average EEG signal (not Z-standardized).

Eventually, a channel was removed in a respective epoch when it contained artifacts. To confirm the presence of artifacts, the EEG and topography of channels in a respective epoch was visualized and examined. Channels in a respective epoch caught our attention when they deviated from their neighbours in terms of 1) delta power, 2) beta power, or 3) the maximum squared deviation in amplitude from the average EEG signal. In the end, we evaluated delta power computed from not Z-standardized EEG and removed any remaining artifacts. 

Before performing this routine on average referenced data, we performed it on Cz referenced data (reference as during recording). We did this to remove a good amount of artifacts before average referencing as average referencing is susceptible to large artifacts itself. More specifically, we set 20 s epochs of EEG in artifact-contaminated channels to NaN before average referencing. Thus, in total, we screened each night eight times for artifacts, each time based on a different marker. The screening of one night took approx. 10-60 minutes, depending on the quality of the data.  

In the background, two automatic outlier detection procedures supported the artifact removal routine. More specifically, outliers were automatically detected 1) channel-wise when epochs deviated more than x standard deviations from a moving average of 40 epochs and 2) epoch-wise, when channels deviated more than x standard deviations from the average of all channels. Thresholds were adapted for each night but were usually situated between 8 and 12 standard deviations.

Thereafter, channels were interpolated in those epochs in which they were labeled as bad. In case more than 3 neighboring channels were classified as bad, however, the entire epoch was rejected instead. With this method, only a minimal amound of NREM epochs needed to be rejected due to poor data quality. Epochs in which only certain channels show artifacts can be inlcuded in the analysis by interpolating those channels in the respective epoch. Moreover, being able to visualize the EEG of suspicious epochs teaches the researcher a lot about the data when performing this routine.

### Screenshot of the GUI
![](ScreenshotGUI.png "Screenshot of the Maltab GUI")


