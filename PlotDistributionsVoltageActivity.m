%Program: Epileptiform Activity Detector
%Author: Michael Chang (michael.chang@live.ca)
%Copyright (c) 2018, Valiante Lab
%Version 8.1

%% Stage 1: Detect Epileptiform Events
%clear all (reset)
close all
clear all
clc

%Manually set File Directory
inputdir = 'C:\Users\Michael\OneDrive - University of Toronto\3) Manuscript III (Nature)\Section 2\Control Data\1) Control (VGAT-ChR2, light-triggered)\1) abf files';

%GUI to set thresholds
%Settings, request for user input on threshold
titleInput = 'Specify Detection Thresholds';
prompt1 = 'Epileptiform Spike Threshold: average + (3.9 x Sigma)';
prompt2 = 'Artifact Threshold: average + (70 x Sigma)';
prompt3 = 'Figure: Yes (1) or No (0)';
prompt4 = 'Stimulus channel (enter 0 if none):';
prompt5 = 'Troubleshooting: plot SLEs(1), IIEs(2), IISs(3), Artifacts (4), Review(5), all(6), None(0):';
prompt6 = 'To analyze multiple files in folder, provide File Directory:';
prompt = {prompt1, prompt2, prompt3, prompt4, prompt5, prompt6};
dims = [1 70];
definput = {'3.9', '70', '0', '2', '0', ''};

opts = 'on';    %allow end user to resize the GUI window
InputGUI = (inputdlg(prompt,titleInput,dims,definput, opts));  %GUI to collect End User Inputs
userInput = str2double(InputGUI(1:5)); %convert inputs into numbers

if (InputGUI(6)=="")
    %Load .abf file (raw data), analyze single file
    [FileName,PathName] = uigetfile ('*.abf','pick .abf file', inputdir);%Choose abf file
    [x,samplingInterval,metadata]=abfload([PathName FileName]); %Load the file name with x holding the channel data(10,000 sampling frequency) -> Convert index to time value by dividing 10k
    [spikes, events, SLE, details, artifactSpikes] = detectionInVitro4AP(FileName, userInput, x, samplingInterval, metadata);
else
    % Analyze all files in folder, multiple files
    PathName = char(InputGUI(6));
    S = dir(fullfile(PathName,'*.abf'));

    for k = 1:numel(S)
        clear IIS SLE_final events fnm FileName x samplingInterval metadata %clear all the previous data analyzed
        fnm = fullfile(PathName,S(k).name);
        FileName = S(k).name;
        [x,samplingInterval,metadata]=abfload(fnm);
        [spikes, events, SLE, details, artifactSpikes] = detectionInVitro4AP(FileName, userInput, x, samplingInterval, metadata);
        %Collect the average intensity ratio for SLEs
        %indexSLE = events(:,7) == 1;
        %intensity{k} = events(indexSLE,18);                   


%% Stage 2: Process the File
% Author: Michael Chang
% Run this file after the detection algorithm to analyze the results and do
% additional analysis to the detected events. This creats the time vector,
% LFP time series, LED if there is light, and filters the data.

%Create time vector
frequency = 1000000/samplingInterval; %Hz. si is the sampling interval in microseconds from the metadata
t = (0:(length(x)- 1))/frequency;
t = t';

%Seperate signals from .abf files
LFP = x(:,1);   %original LFP signal
if userInput(4)>0
    LED = x(:,userInput(4));   %light pulse signal, as defined by user's input via GUI
    onsetDelay = 0.13;  %seconds
    offsetDelay = 1.5;  %seconds
    lightpulse = LED > 1;
else
    LED =[];
    onsetDelay = [];
end

%Filter Bank
[b,a] = butter(2, ([1 100]/(frequency/2)), 'bandpass');
LFP_filtered = filtfilt (b,a,LFP);             %Bandpass filtered [1 - 100 Hz] singal

%% Stage 3: Locate interictal periods 
interictalPeriod = LFP_filtered;

%% Indices of interest
indexSLE = find(events(:,7) == 1);
SLETimes = int64(events(indexSLE,1:2));     %Collect all SLEs
epileptiformEventTimes = SLETimes;
epileptiformEventTimes(:,1) = epileptiformEventTimes(:,1) - 1;    %Move onset 0.5s early to make sure all epileptiform activity is accounted for; Warning! error will occur if the first event occured within 0.5 s of recording
epileptiformEventTimes(:,2) = epileptiformEventTimes(:,2) + 3.0;    %Move offset back 3.0s later to make sure all epileptiform activity is accounted for
% indexIIEIIS = find(or(events(:,7) == 2, events(:,7) == 3));     %Locate only the IIE & IIS events
% epileptiformEventTimes(indexIIEIIS,2) = epileptiformEventTimes(indexIIEIIS,2) + 3.0;  %Move onset back additional 3.0s for IIEs & IISs, the algorithm can't detect their offset effectively
% indexFirstSLE = find(events(:,7) == 1, 1, 'first');     %Locate where the first SLE occurs
% epileptiformEventTimes = int64(epileptiformEventTimes(indexFirstSLE:end,1:2));     %Ignore all events prior to the first SLE; int64 to make them whole numbers

