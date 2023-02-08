%%% Script for conversion of hypnograms in epoch format and conversion of EEG data in
%%% EEGlab structs
clear all;
close all;
clc;

%define paths
GUIpath = "C:\Users\vakas\GitHub\outliergui\";
maineeg = "C:\Users\vakas\switchdrive\SingleTrains_StudyOrganization\DATA\"; %EEG
mainh = "C:\Users\vakas\switchdrive\SingleTrains_StudyOrganization\Scoring\checked_Vanessa\"; %hypnograms
epochlength = 30;
srate = 250;
hypnostyle = 'duration'; %choose between 'duration' (new format) or 'seconds' (old format)

%add GUI files to path
addpath(genpath(GUIpath));

%% --- load files: EEG
%TO DO: exclude *EEGstruct_singlechan.mat, *artndxn.mat in case you need to
%repeat it once you populate your folder with more data

%load EEG data from subfolders
filelist = dir(fullfile(maineeg, "**\*Sleep-Loop*.mat")); % all files with Sleep-Loop in their name and .mat ending 
filelist = filelist(~contains({filelist.folder}, "RESULTS"));%remove RESULTS folders from list
filelist = filelist(~contains({filelist.folder}, "PREPROCESS"));%remove PREPROCESS folders from list
filelist = filelist(~contains({filelist.folder}, "Quality"));%remove Quality folders from list
filelist = filelist(~contains({filelist.folder}, "multiple"));%remove multiple folders from list
%only left with the sleep-eeg.mat 

% filelist = dir(fullfile(maineeg, "**\*"));
% subDirs = filelist([filelist.isdir]);
% IVFlag = contains({subDirs.name}, "IV");
% IVfiles = subDirs(IVFlag);

%get mat EEG files from subfolder
% eegFiles = cell(1, numel(IVfiles));
% eegPaths = cell(1, numel(IVfiles));
% for i= 1:numel(IVfiles)
%    eegFiles{i} = dir(fullfile(IVfiles(i).folder,IVfiles(i).name,"*.mat")).name;
%    eegPaths{i} = fullfile(IVfiles(i).folder,IVfiles(i).name);
% end
%     

%% --- load files: Scoring
%load hypnograms from subfolders
hypno_filelist = dir(fullfile(mainh, "**\*.txt"));

%% --- generate EEGlab structure
%generate EEGlab structure from EEG files
for i = 1:length(filelist)
    EEGstruct = load(fullfile(filelist(i).folder,filelist(i).name));
    EEG = makeEEG(EEGstruct.M_VAL(:,2)', srate); %include also first eye channel
    newname = strsplit(filelist(i).name, ".");
    cd(filelist(i).folder)
    save(newname{1,1} + "_EEGstruct_singlechan.mat", 'EEG');
    fprintf("\nEEG file %s converted to struct", filelist(i).name);
end

%% --- generate hypnogram epoch matrices
%read hypnogram files and save as epoch data
for i = 1:length(hypno_filelist)
    if contains(hypnostyle, 'seconds')
        hypnomat = readmatrix(fullfile(hypno_filelist(i).folder, hypno_filelist(i).name));
        truncation_idx = length(hypnomat) - mod(length(hypnomat),epochlength);
        hypnomat_trc = hypnomat(1:truncation_idx,:);
        hypnomat_epoch = reshape(hypnomat_trc, epochlength, []);
        epoch_score = mean(hypnomat_epoch);
        
        %double check that there are no diverging scores in one epoch
        good_epcs = epoch_score(mod(epoch_score,1) == 0);
        if isequal(length(good_epcs), length(epoch_score))
            fprintf("\nHypnogram %s successfully transformed to epoch format", hypnoFiles{i});
            newname = strsplit(hypno_filelist(i).name,".");
            cd(hypno_filelist(i).folder)
            save(newname{1,1} + "_EPOCH.mat", 'epoch_score');
        else
            fprintf("n\Please check epochs again in %s", hypno_filelist(i).name);
        end
    elseif contains(hypnostyle, 'duration')
        fid = fopen(fullfile(hypno_filelist(i).folder, hypno_filelist(i).name));
        data = textscan(fid, '%q %f', 'delimiter', '\t', 'HeaderLines', 2);
        
        %night in epochs
        epos = 1:epochlength:round(data{1,2}(end));
                
        %reassign sleep stages by mapping
        keys = {'N1', 'N2', 'N3', 'REM', 'Wake'};
        values = {1, 2, 3, 4, 0};
        sleepstageMap = containers.Map(keys, values);
        
        %get index and fill in sleep stage
        previdx = 1;
        stage = zeros(round(data{1,2}(end))+1,1);
        for k = 1:length(data{1,1})
            curridx = round(data{1,2}(k));
            stage(previdx:curridx+1) = sleepstageMap(string(data{1,1}(k)));
            previdx = curridx + 1;
        end
        epoch_score = stage(1:epochlength:end);
        fprintf("\nHypnogram %s successfully transformed to epoch format", hypno_filelist(i).name);
        newname = split(hypno_filelist(i).name,".");
        cd(hypno_filelist(i).folder)
        save(newname{1,1} + "_EPOCH.mat", 'epoch_score');    
    end
end    