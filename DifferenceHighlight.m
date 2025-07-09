function AdvancedDifferenceTool
    % Advanced Difference Analysis Tool - Enhanced Professional Version with Improved Visualization
    
    % Global variables
    originalImgs = {};
    processedImgs = {};
    imgNames = {};
    metaData = [];
    selectedImg1 = 1;
    selectedImg2 = 2;
    currentThreshold = 0.1;
    flickTimer = [];
    flickState = false;
    currentHighlightImg = [];
    isHeatmapOn = false;
    isHighlightOn = false;
    isIncreaseOnlyOn = false;
    isDecreaseOnlyOn = false;
    
    % UI control handles
    statusText = [];
    img1Popup = [];
    img2Popup = [];
    thresholdSlider = [];
    thresholdText = [];
    heatmapToggle = [];
    highlightToggle = [];
    flickBtn = [];
    flickSpeedSlider = [];
    flickSpeedText = [];
    increaseLamp = [];
    decreaseLamp = [];
    
    % Display axes handles
    ax1 = [];
    ax2 = [];
    ax3 = [];
    ax4 = [];
    ax5 = [];
    
    % Create main interface - enhanced layout
    fig = figure('Name', 'Advanced Difference Analysis Tool - Enhanced Professional Edition', ...
                 'Position', [50, 50, 1600, 900], ...
                 'MenuBar', 'none', 'ToolBar', 'none', ...
                 'Color', [0.96, 0.96, 0.96], ...
                 'CloseRequestFcn', @closeFigure);
    
    % Create interface layout
    createInterface();
    
    function createInterface()
        % Enhanced control panel - increased height and better spacing
        controlPanel = uipanel('Parent', fig, 'Title', 'Control Panel', ...
                              'Position', [0.01, 0.75, 0.98, 0.24], ...
                              'FontSize', 16, 'FontWeight', 'bold', ...
                              'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Image display panel - adjusted for new control panel size
        imagePanel = uipanel('Parent', fig, 'Title', 'Image Display Area', ...
                            'Position', [0.01, 0.01, 0.98, 0.73], ...
                            'FontSize', 16, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.98, 0.98, 0.98]);
        
        createEnhancedControlPanel(controlPanel);
        createImagePanel(imagePanel);
    end
    
    function createEnhancedControlPanel(controlPanel)
        % Row 1: File Operations (Top row) - using normalized coordinates
        
        % Load folder button
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Load Folder', 'Units', 'normalized', ...
                  'Position', [0.02, 0.7, 0.12, 0.25], ...
                  'FontSize', 12, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.2, 0.5, 0.8], 'ForegroundColor', 'white', ...
                  'Callback', @loadFolder);
        
        % Status text
        statusText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                              'String', 'Status: Ready to load images', ...
                              'Units', 'normalized', 'Position', [0.15, 0.7, 0.4, 0.25], ...
                              'FontSize', 11, 'HorizontalAlignment', 'left', ...
                              'BackgroundColor', [0.94, 0.94, 0.94], ...
                              'ForegroundColor', [0, 0.4, 0]);
        
        % Pipeline info
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Pipeline: Alignment → Cropping → Brightness Normalization', ...
                  'Units', 'normalized', 'Position', [0.56, 0.8, 0.22, 0.15], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94], 'ForegroundColor', [0, 0.5, 0]);
        
        % Tools section - enhanced with GIF save
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Tools:', 'Units', 'normalized', ...
                  'Position', [0.80, 0.85, 0.06, 0.15], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Reset', 'Units', 'normalized', ...
                  'Position', [0.78, 0.7, 0.05, 0.2], ...
                  'FontSize', 9, 'Callback', @resetDisplay);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Save', 'Units', 'normalized', ...
                  'Position', [0.84, 0.7, 0.05, 0.2], ...
                  'FontSize', 9, 'Callback', @saveResults);
        
        % NEW: Save GIF button
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Save GIF', 'Units', 'normalized', ...
                  'Position', [0.90, 0.7, 0.05, 0.2], ...
                  'FontSize', 9, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.8, 0.2, 0.2], 'ForegroundColor', 'white', ...
                  'Callback', @saveFlickAsGIF);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Export', 'Units', 'normalized', ...
                  'Position', [0.96, 0.7, 0.03, 0.2], ...
                  'FontSize', 9, 'Callback', @exportData);
        
        % Row 2: Image Selection and Parameters (Middle row)
        
        % Image selection
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image Selection:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.45, 0.12, 0.15], ...
                  'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image A:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.25, 0.06, 0.15], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        img1Popup = uicontrol('Parent', controlPanel, 'Style', 'popupmenu', ...
                             'String', {'Load images first'}, 'Units', 'normalized', ...
                             'Position', [0.08, 0.25, 0.18, 0.15], ...
                             'FontSize', 9, 'Callback', @selectImage1);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image B:', 'Units', 'normalized', ...
                  'Position', [0.28, 0.25, 0.06, 0.15], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        img2Popup = uicontrol('Parent', controlPanel, 'Style', 'popupmenu', ...
                             'String', {'Load images first'}, 'Units', 'normalized', ...
                             'Position', [0.34, 0.25, 0.18, 0.15], ...
                             'FontSize', 9, 'Callback', @selectImage2);
        
        % Threshold control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Threshold:', 'Units', 'normalized', ...
                  'Position', [0.54, 0.45, 0.08, 0.15], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        thresholdSlider = uicontrol('Parent', controlPanel, 'Style', 'slider', ...
                                   'Min', 0, 'Max', 1, 'Value', 0.1, ...
                                   'Units', 'normalized', 'Position', [0.54, 0.25, 0.15, 0.15], ...
                                   'Callback', @updateThreshold);
        
        thresholdText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                 'String', '0.10', 'Units', 'normalized', ...
                                 'Position', [0.70, 0.25, 0.04, 0.15], ...
                                 'FontSize', 10, 'HorizontalAlignment', 'center', ...
                                 'BackgroundColor', [1, 1, 1]);
        
        % Change indicators - adjusted positions to avoid overlap
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Indicators:', 'Units', 'normalized', ...
                  'Position', [0.76, 0.45, 0.10, 0.15], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        increaseLamp = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                'String', '●', 'Units', 'normalized', ...
                                'Position', [0.75, 0.35, 0.05, 0.14], ...
                                'FontSize', 18, 'HorizontalAlignment', 'center', ...
                                'ForegroundColor', [0.5, 0.5, 0.5], 'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Inc', 'Units', 'normalized', ...
                  'Position', [0.79, 0.33, 0.04, 0.12], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        decreaseLamp = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                'String', '●', 'Units', 'normalized', ...
                                'Position', [0.83, 0.35, 0.05, 0.14], ...
                                'FontSize', 18, 'HorizontalAlignment', 'center', ...
                                'ForegroundColor', [0.5, 0.5, 0.5], 'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Dec', 'Units', 'normalized', ...
                  'Position', [0.87, 0.33, 0.04, 0.12], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Row 3: Analysis Functions (Bottom row)
        
        % Analysis functions
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Analysis Functions:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.05, 0.15, 0.12], ...
                  'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Main analysis toggles
        heatmapToggle = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                                 'String', 'Heatmap', 'Units', 'normalized', ...
                                 'Position', [0.18, 0.02, 0.08, 0.18], ...
                                 'FontSize', 10, 'FontWeight', 'bold', ...
                                 'BackgroundColor', [0.9, 0.9, 0.9], ...
                                 'Callback', @toggleHeatmap);
        
        highlightToggle = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                                   'String', 'Highlight', 'Units', 'normalized', ...
                                   'Position', [0.27, 0.02, 0.08, 0.18], ...
                                   'FontSize', 10, 'FontWeight', 'bold', ...
                                   'BackgroundColor', [0.9, 0.9, 0.9], ...
                                   'Callback', @toggleHighlight);
        
        % Specific analysis buttons
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Increase', 'Units', 'normalized', ...
                  'Position', [0.36, 0.02, 0.08, 0.18], ...
                  'FontSize', 10, 'Callback', @showIncreaseOnly);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Decrease', 'Units', 'normalized', ...
                  'Position', [0.45, 0.02, 0.08, 0.18], ...
                  'FontSize', 10, 'Callback', @showDecreaseOnly);
        
        % Flick control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Flick:', 'Units', 'normalized', ...
                  'Position', [0.55, 0.05, 0.05, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        flickBtn = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                            'String', 'Start', 'Units', 'normalized', ...
                            'Position', [0.61, 0.02, 0.06, 0.18], ...
                            'FontSize', 10, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.9, 0.9, 0.9], ...
                            'Callback', @toggleFlick);
        
        % Flick speed control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Speed:', 'Units', 'normalized', ...
                  'Position', [0.68, 0.12, 0.05, 0.08], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        flickSpeedSlider = uicontrol('Parent', controlPanel, 'Style', 'slider', ...
                                    'Min', 0.1, 'Max', 1, 'Value', 0.5, ...
                                    'Units', 'normalized', 'Position', [0.68, 0.02, 0.08, 0.08], ...
                                    'Callback', @updateFlickSpeed);
        
        flickSpeedText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                  'String', '0.5s', 'Units', 'normalized', ...
                                  'Position', [0.77, 0.02, 0.03, 0.08], ...
                                  'FontSize', 9, 'HorizontalAlignment', 'center', ...
                                  'BackgroundColor', [1, 1, 1]);
    end
    
    function createImagePanel(imagePanel)
        % Create image display areas with mouse wheel zoom functionality
        ax1 = axes('Parent', imagePanel, 'Position', [0.03, 0.55, 0.30, 0.40]);
        title(ax1, 'Original Image A', 'FontSize', 13, 'FontWeight', 'bold');
        axis(ax1, 'off');
        enableMouseWheelZoom(ax1);
        
        ax2 = axes('Parent', imagePanel, 'Position', [0.35, 0.55, 0.30, 0.40]);
        title(ax2, 'Original Image B', 'FontSize', 13, 'FontWeight', 'bold');
        axis(ax2, 'off');
        enableMouseWheelZoom(ax2);
        
        ax3 = axes('Parent', imagePanel, 'Position', [0.67, 0.55, 0.30, 0.40]);
        title(ax3, 'Preprocessed Overlay', 'FontSize', 13, 'FontWeight', 'bold');
        axis(ax3, 'off');
        enableMouseWheelZoom(ax3);
        
        ax4 = axes('Parent', imagePanel, 'Position', [0.03, 0.05, 0.45, 0.45]);
        title(ax4, 'Difference Analysis Results', 'FontSize', 13, 'FontWeight', 'bold');
        axis(ax4, 'off');
        enableMouseWheelZoom(ax4);
        
        ax5 = axes('Parent', imagePanel, 'Position', [0.52, 0.05, 0.45, 0.45]);
        title(ax5, 'Flick Display (Earlier ↔ Changes)', 'FontSize', 13, 'FontWeight', 'bold');
        axis(ax5, 'off');
        % ax5 (flick display) does not have zoom functionality
    end
    
    function enableMouseWheelZoom(axHandle)
        % Enable mouse wheel zoom functionality for the specified axes
        set(axHandle, 'ButtonDownFcn', @(src,evt) set(fig, 'WindowScrollWheelFcn', @(src,evt) mouseWheelZoom(src,evt,axHandle)));
        set(fig, 'WindowButtonMotionFcn', @(src,evt) updateScrollTarget(src,evt));
    end
    
    function updateScrollTarget(~, ~)
        % Update which axes should receive scroll events based on mouse position
        currentPoint = get(fig, 'CurrentPoint');
        figPos = get(fig, 'Position');
        
        % Convert to normalized coordinates
        normX = currentPoint(1) / figPos(3);
        normY = currentPoint(2) / figPos(4);
        
        % Check which axes the mouse is over (excluding ax5 - flick display)
        targetAx = [];
        axesList = [ax1, ax2, ax3, ax4]; % ax5 excluded from zoom functionality
        
        for i = 1:length(axesList)
            if isvalid(axesList(i))
                pos = get(axesList(i), 'Position');
                if normX >= pos(1) && normX <= pos(1) + pos(3) && ...
                   normY >= pos(2) && normY <= pos(2) + pos(4)
                    targetAx = axesList(i);
                    break;
                end
            end
        end
        
        % Set the scroll wheel function for the target axes
        if ~isempty(targetAx)
            set(fig, 'WindowScrollWheelFcn', @(src,evt) mouseWheelZoom(src,evt,targetAx));
        else
            set(fig, 'WindowScrollWheelFcn', []);
        end
    end
    
    function mouseWheelZoom(~, eventdata, axHandle)
        % Mouse wheel zoom function with image filling the entire axes area
        if ~isvalid(axHandle)
            return;
        end
        
        % Get the image object in the axes
        imgObj = findobj(axHandle, 'Type', 'image');
        if isempty(imgObj)
            return;
        end
        
        % Get current axes limits
        xlim_current = get(axHandle, 'XLim');
        ylim_current = get(axHandle, 'YLim');
        
        % Get mouse position in axes coordinates
        mousePoint = get(axHandle, 'CurrentPoint');
        mouseX = mousePoint(1,1);
        mouseY = mousePoint(1,2);
        
        % Zoom factor
        zoomFactor = 1.2;
        
        % Determine zoom direction
        if eventdata.VerticalScrollCount > 0
            % Zoom out
            scaleFactor = zoomFactor;
        else
            % Zoom in
            scaleFactor = 1 / zoomFactor;
        end
        
        % Get image data dimensions
        imgData = get(imgObj, 'CData');
        [imgHeight, imgWidth, ~] = size(imgData);
        
        % Calculate new limits centered on mouse position
        xRange = xlim_current(2) - xlim_current(1);
        yRange = ylim_current(2) - ylim_current(1);
        
        newXRange = xRange * scaleFactor;
        newYRange = yRange * scaleFactor;
        
        % Center the zoom on the mouse position
        xCenter = mouseX;
        yCenter = mouseY;
        
        newXLim = [xCenter - newXRange/2, xCenter + newXRange/2];
        newYLim = [yCenter - newYRange/2, yCenter + newYRange/2];
        
        % Constrain limits to image boundaries to ensure image fills the axes
        % For X limits
        if newXLim(1) < 0.5
            newXLim = [0.5, newXRange + 0.5];
        elseif newXLim(2) > imgWidth + 0.5
            newXLim = [imgWidth + 0.5 - newXRange, imgWidth + 0.5];
        end
        
        % For Y limits
        if newYLim(1) < 0.5
            newYLim = [0.5, newYRange + 0.5];
        elseif newYLim(2) > imgHeight + 0.5
            newYLim = [imgHeight + 0.5 - newYRange, imgHeight + 0.5];
        end
        
        % Ensure we don't zoom out beyond the full image
        if newXRange > imgWidth
            newXLim = [0.5, imgWidth + 0.5];
        end
        if newYRange > imgHeight
            newYLim = [0.5, imgHeight + 0.5];
        end
        
        % Apply new limits
        set(axHandle, 'XLim', newXLim, 'YLim', newYLim);
    end
    
    % Helper function to determine temporal order of images
    function [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(idx1, idx2)
        % Compare timestamps to determine which image is earlier
        timestamp1 = metaData(idx1).timestamp;
        timestamp2 = metaData(idx2).timestamp;
        
        if timestamp1 <= timestamp2
            earlierImg = processedImgs{idx1};
            laterImg = processedImgs{idx2};
            isImg1Earlier = true;
        else
            earlierImg = processedImgs{idx2};
            laterImg = processedImgs{idx1};
            isImg1Earlier = false;
        end
    end
    
    % Callback functions
    function loadFolder(~, ~)
        try
            updateStatus('Selecting folder...');
            
            folder = uigetdir(pwd, 'Select folder containing images');
            if folder == 0
                updateStatus('Ready to load images');
                return;
            end
            
            updateStatus('Loading image sequence...');
            [originalImgs, metaData] = loadImageSequence(folder);
            
            updateStatus('Step 1: Image alignment (SURF features)...');
            [alignedImgs, ~] = preprocessImageSequence(originalImgs);
            
            updateStatus('Step 2: Cropping to common region...');
            croppedImgs = cropToCommonRegion(alignedImgs);
            
            updateStatus('Step 3: Brightness normalization...');
            processedImgs = histogramMatchingV(croppedImgs);
            
            % Generate image names
            imgNames = cell(1, length(metaData));
            for i = 1:length(metaData)
                if isnan(metaData(i).month)
                    imgNames{i} = sprintf('%s (%04d)', metaData(i).name, metaData(i).year);
                else
                    imgNames{i} = sprintf('%s (%04d-%02d)', metaData(i).name, metaData(i).year, metaData(i).month);
                end
            end
            
            % Update interface
            set(img1Popup, 'String', imgNames, 'Value', 1);
            set(img2Popup, 'String', imgNames, 'Value', min(2, length(imgNames)));
            
            selectedImg1 = 1;
            selectedImg2 = min(2, length(imgNames));
            
            displayOriginalImages();
            
            updateStatus(sprintf('Successfully loaded and preprocessed %d images!', length(processedImgs)));
            
        catch ME
            updateStatus('Loading/preprocessing failed');
            fprintf('Error details: %s\n', ME.message);
            errordlg(['Loading failed: ' ME.message], 'Error');
        end
    end
    
    function selectImage1(~, ~)
        selectedImg1 = get(img1Popup, 'Value');
        displayOriginalImages();
        updateAnalysisIfNeeded();
    end
    
    function selectImage2(~, ~)
        selectedImg2 = get(img2Popup, 'Value');
        displayOriginalImages();
        updateAnalysisIfNeeded();
    end
    
    function displayOriginalImages()
        if isempty(processedImgs)
            return;
        end
        
        if selectedImg1 <= length(originalImgs)
            axes(ax1);
            cla(ax1);
            imshow(originalImgs{selectedImg1});
            title(ax1, ['Original A: ' imgNames{selectedImg1}], 'FontSize', 12, 'Interpreter', 'none');
        end
        
        if selectedImg2 <= length(originalImgs)
            axes(ax2);
            cla(ax2);
            imshow(originalImgs{selectedImg2});
            title(ax2, ['Original B: ' imgNames{selectedImg2}], 'FontSize', 12, 'Interpreter', 'none');
        end
        
        if selectedImg1 <= length(processedImgs) && selectedImg2 <= length(processedImgs)
            axes(ax3);
            cla(ax3);
            overlay = 0.5 * processedImgs{selectedImg1} + 0.5 * processedImgs{selectedImg2};
            imshow(overlay);
            title(ax3, 'Preprocessed Overlay', 'FontSize', 12);
        end
    end
    
    function updateThreshold(~, ~)
        currentThreshold = get(thresholdSlider, 'Value');
        set(thresholdText, 'String', sprintf('%.2f', currentThreshold));
        updateAnalysisIfNeeded();
    end
    
    function updateAnalysisIfNeeded()
        % Update analysis based on current active mode
        if isHeatmapOn
            showHeatmap();
        elseif isHighlightOn
            showHighlight();
        elseif isIncreaseOnlyOn
            showIncreaseOnly();
        elseif isDecreaseOnlyOn
            showDecreaseOnly();
        end
    end
    
    function toggleHeatmap(~, ~)
        if get(heatmapToggle, 'Value')
            isHeatmapOn = true;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            set(heatmapToggle, 'String', 'Hide Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            showHeatmap();
        else
            isHeatmapOn = false;
            set(heatmapToggle, 'String', 'Heatmap');
            axes(ax4);
            cla(ax4);
            title(ax4, 'Difference Analysis Results', 'FontSize', 13, 'FontWeight', 'bold');
            updateLamps(false, false);
        end
    end
    
    function toggleHighlight(~, ~)
        if get(highlightToggle, 'Value')
            isHighlightOn = true;
            isHeatmapOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            set(highlightToggle, 'String', 'Hide Highlight');
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Heatmap');
            showHighlight();
        else
            isHighlightOn = false;
            set(highlightToggle, 'String', 'Highlight');
            axes(ax4);
            cla(ax4);
            title(ax4, 'Difference Analysis Results', 'FontSize', 13, 'FontWeight', 'bold');
            updateLamps(false, false);
            currentHighlightImg = [];
        end
    end
    
    function showHeatmap(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images', 'Warning');
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Heatmap');
            isHeatmapOn = false;
            return;
        end
        
        try
            % Set current mode
            isHeatmapOn = true;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            
            updateStatus('Calculating thermal-style heatmap...');
            
            img1 = processedImgs{selectedImg1};
            img2 = processedImgs{selectedImg2};
            
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            diff = abs(gray2 - gray1);
            
            increase = gray2 > gray1;
            decrease = gray2 < gray1;
            significantChange = diff > currentThreshold;
            
            % Additional filtering: Remove very small changes (less than 1.5x threshold)
            strongSignificantChange = diff > (currentThreshold * 1.5);
            significantChange = significantChange & strongSignificantChange;
            
            hasIncrease = any(increase(:) & significantChange(:));
            hasDecrease = any(decrease(:) & significantChange(:));
            
            updateLamps(hasIncrease, hasDecrease);
            
            % Create thermal-style heatmap with proper color gradients
            [h, w, ~] = size(img1);
            heatmapImg = zeros(h, w, 3);
            
            % Set black background for thermal imaging effect
            % Keep background as black (zeros)
            
            % Process increase regions with warm color gradient (Red → Orange → Yellow)
            increaseRegion = increase & significantChange;
            if any(increaseRegion(:))
                intensityMap = zeros(size(gray1));
                intensityMap(increaseRegion) = diff(increaseRegion);
                maxIncreaseIntensity = max(intensityMap(:));
                
                if maxIncreaseIntensity > 0
                    % Normalize intensity from 0 to 1
                    normalizedIntensity = intensityMap / maxIncreaseIntensity;
                    
                    % Create warm color gradient for each pixel
                    for i = 1:h
                        for j = 1:w
                            if increaseRegion(i, j)
                                intensity = normalizedIntensity(i, j);
                                
                                if intensity <= 0.33
                                    % Dark red to red (0 to 0.33)
                                    factor = intensity / 0.33;
                                    heatmapImg(i, j, 1) = 0.3 + 0.7 * factor;  % Red: 0.3 → 1.0
                                    heatmapImg(i, j, 2) = 0;                   % Green: 0
                                    heatmapImg(i, j, 3) = 0;                   % Blue: 0
                                elseif intensity <= 0.66
                                    % Red to orange (0.33 to 0.66)
                                    factor = (intensity - 0.33) / 0.33;
                                    heatmapImg(i, j, 1) = 1.0;                % Red: 1.0
                                    heatmapImg(i, j, 2) = 0.5 * factor;       % Green: 0 → 0.5
                                    heatmapImg(i, j, 3) = 0;                  % Blue: 0
                                else
                                    % Orange to yellow (0.66 to 1.0)
                                    factor = (intensity - 0.66) / 0.34;
                                    heatmapImg(i, j, 1) = 1.0;                % Red: 1.0
                                    heatmapImg(i, j, 2) = 0.5 + 0.5 * factor; % Green: 0.5 → 1.0
                                    heatmapImg(i, j, 3) = 0;                  % Blue: 0
                                end
                            end
                        end
                    end
                end
            end
            
            % Process decrease regions with cool color gradient (Dark Blue → Blue → Light Blue → Cyan)
            decreaseRegion = decrease & significantChange;
            if any(decreaseRegion(:))
                intensityMap = zeros(size(gray1));
                intensityMap(decreaseRegion) = diff(decreaseRegion);
                maxDecreaseIntensity = max(intensityMap(:));
                
                if maxDecreaseIntensity > 0
                    % Normalize intensity from 0 to 1
                    normalizedIntensity = intensityMap / maxDecreaseIntensity;
                    
                    % Create cool color gradient for each pixel
                    for i = 1:h
                        for j = 1:w
                            if decreaseRegion(i, j)
                                intensity = normalizedIntensity(i, j);
                                
                                if intensity <= 0.33
                                    % Dark blue to blue (0 to 0.33)
                                    factor = intensity / 0.33;
                                    heatmapImg(i, j, 1) = 0;                   % Red: 0
                                    heatmapImg(i, j, 2) = 0;                   % Green: 0
                                    heatmapImg(i, j, 3) = 0.3 + 0.7 * factor; % Blue: 0.3 → 1.0
                                elseif intensity <= 0.66
                                    % Blue to light blue (0.33 to 0.66)
                                    factor = (intensity - 0.33) / 0.33;
                                    heatmapImg(i, j, 1) = 0.3 * factor;       % Red: 0 → 0.3
                                    heatmapImg(i, j, 2) = 0.3 * factor;       % Green: 0 → 0.3
                                    heatmapImg(i, j, 3) = 1.0;                % Blue: 1.0
                                else
                                    % Light blue to cyan (0.66 to 1.0)
                                    factor = (intensity - 0.66) / 0.34;
                                    heatmapImg(i, j, 1) = 0.3;                % Red: 0.3
                                    heatmapImg(i, j, 2) = 0.3 + 0.7 * factor; % Green: 0.3 → 1.0
                                    heatmapImg(i, j, 3) = 1.0;                % Blue: 1.0
                                end
                            end
                        end
                    end
                end
            end
            
            axes(ax4);
            cla(ax4);
            imshow(heatmapImg);
            title(ax4, sprintf('Heatmap (Warm=Inc, Cool=Dec, Th: %.2f)', currentThreshold), 'FontSize', 11);
            
            displayStatistics(diff, increase, decrease, significantChange);
            updateStatus('Thermal heatmap completed!');
            
        catch ME
            updateStatus('Heatmap failed');
            errordlg(['Heatmap failed: ' ME.message], 'Error');
            updateLamps(false, false);
        end
    end
    
    function showHighlight(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images', 'Warning');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            isHighlightOn = false;
            return;
        end
        
        try
            % Set current mode
            isHighlightOn = true;
            isHeatmapOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            
            updateStatus('Calculating highlight...');
            
            img1 = processedImgs{selectedImg1};
            img2 = processedImgs{selectedImg2};
            
            % Determine which image is earlier based on metadata timestamps
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            increase = gray_later > gray_earlier;
            decrease = gray_later < gray_earlier;
            significantChange = diff > currentThreshold;
            
            hasIncrease = any(increase(:) & significantChange(:));
            hasDecrease = any(decrease(:) & significantChange(:));
            
            updateLamps(hasIncrease, hasDecrease);
            
            % Create enhanced highlight overlay with pure, bright colors (FILLED regions)
            highlightImg = zeros(size(earlierImg));
            
            % Increase regions - Pure Bright Yellow (Red + Green) - FILLED
            increaseRegion = increase & significantChange;
            if any(increaseRegion(:))
                highlightImg(:,:,1) = highlightImg(:,:,1) + 1.0 * double(increaseRegion);  % Red component
                highlightImg(:,:,2) = highlightImg(:,:,2) + 1.0 * double(increaseRegion);  % Green component for yellow
            end
            
            % Decrease regions - Pure Bright Red - FILLED
            decreaseRegion = decrease & significantChange;
            if any(decreaseRegion(:))
                highlightImg(:,:,1) = highlightImg(:,:,1) + 1.0 * double(decreaseRegion);  % Full red component only
            end
            
            currentHighlightImg = highlightImg;
            
            axes(ax4);
            cla(ax4);
            
            % Use earlier image as base (temporal reference)
            baseImg = earlierImg;
            
            % Enhanced blending for brighter, more vivid highlights
            highlightIntensity = 0.8;  % Increased intensity for brighter highlights
            maskIntensity = max(highlightImg, [], 3);
            
            % Apply stronger contrast for pure color visibility
            resultImg = baseImg .* (1 - highlightIntensity * maskIntensity) + ...
                        highlightIntensity * highlightImg;
            
            % Ensure values are within valid range and apply slight gamma correction for brightness
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;  % Slight gamma correction for brighter appearance
            
            imshow(resultImg);
            
            % Updated title with filled regions
            title(ax4, sprintf('Highlight (Yellow=Inc, Red=Dec, Th: %.2f)', currentThreshold), 'FontSize', 11);
            
            displayStatistics(diff, increase, decrease, significantChange);
            updateStatus('Highlight completed!');
            
        catch ME
            updateStatus('Highlight failed');
            errordlg(['Highlight failed: ' ME.message], 'Error');
        end
    end
    
    function showIncreaseOnly(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images', 'Warning');
            return;
        end
        
        try
            % Set current mode
            isHeatmapOn = false;
            isHighlightOn = false;
            isIncreaseOnlyOn = true;
            isDecreaseOnlyOn = false;
            
            % Reset other toggles
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            
            % Determine temporal order
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            increase = gray_later > gray_earlier;
            significantChange = diff > currentThreshold;
            
            hasIncrease = any(increase(:) & significantChange(:));
            updateLamps(hasIncrease, false);
            
            % Use earlier image as base for increase-only display
            baseImg = earlierImg;
            highlightImg = zeros(size(earlierImg));
            % Change increase to yellow (Red + Green components)
            highlightImg(:,:,1) = 1.0 * double(increase & significantChange);  % Red component for yellow
            highlightImg(:,:,2) = 1.0 * double(increase & significantChange);  % Green component for yellow
            
            axes(ax4);
            cla(ax4);
            
            highlightIntensity = 0.8;  % Increased for brighter display
            yellowMask = max(highlightImg(:,:,1), highlightImg(:,:,2));
            resultImg = baseImg .* (1 - highlightIntensity * yellowMask) + ...
                        highlightIntensity * highlightImg;
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;  % Slight gamma correction for brightness
            
            imshow(resultImg);
            
            % Updated title for yellow color
            title(ax4, sprintf('Increase Only (Yellow, Th: %.2f)', currentThreshold), 'FontSize', 11);
            
            updateStatus('Increase-only completed!');
            
        catch ME
            errordlg(['Show increase failed: ' ME.message], 'Error');
        end
    end
    
    function showDecreaseOnly(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images', 'Warning');
            return;
        end
        
        try
            % Set current mode
            isHeatmapOn = false;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = true;
            
            % Reset other toggles
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            
            % Determine temporal order
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            decrease = gray_later < gray_earlier;
            significantChange = diff > currentThreshold;
            
            hasDecrease = any(decrease(:) & significantChange(:));
            updateLamps(false, hasDecrease);
            
            % Use earlier image as base for decrease-only display
            baseImg = earlierImg;
            highlightImg = zeros(size(earlierImg));
            % Change decrease to red (only Red component)
            highlightImg(:,:,1) = 1.0 * double(decrease & significantChange);  % Pure red for decrease
            
            axes(ax4);
            cla(ax4);
            
            highlightIntensity = 0.8;  % Increased for brighter display
            redMask = highlightImg(:,:,1);
            resultImg = baseImg .* (1 - highlightIntensity * redMask) + ...
                        highlightIntensity * highlightImg;
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;  % Slight gamma correction for brightness
            
            imshow(resultImg);
            
            % Updated title for red color
            title(ax4, sprintf('Decrease Only (Red, Th: %.2f)', currentThreshold), 'FontSize', 11);
            
            updateStatus('Decrease-only completed!');
            
        catch ME
            errordlg(['Show decrease failed: ' ME.message], 'Error');
        end
    end
    
    function updateFlickSpeed(~, ~)
        speed = get(flickSpeedSlider, 'Value');
        set(flickSpeedText, 'String', sprintf('%.1fs', speed));
        
        if ~isempty(flickBtn) && get(flickBtn, 'Value')
            stopFlick();
            startFlick();
        end
    end
    
    function updateLamps(hasIncrease, hasDecrease)
        if hasIncrease
            set(increaseLamp, 'ForegroundColor', [1, 1, 0]);  % Yellow for increase
        else
            set(increaseLamp, 'ForegroundColor', [0.5, 0.5, 0.5]);
        end
        
        if hasDecrease
            set(decreaseLamp, 'ForegroundColor', [1, 0, 0]);  % Red for decrease
        else
            set(decreaseLamp, 'ForegroundColor', [0.5, 0.5, 0.5]);
        end
    end
    
    function toggleFlick(~, ~)
        if get(flickBtn, 'Value')
            startFlick();
        else
            stopFlick();
        end
    end
    
    function startFlick()
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images to enable flick mode', 'Warning');
            set(flickBtn, 'Value', 0);
            return;
        end
        
        speed = get(flickSpeedSlider, 'Value');
        flickTimer = timer('TimerFcn', @flickCallback, 'Period', speed, ...
                          'ExecutionMode', 'fixedRate');
        flickState = true;
        start(flickTimer);
        set(flickBtn, 'String', 'Stop');
    end
    
    function stopFlick()
        if ~isempty(flickTimer) && isvalid(flickTimer)
            stop(flickTimer);
            delete(flickTimer);
            flickTimer = [];
        end
        flickState = false;
        if ~isempty(flickBtn) && isvalid(flickBtn)
            set(flickBtn, 'String', 'Start');
        end
        
        if isvalid(ax5)
            axes(ax5);
            cla(ax5);
            title(ax5, 'Flick Display (Earlier ↔ Changes)', 'FontSize', 13, 'FontWeight', 'bold');
        end
    end
    
    function flickCallback(~, ~)
        try
            if ~isvalid(ax5)
                stopFlick();
                return;
            end
            
            % Get temporal order and calculate differences
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            if flickState
                axes(ax5);
                cla(ax5);
                
                % Show the earlier image (temporal baseline)
                imshow(earlierImg);
                
                if isImg1Earlier
                    title(ax5, ['Earlier: ' imgNames{selectedImg1}], 'FontSize', 12, 'Interpreter', 'none');
                else
                    title(ax5, ['Earlier: ' imgNames{selectedImg2}], 'FontSize', 12, 'Interpreter', 'none');
                end
                flickState = false;
            else
                axes(ax5);
                cla(ax5);
                
                % Calculate differences for boundary detection
                gray_earlier = rgb2gray(earlierImg);
                gray_later = rgb2gray(laterImg);
                diff = abs(gray_later - gray_earlier);
                
                increase = gray_later > gray_earlier;
                decrease = gray_later < gray_earlier;
                significantChange = diff > currentThreshold;
                
                % Create preprocessed overlay
                overlayImg = 0.5 * earlierImg + 0.5 * laterImg;
                
                % Create boundary regions
                increaseRegion = increase & significantChange;
                decreaseRegion = decrease & significantChange;
                
                % Create boundaries with thinner lines
                increaseBoundary = zeros(size(earlierImg));
                decreaseBoundary = zeros(size(earlierImg));
                
                if any(increaseRegion(:))
                    % Yellow boundaries for increase
                    boundary = bwperim(increaseRegion);
                    se = strel('disk', 1); % Thinner line
                    boundary = imdilate(boundary, se);
                    increaseBoundary(:,:,1) = double(boundary); % Red component
                    increaseBoundary(:,:,2) = double(boundary); % Green component for yellow
                end
                
                if any(decreaseRegion(:))
                    % Red boundaries for decrease
                    boundary = bwperim(decreaseRegion);
                    se = strel('disk', 1); % Thinner line
                    boundary = imdilate(boundary, se);
                    decreaseBoundary(:,:,1) = double(boundary); % Red component only
                end
                
                % Combine boundaries
                combinedBoundary = increaseBoundary + decreaseBoundary;
                
                % Apply boundaries to overlay
                boundaryIntensity = 0.9;
                maskIntensity = max(combinedBoundary, [], 3);
                resultImg = overlayImg .* (1 - boundaryIntensity * maskIntensity) + ...
                            boundaryIntensity * combinedBoundary;
                resultImg = min(max(resultImg, 0), 1);
                
                imshow(resultImg);
                
                if isImg1Earlier
                    title(ax5, ['Overlay + Boundaries: ' imgNames{selectedImg1} ' → ' imgNames{selectedImg2}], ...
                          'FontSize', 12, 'Interpreter', 'none');
                else
                    title(ax5, ['Overlay + Boundaries: ' imgNames{selectedImg2} ' → ' imgNames{selectedImg1}], ...
                          'FontSize', 12, 'Interpreter', 'none');
                end
                
                flickState = true;
            end
        catch
            stopFlick();
        end
    end
    
    % Function to save flick animation as GIF
    function saveFlickAsGIF(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images before saving GIF', 'Warning');
            return;
        end
        
        try
            % Get file path from user
            [filename, pathname] = uiputfile('*.gif', 'Save Flick Animation as GIF');
            if filename == 0
                return;
            end
            
            fullpath = fullfile(pathname, filename);
            updateStatus('Creating GIF animation...');
            
            % Parameters for GIF
            delayTime = get(flickSpeedSlider, 'Value'); % Use current flick speed
            numCycles = 3; % Number of complete cycles to include
            
            % Get temporal order and calculate differences
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            % Calculate differences for boundary detection
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            increase = gray_later > gray_earlier;
            decrease = gray_later < gray_earlier;
            significantChange = diff > currentThreshold;
            
            % Create preprocessed overlay
            overlayImg = 0.5 * earlierImg + 0.5 * laterImg;
            
            % Create boundary regions
            increaseRegion = increase & significantChange;
            decreaseRegion = decrease & significantChange;
            
            % Create boundaries with thinner lines
            increaseBoundary = zeros(size(earlierImg));
            decreaseBoundary = zeros(size(earlierImg));
            
            if any(increaseRegion(:))
                % Yellow boundaries for increase
                boundary = bwperim(increaseRegion);
                se = strel('disk', 1); % Thinner line
                boundary = imdilate(boundary, se);
                increaseBoundary(:,:,1) = double(boundary); % Red component
                increaseBoundary(:,:,2) = double(boundary); % Green component for yellow
            end
            
            if any(decreaseRegion(:))
                % Red boundaries for decrease
                boundary = bwperim(decreaseRegion);
                se = strel('disk', 1); % Thinner line
                boundary = imdilate(boundary, se);
                decreaseBoundary(:,:,1) = double(boundary); % Red component only
            end
            
            % Combine boundaries
            combinedBoundary = increaseBoundary + decreaseBoundary;
            
            % Apply boundaries to overlay
            boundaryIntensity = 0.9;
            maskIntensity = max(combinedBoundary, [], 3);
            overlayWithBoundaries = overlayImg .* (1 - boundaryIntensity * maskIntensity) + ...
                                   boundaryIntensity * combinedBoundary;
            overlayWithBoundaries = min(max(overlayWithBoundaries, 0), 1);
            
            % Create frames
            frames = cell(1, 2 * numCycles);
            frameIndex = 1;
            
            for cycle = 1:numCycles
                % Frame 1: Earlier image
                frames{frameIndex} = im2uint8(earlierImg);
                frameIndex = frameIndex + 1;
                
                % Frame 2: Overlay with boundaries
                frames{frameIndex} = im2uint8(overlayWithBoundaries);
                frameIndex = frameIndex + 1;
            end
            
            % Write GIF file
            for i = 1:length(frames)
                [imind, cm] = rgb2ind(frames{i}, 256);
                if i == 1
                    imwrite(imind, cm, fullpath, 'gif', 'Loopcount', inf, 'DelayTime', delayTime);
                else
                    imwrite(imind, cm, fullpath, 'gif', 'WriteMode', 'append', 'DelayTime', delayTime);
                end
            end
            
            updateStatus(sprintf('GIF saved successfully: %s', filename));
            msgbox(['GIF animation saved successfully!' newline 'File: ' filename], 'Success');
            
        catch ME
            updateStatus('GIF save failed');
            errordlg(['GIF save failed: ' ME.message], 'Error');
        end
    end
    
    function saveResults(~, ~)
        if isempty(get(ax4, 'Children'))
            msgbox('No results to save. Please run analysis first.', 'Warning');
            return;
        end
        
        try
            [filename, pathname] = uiputfile({...
                '*.png', 'PNG Image (*.png)';...
                '*.jpg', 'JPEG Image (*.jpg)';...
                '*.fig', 'MATLAB Figure (*.fig)'}, ...
                'Save Analysis Results');
            
            if filename ~= 0
                fullpath = fullfile(pathname, filename);
                [~, ~, ext] = fileparts(filename);
                
                if strcmpi(ext, '.fig')
                    savefig(fig, fullpath);
                else
                    exportgraphics(ax4, fullpath, 'Resolution', 300);
                end
                
                updateStatus(sprintf('Results saved to: %s', filename));
                msgbox('Results saved successfully!', 'Success');
            end
            
        catch ME
            errordlg(['Save failed: ' ME.message], 'Error');
        end
    end
    
    function exportData(~, ~)
        if isempty(processedImgs)
            msgbox('No data to export. Please load images first.', 'Warning');
            return;
        end
        
        try
            [filename, pathname] = uiputfile('*.mat', 'Export Analysis Data');
            if filename ~= 0
                fullpath = fullfile(pathname, filename);
                
                exportData = struct();
                exportData.originalImgs = originalImgs;
                exportData.processedImgs = processedImgs;
                exportData.imgNames = imgNames;
                exportData.metaData = metaData;
                exportData.currentThreshold = currentThreshold;
                exportData.analysisDateTime = datetime('now');
                
                save(fullpath, 'exportData');
                
                updateStatus(sprintf('Data exported to: %s', filename));
                msgbox('Data exported successfully!', 'Success');
            end
            
        catch ME
            errordlg(['Export failed: ' ME.message], 'Error');
        end
    end
    
    function displayStatistics(diff, increase, decrease, significantChange)
        totalPixels = numel(diff);
        changedPixels = sum(significantChange(:));
        increasedPixels = sum(increase(:) & significantChange(:));
        decreasedPixels = sum(decrease(:) & significantChange(:));
        
        % Determine temporal order for statistics display
        [~, ~, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
        
        fprintf('=== Temporal Change Statistics ===\n');
        if isImg1Earlier
            fprintf('Temporal Analysis: %s → %s\n', imgNames{selectedImg1}, imgNames{selectedImg2});
        else
            fprintf('Temporal Analysis: %s → %s\n', imgNames{selectedImg2}, imgNames{selectedImg1});
        end
        fprintf('Total pixels: %d\n', totalPixels);
        fprintf('Changed pixels: %d (%.2f%%)\n', changedPixels, (changedPixels/totalPixels)*100);
        fprintf('Increased pixels: %d (%.2f%%)\n', increasedPixels, (increasedPixels/totalPixels)*100);
        fprintf('Decreased pixels: %d (%.2f%%)\n', decreasedPixels, (decreasedPixels/totalPixels)*100);
        fprintf('Threshold: %.2f\n', currentThreshold);
        fprintf('===================================\n');
    end
    
    function resetDisplay(~, ~)
        try
            % Stop any running timers first
            stopFlick();
            
            % Clear all axes
            if isvalid(ax1), cla(ax1); end
            if isvalid(ax2), cla(ax2); end
            if isvalid(ax3), cla(ax3); end
            if isvalid(ax4), cla(ax4); end
            if isvalid(ax5), cla(ax5); end
            
            % Reset titles
            if isvalid(ax1), title(ax1, 'Original Image A', 'FontSize', 13, 'FontWeight', 'bold'); end
            if isvalid(ax2), title(ax2, 'Original Image B', 'FontSize', 13, 'FontWeight', 'bold'); end
            if isvalid(ax3), title(ax3, 'Preprocessed Overlay', 'FontSize', 13, 'FontWeight', 'bold'); end
            if isvalid(ax4), title(ax4, 'Difference Analysis Results', 'FontSize', 13, 'FontWeight', 'bold'); end
            if isvalid(ax5), title(ax5, 'Flick Display (Earlier ↔ Changes)', 'FontSize', 13, 'FontWeight', 'bold'); end
            
            % Reset variables
            currentHighlightImg = [];
            isHeatmapOn = false;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            
            % Reset UI controls
            if isvalid(heatmapToggle)
                set(heatmapToggle, 'Value', 0);
                set(heatmapToggle, 'String', 'Heatmap');
            end
            if isvalid(highlightToggle)
                set(highlightToggle, 'Value', 0);
                set(highlightToggle, 'String', 'Highlight');
            end
            
            updateLamps(false, false);
            updateStatus('Display reset completed');
            
        catch ME
            fprintf('Reset error: %s\n', ME.message);
        end
    end
    
    function updateStatus(message)
        if isvalid(statusText)
            set(statusText, 'String', ['Status: ' message]);
            drawnow;
        end
    end
    
    function closeFigure(~, ~)
        try
            % Clean up timers
            stopFlick();
            
            % Delete figure
            if isvalid(fig)
                delete(fig);
            end
        catch
            % Force close if there's an error
            if isvalid(fig)
                delete(fig);
            end
        end
    end
    
end