%% Prepare Time Series 
%remove artifacts
for i = 1:size(artifactSpikes,1)
    timeStart = int64(artifactSpikes(i,1)*frequency);
    timeEnd = int64(artifactSpikes(i,2)*frequency);    %Remove 6 s after spike offset
    interictalPeriod (timeStart:timeEnd) = [-1];
end

%remove light pulse
if LED
    [pulse] = pulse_seq(LED);   %determine location of light pulses

    %Find range of time when light pulse has potential to trigger an event,
    for i = 1:numel(pulse.range(:,1))
        lightTriggeredOnsetRange = (pulse.range(i,1):pulse.range(i,1)+(6*frequency)); %6 s after light pulse offset
        lightTriggeredOnsetZone{i} = lightTriggeredOnsetRange;
        clear lightTriggeredRange
    end
    %Combine all the ranges where light triggered events occur into one array
    lightTriggeredOnsetZones = cat(2, lightTriggeredOnsetZone{:});  %2 is vertcat

    %% remove spiking due to light pulse
    interictalPeriod (lightTriggeredOnsetZones) = [-1];
end

%% Stage 4: %Plot histogram of distributions of Voltage activity
%Plot PowerPoint Slides
isOpen  = exportToPPTX();
if ~isempty(isOpen)
    % If PowerPoint already started, then close first and then open a new one
    exportToPPTX('close');
end
exportToPPTX('new','Dimensions',[12 6], ...
    'Title','Epileptiform Event Detector V4.0', ...
    'Author','Michael Chang', ...
    'Subject','Automatically generated PPTX file', ...
    'Comments','This file has been automatically generated by exportToPPTX');
