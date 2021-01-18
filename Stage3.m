%% Stage 3: Analyze the file
% Author: Michael Chang
% Run this file after Stage 2 to analyze the results and do
% additional analysis to the detected events. This creates the time vector,
% LFP time series, LED if there is light, and filters the data using a
% bandpass filter (1-50 Hz) and a low pass filter (@68 Hz)

%% Customize Analysis 
excelFileName = 'result_summary.xlsx'; %excel sheet output is written

%Label treatment groups
treatmentGroups(1,1) = {'Control'};
treatmentGroups(2,1) = {'Test'};
treatmentGroups(3,1) = {'PostTest'};
% treatmentGroups = [1:3]';

%Add all subfolders in working directory to the path.
addpath(genpath(pwd));  

%organize groups index
indexControl = events(:,4)==1;
indexTest = events(:,4)==2;
indexPosttest = events(:,4)==3;

%% Duration
%Organize groups 
feature = 3;    %column #, i.e., duration is the 3rd column
durationControl = events(events(:,4)==1,feature);
durationTest = events(events(:,4)==2,feature);
durationPosttest = events(events(:,4)==3,feature);

%duration Matrix
durationMatrix(1:numel(durationControl),1) = durationControl;
durationMatrix(1:numel(durationTest),2) = durationTest;
durationMatrix(1:numel(durationPosttest),3) = durationPosttest;
durationMatrix(durationMatrix==0) = NaN;

%Analysis
%Control Condition
[resultsDuration(1,:)] = stage3Analysis (durationControl, 'nonparametric', 'no figure');
%Test Condition
resultsDuration(2,:) = stage3Analysis (durationTest, 'nonparametric', 'no figure');
%Posttest Conditions
if numel(durationPosttest) >2
resultsDuration(3,:) = stage3Analysis (durationPosttest, 'nonparametric', 'no figure');   
end

%Comparisons
[h,p,D] = kstest2(durationControl, durationTest); %2-sample KS Test
p_value_KS_duration = p;    %KS Test's p value
d_KS_duration = D;  %KS Test's D statistic
cliffs_d_duration = CliffDelta(durationControl, durationTest);   %Cliff's d

% %Mann Whitney U Test (aka Wilcoxin Ranked Sum Test)
% [p,h,stats] = ranksum(durationControl, durationTest)

% %Independent sample Student's T-test
% [h,p,ci,stats] = ttest2(durationControl, durationTest);

%one-way ANOVA
[p,tbl,stats] = anova1(durationMatrix);
tbl_1ANOVA_duration = tbl;

% title('Box Plot of ictal event duration from different time periods')
% xlabel ('Time Period')
% ylabel ('Duration of ictal events (s)')

%multiple comparisons, Tukey-Kramer Method
c = multcompare(stats);
c_duration = c;

%Kruskal Wallis
% p = kruskalwallis(durationMatrix);
% title('Boxplot: duration of ictal events from different treatment groups')
% xlabel ('Treatment Group')
% ylabel ('Duration (s)')


%% Intensity
%Organize groups
feature = 5;
intensityControl = events(events(:,4)==1,feature);
intensityTest = events(events(:,4)==2,feature);
intensityPosttest = events(events(:,4)==3,feature);

%intensity Matrix
intensityMatrix(1:numel(intensityControl),1) = intensityControl;
intensityMatrix(1:numel(intensityTest),2) = intensityTest;
intensityMatrix(1:numel(intensityPosttest),3) = intensityPosttest;
intensityMatrix(intensityMatrix==0) = NaN;

%Analysis
%Control Condition
resultsIntensity(1,:) = stage3Analysis (intensityControl, 'nonparametric', 'nofigure');
%Test Condition
resultsIntensity(2,:) = stage3Analysis (intensityTest, 'nonparametric', 'nofigure');
%Posttest Conditions
if numel(intensityPosttest)>2
resultsIntensity(3,:) = stage3Analysis (intensityPosttest, 'nonparametric', 'nofigure');
end

