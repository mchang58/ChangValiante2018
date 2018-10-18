%%Template Matching using convolution | By: Michael Chang and Kramay Patel
%This function searches for spikes (template) in the Time Series that has
%been high pass filtered to remove any DC shift.


%Time Series
timeSeries = LFP;

figure;
plot(timeSeries)
axis tight
title ('Time Series')

%Make High-Pass Filter
[b,a] = butter(4, 0.5/(10000/2), 'high');   %Highpass Filter 0.5 Hz

%Filter Time Series
LFP_highPass = filtfilt(b,a,LFP);

figure;
plot(LFP_highPass)
axis tight
title ('Time Series high pass filtered')

%A template is given
template = LFP_highPass(175700:178700);

figure;
plot(template)
axis tight
title ('Template')

%Convolution | template matching
w = conv(LFP_highPass,template, 'same');

figure;
plot(t, w)
axis tight
title ('Convolution Output')

%% Plot all the IIS spikes detected
timeSeries = LFP_detrended;

for i = 1:numel(IIS(:,1))
    startTime = (IIS(i,1)-1)*frequency;
    endTime = (IIS(i,2)+1)*frequency;

    figure;
    plot(timeSeries(startTime:endTime))
    axis tight
    title (sprintf('Spike #%d',i))
end

template = LFP_detrended(175700:178700);

    % Create a matched filter based on the template
    b = template;

    % For testing the matched filter, create a random signal which
    % contains a match for the template at some time index
    % x = [randn(200,1); template(:); randn(300,1)];
    x = LFP(1:300000);
    n = 1:length(x);

    figure;
    plot(x)
    axis tight
    title ('Time Series Signal')

    % Process the signal with the matched filter
    y = filter(b,1,x);

% Set a detection threshold (exmaple used is 90% of template)
thresh = .9;

% Compute normalizing factor
u = template.'*template;

% Find matches
%matches = n(y>thresh*u);
n = 1:length(timeSeries);
matches = n(w>thresh*u);


% Plot the results
figure;
plot(t,w,'b')
hold on
plot(t(matches), w(matches), 'ro');
axis tight
title ('Detected spikes from Template Matching')

% Print the results to the console
% display(matches);

%Dealing with IISs
spikes = SLECrawler(LFP_filtered, IIS, frequency, LED, onsetDelay, 0, locs_spike_2nd, 1);  