%Add New Slide
exportToPPTX('addslide');
exportToPPTX('addtext', 'Frequency Context of Epileptiform Events detected', 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);
exportToPPTX('addtext', sprintf('File: %s', FileName), 'Position',[3 3 6 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 20);
exportToPPTX('addtext', 'By: Michael Chang', 'Position',[4 4 4 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 20);
%Add New Slide
exportToPPTX('addslide');
exportToPPTX('addtext', 'Legend', 'Position',[0 0 4 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 24);
text = 'Authors: Michael Chang, Liam Long, and Kramay Patel';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 1 6 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = 'Nyquist frequency (Max Frequency/2) typically much higher than physiology frequencies';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 2 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = 'Rayleigh frequency: 1/windowSize (Hz), is the minimum frequency that can be resolved from signal';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 3 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = 'The window size used is 10 s. so the minimum frequncy is 0.1 Hz';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 4 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = 'Accordingly, the smallest event that can be analyzed is 10 s, thus the floor duration for SLE is 10 s';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 5 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 16);

%% Create Vectors of SLEs
%Add New Slide
exportToPPTX('addslide');
text = 'Distribution of voltage activity from Seizure-Like Events (SLEs)';
exportToPPTX('addtext', sprintf('%s', text), 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);

%Add New Slide of SLE
for i = 1:numel(SLETimes(:,1))
    ictal{i,1} = LFP_filtered(SLETimes(i,1)*frequency:SLETimes(i,2)*frequency);  
    ictal{i,1} (ictal{i,1} == -1) = [];   %remove any spikes, artifacfts or like pulses during the interictal period 

    %Characterize baseline features from absolute value of the filtered data
    ictal{i,2} = mean(ictal{i,1}); %Average
    ictal{i,3} = std(ictal{i,1}); %Standard Deviation
    
    data = abs(ictal{i,1});  %interested in size so only take the absolute value
        
    %Plot figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', sprintf ('SLE #%d', i)); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));
    
    subplot (2,1,1)
    plot (ictal{i})
    title(sprintf('Ictal Event #%d. Sigma:%.4f', i, ictal{i,3}))
    axis tight
    
    subplot (2,1,2)
%     plot (sort(ictal{i}))    
%     title(sprintf('Distribution of voltage activity #%d. Sigma:%.4f', i, ictal{i,3}))
%     axis tight        

    histogram(data.^2); %bins the data for you
    set (gca, 'yscale', 'log')
    set (gca, 'xscale', 'log')

    title(sprintf('Ictal Event #%d. Histogram: Distribution of voltage activitys power | Min Data:%.4f  |  Max Data:%.4f ', i, min(data), max(data)))

    xlabel ('Power (mV^2), binned')
    ylabel ('Frequency of Occurrence')
     
    %Export figures to .pptx
    exportToPPTX('addslide'); %Draw seizure figure on new powerpoint slide
    exportToPPTX('addpicture',figHandle);
    close(figHandle)
end

%Add New Slide
exportToPPTX('addslide');
text = 'Distribution of voltage activity from all Seizure-Like Events (SLEs) combined';
exportToPPTX('addtext', sprintf('%s', text), 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);

ictalCombined = ictal(:,1);
ictalCombined = vertcat(ictalCombined{:});
data = (abs(ictalCombined));

%Plot figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', 'SLE combined together'); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));
    
    subplot (2,1,1)
    plot (ictalCombined)
    title(sprintf('%d Ictal Events combined', numel(ictal(:,1))))
    axis tight
    
    subplot (2,1,2)
%     plot (sort(ictal{i}))    
%     title(sprintf('Distribution of voltage activity #%d. Sigma:%.4f', i, ictal{i,3}))
%     axis tight        

    histogram(data.^2);
    set (gca, 'yscale', 'log')
    set (gca, 'xscale', 'log')
    title(sprintf('Histogram: Distribution of Voltage Activity from all Ictal Events. Order of Magnitude difference:%.0fx  |  Min Data:%.4f  |  Max Data:%.4f ', (max(data)/min(data)), min(data), max(data)))
    xlabel ('Power (mV^2), binned')
    ylabel ('Frequency of Occurrence')
    
    %Export figures to .pptx
    exportToPPTX('addslide'); %Draw seizure figure on new powerpoint slide
    exportToPPTX('addpicture',figHandle);
    close(figHandle)
    
%% Create Vectors of Interictal Periods
%Add New Slide
exportToPPTX('addslide');
text = 'Distribution of voltage activity from Interictal Period (between ictal events)';
exportToPPTX('addtext', sprintf('%s', text), 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);
         
interictalPeriodCount = numel(epileptiformEventTimes(:,1))-1;   %Period between epileptiform events (period behind last epileptiform event is not 'interictal', technically)
interictal = cell(interictalPeriodCount, 1);
%Add New Slide of Interictal Period
for i = 1:interictalPeriodCount
    interictal{i,1} = interictalPeriod(epileptiformEventTimes(i,2)*frequency:epileptiformEventTimes(i+1,1)*frequency);    %contains IIEs and IISs
    interictal{i,1} (interictal{i,1} == -1) = [];   %remove any spikes, artifacfts or like pulses during the interictal period 
%     if length(interictal{i})<10*frequency
%         interictal{i} = -1;
%     end
    %Characterize baseline features from absolute value of the filtered data
    interictal{i,2} = mean(interictal{i,1}); %Average
    interictal{i,3} = std(interictal{i,1}); %Standard Deviation
    
    %Bin Data
    data = abs(interictal{i,1});  %interested in size so only take the absolute value   
         
    %Plot figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', sprintf ('Interictal Period #%d', i)); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));
    
    
    subplot (2,1,1)
    plot (interictal{i})
    title(sprintf('interictal period #%d. Sigma:%.4f', i, interictal{i,3}))
    axis tight
    
    subplot (2,1,2)
%     plot (sort(data))    
%     title(sprintf('Distribution of voltage activity #%d. Sigma:%.4f', i, ictal{i,3}))
%     axis tight
        
    histogram(data.^2);
    set (gca, 'yscale', 'log')
    set (gca, 'xscale', 'log')

    title(sprintf('Interictal Event #%d. Histogram: Distribution of voltage activitys power |  Min Data:%.4f  |  Max Data:%.4f ', i, min(data), max(data)))
    xlabel ('Power (mV^2), binned')
    ylabel ('Frequency of Occurrence')
    
    %Export figures to .pptx
    exportToPPTX('addslide'); %Draw seizure figure on new powerpoint slide
    exportToPPTX('addpicture',figHandle);
    close(figHandle)
end

%Plot all the interictal periods combined
%Add New Slide
exportToPPTX('addslide');
text = 'Distribution of voltage activity from all Seizure-Like Events (SLEs) combined';
exportToPPTX('addtext', sprintf('%s', text), 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);

interictalCombined = interictal(:,1);
interictalCombined = vertcat(interictalCombined {:});
data = (abs(interictalCombined));

%Plot figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', 'Interictal Periods combined together'); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));
    
    subplot (2,1,1)
    plot (interictalCombined)
    title(sprintf('%d Interictal Periods combined', numel(interictal(:,1))))
    axis tight        

    subplot (2,1,2)
    histogram((data).^2);    %this is the power of the voltage activity
    set (gca, 'yscale', 'log')
    set (gca, 'xscale', 'log')
    title(sprintf('Histogram: Distribution of Voltage Activitys power during all interictal periods combined.  Min Data:%.4f  |  Max Data:%.4f ', min(data), max(data)))
    xlabel ('Power (mV^2), binned')
    ylabel ('Frequency of Occurrence')

    %Export figures to .pptx
    exportToPPTX('addslide'); %Draw seizure figure on new powerpoint slide
    exportToPPTX('addpicture',figHandle);
    close(figHandle)
    

% save and close the .PPTX
subtitle = '(DistributionVoltagePower)';
excelFileName = FileName(1:8);
exportToPPTX('saveandclose',sprintf('%s%s', excelFileName, subtitle));
    

fprintf(1,'\nThank you for choosing to use the Valiante Labs Epileptiform Activity Detector.\n')   

    end
end