%Analysis, comparison
%2-sample KS Test
[h,p,D] = kstest2 (intensityControl, intensityTest);    %KS Test's p value
p_value_KS_intensity = p; %KS Test's D statistic
d_KS_intensity = D; %KS Test's D statistic
cliffs_d_intensity = CliffDelta(intensityControl,intensityTest); %Cliff's D

% %Independent sample Student's T-test
% [h,p,ci,stats] = ttest2(intensityControl, intensityTest);

%one-way ANOVA
[p,tbl,stats] = anova1(intensityMatrix);
tbl_1ANOVA_intensity = tbl;

% title('Box Plot of ictal event intensity from different time periods')
% xlabel ('Treatment Condition')
% ylabel ('intensity of ictal events (mV^2/s)')

%Multiple Comparisons, Tukey-Kramer Method
c = multcompare(stats);
c_intensity = c;

% %Kruskal Wallis
% p = kruskalwallis(intensityMatrix);
% title('Boxplot intensity of ictal events from different treatment groups')
% xlabel ('Treatment Group')
% ylabel ('intensity (e-5)')

%% Circular Variance and Plots of Ictal Event with photosimulation    
%Calculate Theta
for i = 1:numel(events(:,1))
    events(i, 29) = events(i, 26)/events(i, 27) * (2*pi);
end
%Organize Group
feature = 29;
thetaControl = events(events(:,4)==1,feature);
thetaTest = events(events(:,4)==2,feature);
thetaPosttest = events(events(:,4)==3,feature);

% thetaControl=SLE(controlStart<SLE(:,1) & SLE(:,1)<controlEnd,feature);
% thetaTest=SLE(testStart<SLE(:,1) & SLE(:,1)<testEnd,feature);
% thetaPosttest=SLE(posttestStart<SLE(:,1) & SLE(:,1)<posttestEnd,feature);

%Analysis, light correlation?
resultsTheta(1,1)=circ_vtest(thetaControl,0);
resultsTheta(2,1)=circ_vtest(thetaTest,0);

%Figures for Visual Analysis
    FigE=figure;
    set(gcf,'Name','Control', 'NumberTitle', 'off');
    circ_plot(thetaControl,'hist',[],50,false,true,'linewidth',2,'color','r');
    title (sprintf('Control Condition, p = %.3f', resultsTheta(1,1)));

    FigF=figure;
    set(gcf,'Name','Test','NumberTitle', 'off');
    circ_plot(thetaTest,'hist',[],50,false,true,'linewidth',2,'color','r');
    title (sprintf('Test Condition, p = %.3f', resultsTheta(2,1)));

if numel(thetaPosttest)>2
    resultsTheta(3,1)=circ_vtest(thetaPosttest,0);
    %Figures for visual analysis
    FigG=figure;
    set(gcf,'Name','Post-Test','NumberTitle', 'off');
    circ_plot(thetaPosttest,'hist',[],50,false,true,'linewidth',2,'color','r');
    title (sprintf('Post-Test Condition, p = %dominantFreqControl.3f',resultsTheta(3,1)));
end

%% Dominant Frequency Content; the frequency that carries more power (PSD) w.r.t.
%https://dsp.stackexchange.com/questions/40180/the-exact-definition-of-dominant-frequency

%Preallocate
frequencyContentAnalysis = zeros(size(epileptiformEvent,1),7);

