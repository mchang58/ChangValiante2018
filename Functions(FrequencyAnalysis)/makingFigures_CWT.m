%% making Figures with CWT.m

%Filter Bank
%Band Pass Filter
[b,a] = butter(2, ([1 100]/(frequency/2)), 'bandpass');  %Band pass filter
LFP_filteredBandPass = filtfilt (b,a,LFP);             %Bandpass filtered [1 - 50 Hz] singal; because of the 76 Hz noise above, also SLEs only have frequencies up to 20 Hz

%High Pass Filter
fc = 1; % Cut off frequency; a hard stop at 2 Hz
[b,a] = butter(4,fc/(frequency/2), 'high'); %Butterworth filter of order 4
LFP_filteredHighPass = filtfilt(b,a,LFP_filteredBandPass); %filtered signal

%Low Pass Filter
fc = 100; % Cut off frequency; a hard stop at 50 Hz
[b,a] = butter(4,fc/(frequency/2), 'low'); %Bessel filter of order 8
LFP_filteredLowPass = filtfilt(b,a,LFP_filteredHighPass); %filtered signal

%detrend the LFP data
LFP_detrend = detrend(LFP); 

windowSize = 1.1;
windowOverlap = .1;

%Make vectors of SLEs, unfiltered 
for i = 1:numel(events(:,1))  
    [~, indicesBackground] = eventIndices(LFP, events(i,:), 5, frequency);    %Make vectors based on original times detected by algorithm
    epileptiformEvent_unfiltered{i,1} = LFP_detrend(indicesBackground); 
    LED_event{i,1} = LED(indicesBackground); 
end

%Make vectors of SLEs, filtered 
for i = 1:numel(events(:,1))  
    [~, indicesBackground] = eventIndices(LFP_filteredLowPass, events(i,:), 5, frequency);    %Make vectors based on original times detected by algorithm
    epileptiformEvent{i,1} = LFP_filteredLowPass(indicesBackground); 
end



%Calculate Frequency Content of Epileptiform Events
for i = 6
     %Event Vector
    eventVector = decimate(epileptiformEvent{i, 1},decimation_factor);  %decimated
    eventVector_detrend = decimate(epileptiformEvent_unfiltered{i, 1},decimation_factor);   %decimated
        
    %Time Vector
    timeVector = (0:(length(eventVector)- 1))/frequency_deciminated;
    timeVector = timeVector';    
    
   %Make filterbank | Focus on a specific frequency range 
    fb = cwtfilterbank('SignalLength', numel(eventVector), 'SamplingFrequency', frequency_deciminated, 'FrequencyLimits', [0 fc], 'Wavelet','amor');
   %Perform continuous wavelet transform to calculate frequency content
    [wt, f] = cwt(eventVector, 'FilterBank',fb);
    p = abs(wt);    %Calculate power 
    
    %Dominant Frequency at each time point 
    [maxS, idx] = max(p);        
    maxFreq = f(idx);   %finding the frequency with the maximum PSD      
    
    %Remove noise
    
    %if the maximum power at that time point is: p <0.01, make the
    %dominan frequency 0, regardless
    index_LowPower = maxS<max(maxS)*0.08;
    maxFreq(index_LowPower) = 1.314;    %This is my assumption for what baseline frequency would be.
    
    %Calculate the average frequency per second
%     P = round(frequency);     %I moved it up outside the for-loop
    x = timeVector;
    x2 = maxFreq;

    S = numel(x);
    xx = reshape(x(1:S-mod(S,P)),P,[]);
    xx2 = reshape(x2(1:S-mod(S,P)),P,[]);
    
    % Average per second
    y = sum(xx,1).'/P;
    y(:,2) = sum(xx2,1).'/P;
    
    %store the averaged max frequency content of each event 
    epileptiformEvent{i, 2} = y(:,1);
    epileptiformEvent{i, 3} = y(:,2);   
    
    clear x x2 S xx xx2 y
    
    %decipher
    [label, classification] = decipher (events,i);
    
     
    %Plot Figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', sprintf ('%s Event #%d (shading flat)', label, i)); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));

    s1=subplot (3,1,1);
    plot (timeVector, eventVector_detrend, 'color', 'k')  %Plot ictal event
    hold on
    plot (timeVector(round(windowSize*frequency_deciminated)), eventVector_detrend(round(windowSize*frequency_deciminated)), 'ro', 'color', 'black', 'MarkerFaceColor', 'green')    %SLE onset
    plot (timeVector(round(numel(eventVector)-(windowSize*frequency_deciminated))), eventVector_detrend(round(numel(eventVector)-(windowSize*frequency_deciminated))), 'ro', 'color', 'black', 'MarkerFaceColor', 'red')    %SLE offset
    title (sprintf('LFP Bandpass Filtered (%s), %s Event #%d   |   Treatment Group:%d', filter, label, i, events(i,4)))
    xlabel('Time (sec)')
    ylabel('Voltage (mV)')
    axis tight   
    
    s2=subplot (3,1,2);
    contourf(timeVector, f,p, 'edgecolor', 'none')
    shading flat
    c = colorbar;
    c.Label.String = 'Power Spectral Density (dB/Hz)';  %Originally I wrote 'Power (dB)', but I think I've been calculating the PSD
    title (sprintf('Frequency Content (PSD) of %s Event #%d. Michaels Algorithm detected: %s', label, i, classification))
    ylabel('Frequency (Hz)')
    xlabel('Time (sec)')         
    
    %reposition scale bar
    s1Pos = get(s1,'position');
    s2Pos = get(s2,'position');
    s2Pos(3:4) = [s1Pos(3:4)];
    set(s2,'position',s2Pos);
    
    subplot (3,1,3)
%     plot(timeVector,maxFreq)
    plot(epileptiformEvent{i, 2},epileptiformEvent{i, 3})
    title (sprintf('Avg. Dominant Frequency per minute over duration of %s Event #%d', label, i))
    ylabel('Frequency (Hz)')
    xlabel('Time (sec)')
    axis tight
    
    ylim ([0 30])
    
end

