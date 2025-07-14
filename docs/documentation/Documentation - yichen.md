# EarthViewer main GUI Documentation

The GUI itself was built using Matlab AppDesigner. The GUI itself is mostly parametric and should fit most types of display without difficulty. 

## Data handling 

The GUI encapsulate the dataset loading and selection proccess. Each visualization implementation only need to visualize the already prepared data contained in the following app level variables.

```
app.ImageDatasets cell

app.AlignedImages cell

app.CroppedImages cell

app.CurrentLoadedTable table
```
The visualization should provide a way to update its content that could be called once the currently selected dataset is changed. 