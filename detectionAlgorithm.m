%Program: Epileptiform Activity Detector
%Author: Michael Chang (michael.chang@live.ca), Fred Chen and Liam Long;
%Copyright (c) 2018, Valiante Lab
%Version 8.0

%% Stage 1: Detect Epileptiform Events
%clear all (reset)
close all
clear all
clc

%Manually set File Director
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
    [spikes, events, SLE, details] = detectionInVitro4AP(FileName, userInput, x, samplingInterval, metadata);
else
    % Analyze all files in folder, multiple files
    PathName = char(InputGUI(6));
    S = dir(fullfile(PathName,'*.abf'));

    for k = 1:numel(S)
        clear IIS SLE_final events fnm FileName x samplingInterval metadata %clear all the previous data analyzed
        fnm = fullfile(PathName,S(k).name);
        FileName = S(k).name;
        [x,samplingInterval,metadata]=abfload(fnm);
        [spikes, events, SLE, details] = detectionInVitro4AP(FileName, userInput, x, samplingInterval, metadata);
        %Collect the average intensity ratio for SLEs
        %indexSLE = events(:,7) == 1;
        %intensity{k} = events(indexSLE,18);                   

%% Stage 2: Process the File
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

%% Stage 3: m-Calculation

%Set Variables
k_max = 10000;  %Largest possible value for a 1 s window (@10 kHz)
contextDuration = 20;  %second

% Creating powerpoint slide
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
exportToPPTX('addtext', 'M Calculation (Branch Ratio) for Epileptiform Events detected', 'Position',[2 1 8 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 36);
exportToPPTX('addtext', sprintf('File: %s', FileName), 'Position',[3 3 6 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 20);
exportToPPTX('addtext', 'By: Michael Chang', 'Position',[4 4 4 2],...
             'Horiz','center', 'Vert','middle', 'FontSize', 20);
%Add New Slide
exportToPPTX('addslide');
exportToPPTX('addtext', 'Legend', 'Position',[0 0 4 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 24);
text = 'Authors: Liam Long and Michael Chang';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 1 6 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = 'Calculations performed by python script written by Wilting and Priesemann, 2018';
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 2 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = sprintf('Duration of background for context: %d seconds', contextDuration);
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 3 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = sprintf('The window size for m calculation: %.2f seconds (@10 kHz)', (k_max+200)/frequency);
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 4 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 14);
text = sprintf('k_max: %.0f points', k_max);
exportToPPTX('addtext', sprintf('%s',text), 'Position',[0 5 5 1],...
             'Horiz','left', 'Vert','middle', 'FontSize', 16);

for i = 1:size(events(:,1),1)
%Find indices of events
[indicesEvent,indicesBackground] = eventIndices(LFP_filtered, events(i,:), contextDuration, frequency);   %Accounts for padding the ends
eventVector = LFP_filtered(indicesEvent);
backgroundVector = LFP_filtered(indicesBackground);
timeVector = t(indicesBackground);

%Size of background vector 
backgroundLength = floor(length(backgroundVector)/k_max);

%Preallocate Memory for Cell Array
m = cell(1,backgroundLength);
M = zeros(backgroundLength,3);
skip = 0;
%Calculate m for each window along the length of the event
for j = 0:backgroundLength-1    %Start at zero, allows me to account for the very beginning of the time series, and each iteration incresaes by k_max (the window size) | I use the maximum k-max for the window size, so I should have the most accurate reading of the signal's stability
 
    if numel(backgroundVector) >= (j+1)*k_max+100
        a_t = backgroundVector(1+(j*k_max):(j+1)*k_max+100);    %I have to add 1 to the indices to account for the fact range starts at zero
    else
        m{j+1} = [];
        M(j+1,:) = [];
        skip = 1;   %if the last window was skipped because it was too short for the k_max for calculation, keep track of it in the program for plotting later
        continue %don't calculate the last window if there are not enough data points
    end
    m{j+1}=WP_MultipleRegression(a_t', k_max);  %Calculate M | Store Struct output
    M(j+1,1) = m{j+1}.branching_ratio;  %"m value" 
    M(j+1,2) = m{j+1}.naive_branching_ratio;    %"conventional m value" 
    M(j+1,3) = m{j+1}.autocorrelationtime;  %Store values into a matrix for plotting
end

%Classification labels for plotting
[label, classification] = decipher (events,i);

%Plot Results
figHandle = figure;
set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
set(gcf,'Name','Overview of Data: m calculation by Wilting and Priesemann, 2018'); %select the name you want
set(gcf, 'Position', get(0, 'Screensize'));

figHandle = plotEvent(figHandle, LFP_filtered, t, events(i,:), [], LED, contextDuration, frequency);
hold on
ylabel ('LFP (mV)');
%     xlabel ('Time (s)');

    yyaxis right

%Make Time Vector for the m-Calculation
startBackground = (events(i,1)-contextDuration)*frequency;
endBackground = (events(i,2)+contextDuration)*frequency;
index_mCalc = int64(startBackground:k_max:endBackground);
if skip == 1    %if the last window was skipped, remove the index for the last window for plotting purposes
    index_mCalc(end) = [];
    skip = 0;   %index has been removed, so turn off skip.
end

if i~=1 %if not the first iteration
    while numel(index_mCalc) > numel(M(:,1))   %remove all the indices at the end that are extra (that were padding)
    index_mCalc(end) = [];
    end
else   %if it is the first iteration
    while numel(index_mCalc) > numel(M(:,1))    %remove all the indices in the beginning that are extra (padding)
    index_mCalc(1) = [];
    end    
end

plot (t(index_mCalc), M(:,1), 'o', 'color', 'k', 'MarkerFaceColor', 'g') %, %Connect all dots w/ black line
plot (t(index_mCalc), M(:,1), 'o', 'color', 'k') %Fill in dots with green

%fixed

% plot (M(:,1), 'o', 'color', 'k', 'MarkerFaceColor', 'g') %, %Connect all dots w/ black line
% plot (M(:,1), 'o', 'color', 'k') %Place holder symbol on the Legend for describing classification

title (sprintf('Overview of m Calculation for event #%d: %s @ %.1f sec', i, label, events(i,1)));
ylabel ('m (Branching Ratio)');
xlabel ('Time (s)');
legend ('LFP filtered', 'Epileptiform Event', 'Detected Onset', 'Detected Offset', 'Applied Stimulus', 'm (Branching Ratio)',  sprintf('Classification: %s', classification))
legend ('Location', 'northeastoutside')
axis tight

set(gca,'fontsize',14)

 %Export figures to .pptx
 exportToPPTX('addslide'); %Draw seizure figure on new powerpoint slide
 exportToPPTX('addpicture',figHandle);
 close(figHandle)

end

%save and close the .PPTX
excelFileName = FileName(1:8);
subtitle = '(mCalculation)';
exportToPPTX('saveandclose',sprintf('%s%s', excelFileName, subtitle));

    end
end


