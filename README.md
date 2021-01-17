# Epileptiform-Event-Detector(detectionAlgorithm.m)

This repository contains documentation and code for the seizure detection algorithm mentioned in [Chang et al., 2019, JoVE](https://www.jove.com/video/57952/generation-on-demand-initiation-acute-ictal-activity-rodent-human).

Requirements:
- Windows PC
- MatLab R2015a (or later)
- Microsoft Office
- 8 GB of RAM

Quick start (For demonstration):
1) Set MatLab's working directory to ChangValiante2018.
2) Open detectionAlgorithm.m
3) Run the script
4) Specify Detection Parameters, or click "OK" and use default settings
5) Select .abf you want to analyze, or select 13226009(exampleFile).abf provided

[Video Tutorial (Full demonstration)](https://www.dropbox.com/s/wpta1wt5facegp4/Detection%20Algorithm%20%28Demo%29%20Nov%2022%2C%202018.mov?dl=0)

## Full Description:
High speed detection of ictal events (SLEs), according to the rules and specifications of  Chang et al., 2018a. The detection algorithm works by detecting all the spikes in the time series provided (.abf file) and groups spikes that are within 10 sec of each other as one event. These events are then classified based on their spiking characteristics (duration, rate, intensity, and amplitude). Events can be classified as ictal event (SLE), questionable ictal event (requires human intuition),  interictal event (IIE), interictal spike (IIS), or an artifact.

Specifying Detection Parameters (overview of GUI inputs):
When you run the script, a GUI will pop open and request the end user to specify the detection parameters. This GUI allows the end user to set the threshold for epileptiform spike detection as some multiple of the time series' baseline's sigma (Default is 3.9x, but use up to 10x in noisier data sets or in vivo recordings), where baseline is the time series without any spiking activity. End user can also set the threshold for artifact detection in a similar manner (default is 70x; future versions will also detect lower amplitude artifacts by their width, <4 ms). There is also an option to generate figures of detected SLEs and other event types (for troubleshooting purposes) as a .pptx. Lastly, there is an option to provide the directory of a folder which contains multiple .abf files that can all be analyzed continuously. For the option to choose only one file for analysis, leave the directory blank. Click "OK" on the GUI. If no directory was provided there will be a request for the end user to select a .abf file for analysis, as indicated by on-screen instructions.

![Input GUI](https://user-images.githubusercontent.com/37356279/104832613-56b8fa00-5860-11eb-8c3c-227b07439142.png)

Recommendations for Threshold setting:
Use the recommended epileptiform spike threshold: 3.9 x sigma, for in vitro recordings. However, use a higher threshold: 10 x sigma, for noisy data, results where multiple seizure-like events are grouped together, or in vivo recordings.  

Output Files:
The script outputs an excel sheet of the detected events and their associated features (i.e. duration, amplitude, intensity, spike rate); these different events will be organized by their category into different excel tabs. Additionally, there is an option to export figures of the  detect SLEs or specific event types (for troubleshooting) as a PowerPoint. These output files will be placed into the MatLab working folder.


---
Authors: Michael Chang (michael.chang@live.ca), Christopher Lucasius, Liam Long and Taufik A. Valiante.

Acknowledgements for coding strategies: Fu-der (Fred) Chen, Thomas Lordello, Vitaly Topekha, and Kramay Patel.  
Acknowledgements for labelling the seizure data: Shadini, Alina, Barret)  
Copyright 2018, Valiante Lab

Epileptiform Event Detection Code mentioned in [Chang et al., 2019. JoVE](https://www.jove.com/video/57952/generation-on-demand-initiation-acute-ictal-activity-rodent-human).

Based on the epileptiform event marking rules used in [Chang et al., 2018. Neurobiology of Disease](https://www.sciencedirect.com/science/article/pii/S0969996117302255).

Thank you for choosing to use the Valiante Lab's Epileptiform Event Detector.
