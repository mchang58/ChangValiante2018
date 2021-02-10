%Decimate data to find dominant Frequency 

%     frequency_original = frequency;
%     frequency =  frequency/10;

    %Event Vector
    eventVector = decimate(epileptiformEvent{i, 1},10);
    
    %Time Vector
    timeVector = (0:(length(eventVector)- 1))/frequency;
    timeVector = timeVector';    
    
   %Perform continuous wavelet transform to calculate frequency content
   %Make filterbank | Focus on a specific frequency range 
    fb = cwtfilterbank('SignalLength', numel(eventVector), 'SamplingFrequency', frequency, 'FrequencyLimits', [0 fc], 'Wavelet','amor');
    [wt, f] = cwt(eventVector, 'FilterBank',fb);
    p = abs(wt);    %Calculate power 
    
    %Dominant Frequency at each time point 
    [maxS, idx] = max(p);        
    maxFreq = f(idx);   %finding the frequency with the maximum PSD      
    
    %Remove noise
    
    %if the maximum power at that time point is: p <0.01, make the
    %dominan frequency 0, regardless
    index_LowPower = maxS<max(maxS)*0.1;
    maxFreq(index_LowPower) = 1.314;    %This is my assumption for what baseline frequency would be.
    
    %Calculate the average frequency per second
%     P = round(frequency);
    x = timeVector;
    x2 = maxFreq;

    S = numel(x);
    xx = reshape(x(1:S-mod(S,P)),P,[]);
    xx2 = reshape(x2(1:S-mod(S,P)),P,[]);
    
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
    plot (timeVector, eventVector)  %Plot ictal event
    hold on
    plot (timeVector(round(windowSize*frequency)), eventVector(round(windowSize*frequency)), 'ro', 'color', 'black', 'MarkerFaceColor', 'green')    %SLE onset
    plot (timeVector(round(numel(eventVector)-(windowSize*frequency))), eventVector(round(numel(eventVector)-(windowSize*frequency))), 'ro', 'color', 'black', 'MarkerFaceColor', 'red')    %SLE offset
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
    plot(timeVector,maxFreq) 
    title (sprintf('Dominant Frequency over duration of %s Event #%d', label, i))
    ylabel('Frequency (Hz)')
    xlabel('Time (sec)')
    axis tight
    