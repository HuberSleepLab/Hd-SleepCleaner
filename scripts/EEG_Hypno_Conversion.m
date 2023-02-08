%%% Script for conversion of hypnograms and conversion of EEG data in
%%% EEGlab structs

clear all;
close all;
clc;

%define paths
GUIpath = "C:\Users\vakas\GitHub\outliergui\";
maineeg = "E:\HuberLab\01_SingleTrain_Pilot\Sleep_EXPORT\HC\"; %EEG
mainh = "C:\Users\vakas\switchdrive\SingleTrains_StudyOrganization\Scoring\checked_Vanessa\PDR008\Screening\"; %hypnograms
epochlength = 30;
hypnostyle = 'duration'; %choose between 'duration' (new format) or 'seconds' (old format)

%add GUI files to path
addpath(genpath(GUIpath));

%% --- load files
%TO DO: load files recursively from subfolders, making sure that only
%parsed SleepLoop .mat files are loaded (exclude *EEGstruct_singlechan.mat,
%*artndxn.mat, *device_parameters.mat)

%load EEG data from subfolders
filelist = dir(fullfile(maineeg, "**\*"));
subDirs = filelist([filelist.isdir]);
IVFlag = contains({subDirs.name}, "IV");
IVfiles = subDirs(IVFlag);

%get mat EEG files from subfolder
eegFiles = cell(1, numel(IVfiles));
eegPaths = cell(1, numel(IVfiles));
for i= 1:numel(IVfiles)
   eegFiles{i} = dir(fullfile(IVfiles(i).folder,IVfiles(i).name,"*.mat")).name;
   eegPaths{i} = fullfile(IVfiles(i).folder,IVfiles(i).name);
end
    
%TO DO: load files recursively from Scoring/checked_Vanessa/
%load hypnograms from subfolders
hypno_filelist = dir(fullfile(mainh, "*.txt"));

%get hypnogram files from subfolder
hypnoFiles = cell(1, numel(hypno_filelist));
hypnoPaths = cell(1, numel(hypno_filelist));
for i= 1:numel(hypno_filelist)
   hypnoFiles{i} = hypno_filelist(i).name;
   hypnoPaths{i} = hypno_filelist(i).folder;
end

%% --- generate EEGlab structure

%generate EEGlab structure from EEG files
for i = 1:numel(eegFiles)
    EEGstruct = load(fullfile(eegPaths{i},eegFiles{i}));
    EEG = makeEEG(EEGstruct.M_VAL(:,2)', 250); %include also first eye channel
    newname = split(eegFiles{i},".");
    cd(eegPaths{i})
    save(newname{1,1} + "_EEGstruct_singlechan.mat", 'EEG');
    fprintf("\nEEG file %s converted to struct", eegFiles{i});
end

%% --- generate hypnogram epoch matrices
%read hypnogram files and save as epoch data
for i = 1:numel(hypnoFiles)
    if contains(hypnostyle, 'seconds')
        hmat = readmatrix(fullfile(hypnoPaths{i}, hypnoFiles{i}));
        trc_idx = length(hmat) - mod(length(hmat),epochlength);
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
    elseif contains(hypnostyle, 'duration')
        fid = fopen(fullfile(hypnoPaths{i}, hypnoFiles{i}));
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
        fprintf("\nHypnogram %s successfully transformed to epoch format", hypnoFiles{i});
        newname = split(hypnoFiles{i},".");
        cd(hypnoPaths{i})
        save(newname{1,1} + "_EPOCH.mat", 'epoch_score');    
    end
end    