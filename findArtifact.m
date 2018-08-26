function [ artifacts, locs_artifact] = findArtifact(LFP, frequency, minPeakHeight, minPeakDistance)

%Program: Artifact Finder
%Authors: Michael Chang (michael.chang@live.ca) and Liam Long
%Description: Input variables: bandpass filtered [1 - 100 Hz] LFP (timeSeries data); minPeakheight (the
%minimum height of the artifact); minPeakDistance (the minimum distance the
%artifact should be apart). If you don't specific minPeakHeight or
%minPeakDistance, it will be Q(3)*120 and 6000 (1 sec @ 10 kHz),
%respectively. The width of the population spike should also be >4 ms, on 
%average it is 110 ms in width.
%Output variables will be artifacts (matrix): the artifact onset (1st column);
%artifact offset (2nd column); artifact duration (3rd %column). The output
%will be the point in the data (not the time) and locs_artifact. To find the time, insert
%the point into the time vector. Please note, Sigma is any characteristic
%of the recording (std dev, or quartile, or mean, etc).

%% Calculate statistics of Time Serise (i.e., LFP recording)
[mx, Q] = quartilesStat(LFP);   %Quartiles, used to detect artifacts on the minor scale

% Default values, if minPeakHeight and minPeakDistance is not specified 
if nargin<2
    frequency = 10000;       %10kHz sampling frequency
    average = mean(LFP);                %Average
    sigma = std(LFP);               %Standard Deviation
    minPeakHeight = average+(sigma*100);   %artifact amplitude >120x 3rd quartile 
    minPeakDistance = 6000;    %artifact spikes seperated by .6 seconds
end

if nargin<3
    average = mean(LFP);                %Average
    sigma = std(LFP);               %Standard Deviation
    minPeakHeight = average+(sigma*100);   %artifact amplitude >120x 3rd quartile 
    minPeakDistance = 6000;    %artifact spikes seperated by .6 seconds
end

%% Finding potential artifacts
[pks_artifact, locs_artifact_potential, width] = findpeaks (LFP, 'MinPeakHeight', minPeakHeight, 'MinPeakDistance', minPeakDistance); 

%% Finding real Artifacts, width <10 ms
locs_artifact = locs_artifact_potential(width<100);

%preallocate array
artifactStart = zeros(size(locs_artifact));
artifactEnd = zeros(size(locs_artifact));
artifactDuration = zeros(size(locs_artifact));
artifacts = zeros(size(locs_artifact,1),3);

%Remove artifact spiking 
for i= 1:numel(locs_artifact);
    clear pks_artifact_spikes pks_artifact_spikes
    timeSeries=locs_artifact(i)-6000:locs_artifact(i)+6000;

    [pks_artifact_spikes, locs_artifact_spikes] = findpeaks(LFP(timeSeries), 'MinPeakHeight', Q(3)*10); %artifact should be 3x 3rd quartile 
    TF = isempty(locs_artifact_spikes);
    if TF == 1 
        return
    else            
        artifactSpikes=timeSeries(locs_artifact_spikes);

        artifactStart(i) = artifactSpikes(1);
        artifactEnd (i)= artifactSpikes(end);
        artifactDuration(i) = artifactSpikes(end)-artifactSpikes(1);
    end  
        
end

    %putting it all into an array 
    artifacts = [artifactStart, artifactEnd, artifactDuration];

end
