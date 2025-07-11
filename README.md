# TUM CV Challenge 2025

## Description

This branch currently contains the CV challenge GUI Implementation by Yichen Zhang @NoMoreNameToUse.
This branch is kept clean and features from other branch will be incorporated in the GUI.

## Getting Started

### 1. Clone the repository

```bash
git clone -b gui-playground https://github.com/NoMoreNameToUse/tum-cv-challenge-2025.git
```

### 2. Running the GUI
 
* Open Gitlab and make sure the whole repo is in the MATLAB PATH
* Open cv_app.mlapp and run it

### 3. Contribute 

* Please keep this repo clean. 
* For each implemented feature, mark the file with 
```
% Docs: [name of contributor], branch [name of branch], commit [commit id]
```
* The currently loaded and active dataset information is stored in 
```
app.CurrentLoadedTable
```
in form of a matlab table. 

* The corresponding proccessed images are stored in cells under 
```
app.AlignedImages 
app.CroppedImages 
```
* And all currently loaded dataset can be found as cells of tables in 

```
app.ImageDatasets
```
## Changelog
Initial upload GUI V0.1:
* Basic GUI functionality including dataset select, multiple dataset import and dataset switching

GUI V0.2: 
* Updated the preprocessImageSequence.m implementation from martin to the newest version
* Dataset name now shown alongside image file names due to new dataset naming convention
* Cleaned up some internal copy pasta variable and GUI update sequence

GUI V0.3: 
Achieved feature parity with Kai's Revamped GUI and implemented new features
* Implemented slider view from Kai's GUI Revamp with original code from Rongfei
* Implemented side by side view from Kai's GUI Revamp with original code from Rongfei
* Implemented timelapse view from Kai's GUI Revamp with original code from Rongfei
* Implemented difference highlight view from Kai's GUI Revamp with updated code from Zihan
* Implemented heatmap view from Kai's GUI Revamp with updated code from Zihan
* Implemented flicker view from Kai's GUI Revamp with updated code from Zihan