for i = 1:size(epileptiformEvent,1)
    %Place time next to the dominant frequency for each epileptiform event
    epileptiformEvent{i,3}(:,2) = epileptiformEvent{i,2};
    
    %Calculate Tonic Phase
    tonicPhase = 5; %Hz
    dominantFreq = epileptiformEvent{i,3}(:,1:2);
    indexTonic = dominantFreq(:,1) > tonicPhase;   %locate the period of time when ictal event has tonic phase
    epileptiformEvent{i,3}(:,3) = indexTonic;  %store Boolean index          
    
    %locate start of Tonic phase | Contingous segments above threshold    
    for j = 1: numel (indexTonic) %slide along the SLE; 
        if j+1 > numel(indexTonic)  %If you scan through the entire SLE and don't find a tonic phase, classify event as a IIE            
            j = find(indexTonic(:),1,'first');  %Take the 1st sec where frequency is 'high' as the onset if back-to-back high frequency are not found
                if isempty(j)
                    j = 1;  %honory position, just to push the function through                    
                end                
            startTonicPhase(1,1) = dominantFreq(j,2);    %time (s)
            startTonicPhase(1,2) = j;    %store the index
                
                while ~and(indexTonic(j) == 0, indexTonic(j+1) == 0) & dominantFreq(j,1) ~= 0; %Locate the offset time as the first point as either two continueous segments with low frequency or zero frequency, which ever comes first
                    j = j+1;    %keep sliding along the SLE until the statement above is false.
                    if j+1 > numel(indexTonic)  %If you slide all the way to the end and still can't find tonic phase offset, 
                        j = numel(indexTonic)+1;  %take the last point as the offset of the tonic phase - this means there is no clonic phase; add 1 because note you will remove it in line 33
                        classification = 2;   %1 = SLE;   2 = Tonic-only     
                        break
                    end                                    
                end            
                endTonic(1,1) = dominantFreq(j-1,2); %take the point before the frequency drops to be the end of the tonic-phase
                endTonic(1,2) = j-1;  %store the index                    
        else                        
            if indexTonic(j) > 0 && indexTonic(j+1) > 0 %If you locate two continuous segments with high frequency, mark the first segment as start of tonic phase                        
                startTonicPhase(1,1) = dominantFreq(j,2);  %store the onset time
                startTonicPhase(1,2) = j;    %store the index
                classification = 1;   %1 = tonic-clonic SLE;   2 = tonic-only
                while ~and(indexTonic(j) == 0, indexTonic(j+1) == 0) & dominantFreq(j,1) ~= 0; %Locate the offset time as the first point as either two continueous segments with low frequency or zero frequency, which ever comes first
                    j = j+1;    %keep sliding along the SLE until the statement above is false.
                    if j+1 > numel(indexTonic)  %If you slide all the way to the end and still can't find tonic phase offset, 
                        j = numel(indexTonic)+1;  %take the last point as the offset of the tonic phase - this means there is no clonic phase; add 1 because note you will remove it in line 33
                        classification = 2;   %1 = SLE;   2 = Tonic-only     
                        break
                    end                                    
                end            
                endTonic(1,1) = dominantFreq(j-1,2); %take the point before the frequency drops to be the end of the tonic-phase
                endTonic(1,2) = j-1;  %store the index   
                %This is to confirm the tonic phase is >3s
                if (endTonic(1)-startTonicPhase(1)) < 1  %There needs to be at least 3 seconds of tonic phase
                    continue
                else                                  
                    break
                end                
            end
        end        
    end
    
    %Calculate window size
    windowOverlap = epileptiformEvent{i,3}(1,2);    %the first window size represents the overlap
    windowSize = windowOverlap*2;
    
    %Ictal Event Classification 
    frequencyContentAnalysis(i,1) = classification; %0 = no ictal; 1 = tonic-clonic ictal; 2 = tonic-only ictal
    %Ictal Event Onset Time
    frequencyContentAnalysis(i,2) = startTonicPhase(1)-windowSize; %remove the padding added on to ictal event onset
    %Ictal Evenet Offset Time
    frequencyContentAnalysis(i,3) = endTonic(1)-windowSize; %remove the padding added on to ictal event onset
    %Ictal Evenet Duration
    frequencyContentAnalysis(i,4) = endTonic(1) - startTonicPhase(1);        
    %Percentage into SLE tonic phase starts
    frequencyContentAnalysis(i,5) = frequencyContentAnalysis(i,2)/ events(i,3);        
    
    [~, maxIndex] = max(dominantFreq(:,1)); %Find index max frequency occurs
    %Max Frequency
    frequencyContentAnalysis(i,6) = dominantFreq(maxIndex,1)
    %Time the max Frequency occurs
    frequencyContentAnalysis(i,7) = dominantFreq(maxIndex,2) - windowSize;      
        
end

