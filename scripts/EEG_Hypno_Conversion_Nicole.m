%%% Script for conversion of hypnograms and conversion of EEG data in
%%% EEGlab structs

clear all;
close all;
clc;

%define paths
GUIpath = "C:\Users\nicole\Documents\GitHub\Hd-SleepCleaner\";
maineeg = "C:\Users\nicole\Documents\EEG_data\Convertiert_mat\DATA\"; %EEG
mainh = "C:\Users\nicole\switchdrive\SingleTrains_StudyOrganization\Scoring\Nicole\"; %hypnograms
epochlength = 30;

%add GUI files to path
addpath(genpath(GUIpath));

%load EEG data from subfolders 
filelist = dir(fullfile(maineeg, "**\*Sleep-Loop*.mat")); % all files with Sleep-Loop in their name and .mat ending 
filelist = filelist(~contains({filelist.folder}, "RESULTS"))%remove RESULTS folders from list
filelist = filelist(~contains({filelist.folder}, "PREPROCESS"))%remove PREPROCESS folders from list
filelist = filelist(~contains({filelist.folder}, "Quality"))%remove Quality folders from list
filelist = filelist(~contains({filelist.folder}, "multiple"))%remove multiple folders from list
%only left with the sleep-eeg.mat 

%load EEG data from subfolders
%filelist = dir(fullfile(maineeg, "**\*"));
%subDirs = filelist([filelist.isdir]);
%IVFlag = contains({subDirs.name}, "IV");
%IVfiles = subDirs(IVFlag);

%get mat EEG files from subfolder
eegFiles = cell(1, numel(filelist));
eegPaths = cell(1, numel(filelist));
for i= 1:numel(filelist)
   eegFiles{i} = dir(fullfile(filelist(i).folder,filelist(i).name,"*.mat")).name;
   eegPaths{i} = fullfile(filelist(i).folder,filelist(i).name);
end
    
%load hypnograms from subfolders
hypno_filelist = dir(fullfile(mainh, "**\*.txt")); %get all the files in all subfolders
hypno_filelist = hypno_filelist(~contains({hypno_filelist.folder}, "old"))%remove old folders from list

%get hypnogram files from subfolder
hypnoFiles = cell(1, numel(hypno_filelist));
hypnoPaths = cell(1, numel(hypno_filelist));
for i= 1:numel(hypno_filelist)
   hypnoFiles{i} = hypno_filelist(i).name;
   hypnoPaths{i} = hypno_filelist(i).folder;
end


%generate EEGlab structure from EEG files
for i = 1:numel(eegFiles)
    EEGstruct = load(fullfile(eegPaths{i},eegFiles{i}));
    EEG = makeEEG(EEGstruct.M_VAL(:,2:3)', 250); %include also first eye channel
    newname = split(eegFiles{i},".");
    cd(eegPaths{i})
    save(newname{1,1} + "_EEGstruct_2chan.mat", 'EEG');
    fprintf("\nEEG file %s converted to struct", eegFiles{i});
end


%read hypnogram files and save as epoch data
for i = 1:numel(hypnoFiles)
    hmat = readmatrix(fullfile(hypnoPaths{i}, hypnoFiles{i})); 
    trc_idx = length(hmat) - mod(length(hmat),30);
    hmat_trc = hmat(1:trc_idx,:);
    hmat_epoch = reshape(hmat_trc, epochlength, []);
    epoch_score = mean(hmat_epoch);
    %double check that there are no diverging scores in one epoch
    good_epcs = epoch_score(mod(epoch_score,1) == 0);
    if isequal(length(good_epcs), length(epoch_score))
        fprintf("\nHypnogram %s successfully transformed to epoch format", hypnoFiles{i});
        newname = split(hypnoFiles{i},".");
        cd(hypnoPaths{i})
        save(newname{1,1} + "_EPOCH.mat", 'epoch_score');
    else
        fprintf("n\Please check epochs again in %s", hypnoFiles{i});
    end
end    