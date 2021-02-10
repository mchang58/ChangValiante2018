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
LFP_detrended = detrend(LFP); 

windowSize = 1.1;
windowOverlap = .1;

%Make vectors of SLEs, unfiltered 
for i = 1:numel(events(:,1))  
    [~, indicesBackground] = eventIndices(LFP, events(i,:), 5, frequency);    %Make vectors based on original times detected by algorithm
    epileptiformEvent_unfiltered{i,1} = LFP(indicesBackground); 
    LED_event{i,1} = LED(indicesBackground); 
end

%Make vectors of SLEs, filtered 
for i = 1:numel(events(:,1))  
    [~, indicesBackground] = eventIndices(LFP_filteredLowPass, events(i,:), 5, frequency);    %Make vectors based on original times detected by algorithm
    epileptiformEvent{i,1} = LFP_filteredLowPass(indicesBackground); 
end

%Calculate Frequency Content of Epileptiform Events
for i = 7
    %Event Vector
    eventVector = epileptiformEvent{i, 1};
    eventVector_unfiltered = detrend(epileptiformEvent_unfiltered{i,1});
    LED_vector = LED_event{i,1};
    
    %Time Vector
    timeVector = (0:(length(eventVector)- 1))/frequency;
    timeVector = timeVector';    
    
    %Frequency content of epileptiform event 
    [s,f,t,p] = spectrogram (eventVector,round(windowSize*frequency),round(windowOverlap*frequency), 2.^nextpow2(windowSize*frequency), frequency, 'yaxis');
    
    %Dominant Frequency at each time point 
    [maxS, idx] = max(p);        
    maxFreq = f(idx);   %finding the frequency with the maximum PSD
    indexInvalid = find (maxFreq > fc);  %Ignore all frequency above fc (frequency cutoff)
    maxFreq(indexInvalid) = 0;
    
    %store the max frequency content of each event 
    epileptiformEvent{i, 2} = t;
    epileptiformEvent{i, 3} = maxFreq;    

    %decipher
    [label, classification] = decipher (events,i);

    %Plot Figures
    figHandle = figure;
    set(gcf,'NumberTitle','off', 'color', 'w'); %don't show the figure number
    set(gcf,'Name', sprintf ('%s Event #%d', label, i)); %select the name you want
    set(gcf, 'Position', get(0, 'Screensize'));

    subplot (3,1,1)
    plot (timeVector(round(windowOverlap*frequency):round(t(end)*frequency)), eventVector_unfiltered(round(windowOverlap*frequency):round(t(end)*frequency)), 'k')  %Plot ictal event
    hold on
    plot (timeVector(round(windowSize*frequency)), eventVector_unfiltered(round(windowSize*frequency)), 'ro', 'color', 'black', 'MarkerFaceColor', 'green')    %SLE onset
    plot (timeVector(round(numel(eventVector_unfiltered)-(windowSize*frequency))), eventVector_unfiltered(round(numel(eventVector_unfiltered)-(windowSize*frequency))), 'ro', 'color', 'black', 'MarkerFaceColor', 'red')    %SLE offset
    plot (timeVector(round(windowOverlap*frequency):round(t(end)*frequency)), LED_vector(round(windowOverlap*frequency):round(t(end)*frequency)), 'b')  %Plot LED vector
    title (sprintf('LFP Bandpass Filtered (%s), %s Event #%d   |   Treatment Group:%d', filter, label, i, events(i,4)))
    xlabel('Time (sec)')
    ylabel('Voltage (mV)')
    axis tight   
    
    subplot (3,1,2)
    imagesc(t,f,10*log10(p))
    c = colorbar;
    c.Label.String = 'Power (dB)';  
    ylim([0 100])
    title (sprintf('Frequency Content (PSD) of %s Event #%d. Michaels Algorithm detected: %s', label, i, classification))
    ylabel('Frequency (Hz)')
    xlabel('Time (sec)')         
    
    subplot (3,1,3)
    plot(t,maxFreq) 
    title (sprintf('Dominant Frequency over duration of %s Event #%d', label, i))
    ylabel('Frequency (Hz)')
    xlabel('Time (sec)')
    axis tight
    ylim  ([0 50])        
end