%organize groups
dominantFreqControl = frequencyContentAnalysis (indexControl, :);
dominantFreqTest = frequencyContentAnalysis (indexTest, :);
dominantFreqPosttest = frequencyContentAnalysis (indexPosttest, :);

%Max Dominant Frequency Matrix
dominantFreqMatrix(1:size(dominantFreqControl,1),1) = dominantFreqControl(:,6);
dominantFreqMatrix(1:size(dominantFreqTest,1),2) = dominantFreqTest(:,6);
dominantFreqMatrix(1:size(dominantFreqPosttest,1),3) = dominantFreqPosttest(:,6);
dominantFreqMatrix(dominantFreqMatrix==0) = NaN;

%Analysis
%Control Condition
resultsDominantFreq(1,:) = stage3Analysis (dominantFreqControl(:,6), 'nonparametric', 'no figure');
%Test Condition
resultsDominantFreq(2,:) = stage3Analysis (dominantFreqTest(:,6), 'nonparametric', 'no figure');
%Posttest Conditions
if numel(dominantFreqPosttest(:,6)) >2
resultsDominantFreq(3,:) = stage3Analysis (dominantFreqPosttest(:,6), 'nonparametric', 'no figure');   
end

%Comparisons
[h,p,D] = kstest2(dominantFreqControl(:,6), dominantFreqTest(:,6)); %2-sample KS Test
p_value_KS_dominantFreq = p;    %KS Test's p value
d_KS_dominantFreq = D;  %KS Test's D statistic
cliffs_d_dominantFreq = CliffDelta(dominantFreqControl(:,6), dominantFreqTest(:,6));   %Cliff's d

%one-way ANOVA
[p,tbl,stats] = anova1(dominantFreqMatrix);
tbl_1ANOVA_dominantFreq = tbl;

%multiple comparisons, Tukey-Kramer Method
c = multcompare(stats);
c_dominantFreq = c;

%% Combine all the results
result = horzcat(resultsDuration(:,1:3),resultsIntensity(:,1:3),resultsTheta, resultsDominantFreq(:,1:3));  %only the first three columns

%ictal events # in each group
n(1,1)=numel(thetaControl);
n(2,1)=numel(thetaTest);
n(3,1)=numel(thetaPosttest);

%% Write results to .xls 
sheetName = FileName(1:8);

%set subtitle
A = 'Treatment Group';
B = 'Duration (s), median';
C = 'Duration (s), IQR';
D = 'AD test, normality';
E = 'Intensity (mV^2/s), median';
F = 'Intensity (mV^2/s), IQR';
G = 'AD test, normality';
H = 'Light-triggered';
I = 'Dominant Frequency, median';

II = 'Dominant Frequency, IQR';
JJ = 'AD test, normality';
KK = 'n';

J = 'KS Test, 1 vs 2';
K = 'one-way ANOVA, duration';
M = 'Multiple Comparison (Tukey-Kramer method), duration';
N = 'one-way ANOVA, intensity';
O = 'Multiple Comparison (Tukey-Kramer method), intensity';
NN = 'one-way ANOVA, dominant frequency';
OO = 'Multiple Comparison (Tukey-Kramer method), dominant frequency';

P = 'Group';
Q = 'p-value';

R = 'p-value';
S = 'KS D stat';
T = 'Cliffs D';

%Write General Results
    subtitle1 = {A, B, C, D, E, F, G, H, I, II, JJ, KK};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A1');
    xlswrite(sprintf('%s',excelFileName),treatmentGroups,sprintf('%s',sheetName),'A2');
    xlswrite(sprintf('%s',excelFileName),result,sprintf('%s',sheetName),'B2');    
    xlswrite(sprintf('%s',excelFileName),n,sprintf('%s',sheetName),'L2');
%Write KS Test results
    subtitle1 = {J};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A6');    
    xlswrite(sprintf('%s',excelFileName),p_value_KS_duration,sprintf('%s',sheetName),'B6'); %KS Test p-value
    xlswrite(sprintf('%s',excelFileName),d_KS_duration,sprintf('%s',sheetName),'C6');   %KS Test D Value
    xlswrite(sprintf('%s',excelFileName),cliffs_d_duration,sprintf('%s',sheetName),'D6');    %Cliff's D        
    xlswrite(sprintf('%s',excelFileName),p_value_KS_intensity,sprintf('%s',sheetName),'E6'); %KS Test p-value
    xlswrite(sprintf('%s',excelFileName),d_KS_intensity,sprintf('%s',sheetName),'F6'); %KS Test D value
    xlswrite(sprintf('%s',excelFileName),cliffs_d_intensity, sprintf('%s',sheetName),'G6'); %Cliff's D
    xlswrite(sprintf('%s',excelFileName),p_value_KS_dominantFreq,sprintf('%s',sheetName),'I6'); %KS Test p-value
    xlswrite(sprintf('%s',excelFileName),d_KS_dominantFreq,sprintf('%s',sheetName),'J6'); %KS Test D value
    xlswrite(sprintf('%s',excelFileName),cliffs_d_dominantFreq, sprintf('%s',sheetName),'K6'); %Cliff's D
    subtitle2 = {R,S,T};
    xlswrite(sprintf('%s',excelFileName),subtitle2,sprintf('%s',sheetName),'B5');
    xlswrite(sprintf('%s',excelFileName),subtitle2,sprintf('%s',sheetName),'E5');
    xlswrite(sprintf('%s',excelFileName),subtitle2,sprintf('%s',sheetName),'I5');
% if numel(durationPosttest)>2
%Write one-way ANOVA results, duration
    subtitle1 = {K};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A8');
    xlswrite(sprintf('%s',excelFileName),tbl_1ANOVA_duration,sprintf('%s',sheetName),'A9');
%Write multiple comparison (Tukey-Kramer), duration
    subtitle1 = {M};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A14');
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'A15'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'B15'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{Q},sprintf('%s',sheetName),'F15'); %p-value subtitle
    xlswrite(sprintf('%s',excelFileName),c_duration,sprintf('%s',sheetName),'A16');
%Write one-way ANOVA results, intensity
    subtitle1 = {N};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A20');
    xlswrite(sprintf('%s',excelFileName),tbl_1ANOVA_intensity,sprintf('%s',sheetName),'A21');
%Write multiple comparison (Tukey-Kramer), duration
    subtitle1 = {O};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A26');
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'A27'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'B27'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{Q},sprintf('%s',sheetName),'F27'); %p-value subtitle
    xlswrite(sprintf('%s',excelFileName),c_intensity,sprintf('%s',sheetName),'A28');    
%Write one-way ANOVA results, dominant frequency
    subtitle1 = {NN};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A32');
    xlswrite(sprintf('%s',excelFileName),tbl_1ANOVA_dominantFreq,sprintf('%s',sheetName),'A33');
%Write multiple comparison (Tukey-Kramer), dominant frequency
    subtitle1 = {OO};
    xlswrite(sprintf('%s',excelFileName),subtitle1,sprintf('%s',sheetName),'A38');
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'A39'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{P},sprintf('%s',sheetName),'B39'); %Group subtitle
    xlswrite(sprintf('%s',excelFileName),{Q},sprintf('%s',sheetName),'F39'); %p-value subtitle
    xlswrite(sprintf('%s',excelFileName),c_dominantFreq,sprintf('%s',sheetName),'A40');
% end

%Write frequency content analysis of epileptiform events
    subtitle1 = {A,B,C,D};
    xlswrite(sprintf('%s',FileName),subtitle1,'Freq Content Analysis','A1');    
    xlswrite(sprintf('%s',FileName),events(:,1:4),'Freq Content Analysis','A2');   
    subtitle1 = {'Classification', 'Onset, Tonic Phase', 'Offset, Tonic Phase',	'Duration, Tonic Phase', '% into SLE', 'Max Frequency',	'Time of Max Frequency'};
    xlswrite(sprintf('%s',FileName),subtitle1,'Freq Content Analysis','E1');
    xlswrite(sprintf('%s',FileName),frequencyContentAnalysis,'Freq Content Analysis','E2');   

fprintf(1,'\nComplete: A summary of the results can be found in the current working folder: %s\n', pwd)
    