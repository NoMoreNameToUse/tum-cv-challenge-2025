function AdvancedDifferenceTool
    % Advanced Difference Analysis Tool - Simplified Version (Remove Rate Only & Rate Threshold Controls)
    
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
    isComprehensiveMode = false; % Comprehensive mode combining size + rate
    
    % UI control handles
    statusText = [];
    img1Popup = [];
    img2Popup = [];
    thresholdSlider = [];
    thresholdText = [];
    comprehensiveToggle = []; % Toggle for comprehensive mode
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
    
    % Create main interface - simplified layout
    fig = figure('Name', 'Advanced Difference Analysis Tool - Simplified Version', ...
                 'Position', [50, 50, 1600, 900], ...
                 'MenuBar', 'none', 'ToolBar', 'none', ...
                 'Color', [0.96, 0.96, 0.96], ...
                 'CloseRequestFcn', @closeFigure);
    
    % Create interface layout
    createInterface();
    
    function createInterface()
        % Control panel - adjusted height for simplified controls
        controlPanel = uipanel('Parent', fig, 'Title', 'Control Panel', ...
                              'Position', [0.01, 0.72, 0.98, 0.27], ...
                              'FontSize', 16, 'FontWeight', 'bold', ...
                              'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Image display panel
        imagePanel = uipanel('Parent', fig, 'Title', 'Image Display Area', ...
                            'Position', [0.01, 0.01, 0.98, 0.70], ...
                            'FontSize', 16, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.98, 0.98, 0.98]);
        
        createSimplifiedControlPanel(controlPanel);
        createImagePanel(imagePanel);
    end
    
    function createSimplifiedControlPanel(controlPanel)
        % Row 1: File Operations (Top row)
        
        % Load folder button
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Load Folder', 'Units', 'normalized', ...
                  'Position', [0.02, 0.8, 0.12, 0.18], ...
                  'FontSize', 12, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.2, 0.5, 0.8], 'ForegroundColor', 'white', ...
                  'Callback', @loadFolder);
        
        % Status text
        statusText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                              'String', 'Status: Ready to load images', ...
                              'Units', 'normalized', 'Position', [0.15, 0.8, 0.4, 0.18], ...
                              'FontSize', 11, 'HorizontalAlignment', 'left', ...
                              'BackgroundColor', [0.94, 0.94, 0.94], ...
                              'ForegroundColor', [0, 0.4, 0]);
        
        % Tools section
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Tools:', 'Units', 'normalized', ...
                  'Position', [0.80, 0.85, 0.06, 0.13], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Reset', 'Units', 'normalized', ...
                  'Position', [0.78, 0.8, 0.05, 0.15], ...
                  'FontSize', 9, 'Callback', @resetDisplay);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Save', 'Units', 'normalized', ...
                  'Position', [0.84, 0.8, 0.05, 0.15], ...
                  'FontSize', 9, 'Callback', @saveResults);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Save GIF', 'Units', 'normalized', ...
                  'Position', [0.90, 0.8, 0.05, 0.15], ...
                  'FontSize', 9, 'FontWeight', 'bold', ...
                  'BackgroundColor', [0.8, 0.2, 0.2], 'ForegroundColor', 'white', ...
                  'Callback', @saveFlickAsGIF);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Export', 'Units', 'normalized', ...
                  'Position', [0.96, 0.8, 0.03, 0.15], ...
                  'FontSize', 9, 'Callback', @exportData);
        
        % Row 2: Image Selection and Basic Parameters
        
        % Image selection
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image Selection:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.6, 0.12, 0.12], ...
                  'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image A:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.45, 0.06, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        img1Popup = uicontrol('Parent', controlPanel, 'Style', 'popupmenu', ...
                             'String', {'Load images first'}, 'Units', 'normalized', ...
                             'Position', [0.08, 0.45, 0.18, 0.12], ...
                             'FontSize', 9, 'Callback', @selectImage1);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Image B:', 'Units', 'normalized', ...
                  'Position', [0.28, 0.45, 0.06, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        img2Popup = uicontrol('Parent', controlPanel, 'Style', 'popupmenu', ...
                             'String', {'Load images first'}, 'Units', 'normalized', ...
                             'Position', [0.34, 0.45, 0.18, 0.12], ...
                             'FontSize', 9, 'Callback', @selectImage2);
        
        % Basic Threshold control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Threshold:', 'Units', 'normalized', ...
                  'Position', [0.54, 0.6, 0.12, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        thresholdSlider = uicontrol('Parent', controlPanel, 'Style', 'slider', ...
                                   'Min', 0, 'Max', 1, 'Value', 0.1, ...
                                   'Units', 'normalized', 'Position', [0.54, 0.45, 0.12, 0.12], ...
                                   'Callback', @updateThreshold);
        
        thresholdText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                 'String', '0.10', 'Units', 'normalized', ...
                                 'Position', [0.67, 0.45, 0.04, 0.12], ...
                                 'FontSize', 10, 'HorizontalAlignment', 'center', ...
                                 'BackgroundColor', [1, 1, 1]);
        
        % Change indicators
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Indicators:', 'Units', 'normalized', ...
                  'Position', [0.73, 0.6, 0.10, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        increaseLamp = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                'String', '●', 'Units', 'normalized', ...
                                'Position', [0.73, 0.47, 0.05, 0.12], ...
                                'FontSize', 18, 'HorizontalAlignment', 'center', ...
                                'ForegroundColor', [0.5, 0.5, 0.5], 'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Inc', 'Units', 'normalized', ...
                  'Position', [0.77, 0.45, 0.04, 0.12], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        decreaseLamp = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                'String', '●', 'Units', 'normalized', ...
                                'Position', [0.73, 0.32, 0.05, 0.12], ...
                                'FontSize', 18, 'HorizontalAlignment', 'center', ...
                                'ForegroundColor', [0.5, 0.5, 0.5], 'BackgroundColor', [0.94, 0.94, 0.94]);
        
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Dec', 'Units', 'normalized', ...
                  'Position', [0.77, 0.30, 0.04, 0.12], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Row 3: Analysis Functions (Bottom row)
        
        % Analysis functions
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Analysis Functions:', 'Units', 'normalized', ...
                  'Position', [0.02, 0.05, 0.15, 0.12], ...
                  'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Comprehensive Heatmap toggle - Keep original comprehensive functionality
        comprehensiveToggle = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                                       'String', 'Superimposed Heatmap', 'Units', 'normalized', ...
                                       'Position', [0.18, 0.02, 0.10, 0.18], ...
                                       'FontSize', 9, 'FontWeight', 'bold', ...
                                       'BackgroundColor', [0.8, 0.9, 0.8], ...
                                       'ForegroundColor', [0, 0.6, 0], ...
                                       'Callback', @toggleComprehensiveMap);
        
        heatmapToggle = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                                 'String', 'Basic Heatmap', 'Units', 'normalized', ...
                                 'Position', [0.29, 0.02, 0.08, 0.18], ...
                                 'FontSize', 9, 'FontWeight', 'bold', ...
                                 'BackgroundColor', [0.9, 0.9, 0.9], ...
                                 'Callback', @toggleHeatmap);
        
        highlightToggle = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                                   'String', 'Highlight', 'Units', 'normalized', ...
                                   'Position', [0.38, 0.02, 0.08, 0.18], ...
                                   'FontSize', 10, 'FontWeight', 'bold', ...
                                   'BackgroundColor', [0.9, 0.9, 0.9], ...
                                   'Callback', @toggleHighlight);
        
        % Specific analysis buttons
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Increase', 'Units', 'normalized', ...
                  'Position', [0.47, 0.02, 0.06, 0.18], ...
                  'FontSize', 9, 'Callback', @showIncreaseOnly);
        
        uicontrol('Parent', controlPanel, 'Style', 'pushbutton', ...
                  'String', 'Decrease', 'Units', 'normalized', ...
                  'Position', [0.54, 0.02, 0.06, 0.18], ...
                  'FontSize', 9, 'Callback', @showDecreaseOnly);
        
        % Flick control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Flick:', 'Units', 'normalized', ...
                  'Position', [0.62, 0.05, 0.05, 0.12], ...
                  'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        flickBtn = uicontrol('Parent', controlPanel, 'Style', 'togglebutton', ...
                            'String', 'Start', 'Units', 'normalized', ...
                            'Position', [0.68, 0.02, 0.06, 0.18], ...
                            'FontSize', 10, 'FontWeight', 'bold', ...
                            'BackgroundColor', [0.9, 0.9, 0.9], ...
                            'Callback', @toggleFlick);
        
        % Flick speed control
        uicontrol('Parent', controlPanel, 'Style', 'text', ...
                  'String', 'Speed:', 'Units', 'normalized', ...
                  'Position', [0.75, 0.12, 0.05, 0.08], ...
                  'FontSize', 9, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0.94, 0.94, 0.94]);
        
        flickSpeedSlider = uicontrol('Parent', controlPanel, 'Style', 'slider', ...
                                    'Min', 0.1, 'Max', 1, 'Value', 0.5, ...
                                    'Units', 'normalized', 'Position', [0.75, 0.02, 0.08, 0.08], ...
                                    'Callback', @updateFlickSpeed);
        
        flickSpeedText = uicontrol('Parent', controlPanel, 'Style', 'text', ...
                                  'String', '0.5s', 'Units', 'normalized', ...
                                  'Position', [0.84, 0.02, 0.03, 0.08], ...
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
        
        % Constrain limits to image boundaries
        if newXLim(1) < 0.5
            newXLim = [0.5, newXRange + 0.5];
        elseif newXLim(2) > imgWidth + 0.5
            newXLim = [imgWidth + 0.5 - newXRange, imgWidth + 0.5];
        end
        
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
    
    % Function to calculate time-weighted change rate analysis between two time points
    function [changeRateMap, hasIncrease, hasDecrease] = calculateChangeRateAnalysis(startIdx, endIdx)
        % Get all images between start and end indices (inclusive)
        timestamps = [metaData.timestamp];
        startTime = timestamps(startIdx);
        endTime = timestamps(endIdx);
        
        % Find all indices in the time range and sort them
        timeRangeIndices = find(timestamps >= startTime & timestamps <= endTime);
        [sortedTimestamps, sortOrder] = sort(timestamps(timeRangeIndices));
        timeRangeIndices = timeRangeIndices(sortOrder);
        
        updateStatus(sprintf('Analyzing time-weighted change rate across %d images...', length(timeRangeIndices)));
        
        if length(timeRangeIndices) < 2
            % Not enough images for rate analysis
            changeRateMap = zeros(size(rgb2gray(processedImgs{startIdx})));
            hasIncrease = false;
            hasDecrease = false;
            return;
        end
        
        % Initialize weighted accumulation maps
        [h, w] = size(rgb2gray(processedImgs{timeRangeIndices(1)}));
        increaseRateMap = zeros(h, w);
        decreaseRateMap = zeros(h, w);
        totalTimeSpan = sortedTimestamps(end) - sortedTimestamps(1);
        
        if totalTimeSpan == 0
            totalTimeSpan = 1; % Prevent division by zero
        end
        
        % Use a fixed change rate threshold based on the basic threshold
        changeRateThreshold = currentThreshold * 3; % 3x the basic threshold for rate filtering
        
        % Calculate time-weighted change rates between consecutive images
        for i = 1:(length(timeRangeIndices) - 1)
            idx1 = timeRangeIndices(i);
            idx2 = timeRangeIndices(i + 1);
            
            img1 = processedImgs{idx1};
            img2 = processedImgs{idx2};
            
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            
            diff = abs(gray2 - gray1);
            increase = gray2 > gray1;
            decrease = gray2 < gray1;
            significantChange = diff > currentThreshold;
            
            % Calculate time information for this interval
            intervalStartTime = sortedTimestamps(i);
            intervalEndTime = sortedTimestamps(i + 1);
            intervalDuration = intervalEndTime - intervalStartTime;
            if intervalDuration == 0
                intervalDuration = 1; % Prevent division by zero
            end
            
            % Calculate temporal position: how early this change occurs
            % Earlier changes get higher weights (faster change rate)
            normalizedStartTime = (intervalStartTime - sortedTimestamps(1)) / totalTimeSpan;
            
            % Time weight: earlier changes (smaller normalizedStartTime) get higher weights
            % Using exponential decay: earlier = higher weight
            timeWeight = exp(-3 * normalizedStartTime); % Exponential decay factor
            
            % Calculate change magnitude weighted by time
            changeMagnitude = diff .* double(significantChange);
            
            % Change rate = (change magnitude × time weight) / interval duration
            intervalChangeRate = (changeMagnitude * timeWeight) / intervalDuration;
            
            % Accumulate weighted change rates
            increaseRegion = increase & significantChange;
            decreaseRegion = decrease & significantChange;
            
            increaseRateMap = increaseRateMap + intervalChangeRate .* double(increaseRegion);
            decreaseRateMap = decreaseRateMap + intervalChangeRate .* double(decreaseRegion);
        end
        
        % Normalize change rates to [0, 1] range for consistent thresholding
        maxIncreaseRate = max(increaseRateMap(:));
        maxDecreaseRate = max(decreaseRateMap(:));
        
        if maxIncreaseRate > 0
            increaseRateMap = increaseRateMap / maxIncreaseRate;
        end
        if maxDecreaseRate > 0
            decreaseRateMap = decreaseRateMap / maxDecreaseRate;
        end
        
        % Apply change rate threshold to filter fast vs slow changes
        fastIncreaseRegions = increaseRateMap > (changeRateThreshold / currentThreshold / 10); % Adjusted for fixed threshold
        fastDecreaseRegions = decreaseRateMap > (changeRateThreshold / currentThreshold / 10);
        
        % Determine if there are significant fast changes
        hasIncrease = any(fastIncreaseRegions(:));
        hasDecrease = any(fastDecreaseRegions(:));
        
        % Create final output maps showing only fast-changing regions
        finalIncreaseRate = increaseRateMap .* double(fastIncreaseRegions);
        finalDecreaseRate = decreaseRateMap .* double(fastDecreaseRegions);
        
        changeRateMap = struct();
        changeRateMap.increaseRate = finalIncreaseRate;
        changeRateMap.decreaseRate = finalDecreaseRate;
        changeRateMap.totalRate = finalIncreaseRate + finalDecreaseRate;
        changeRateMap.numIntervals = length(timeRangeIndices) - 1;
        changeRateMap.totalTimeSpan = totalTimeSpan;
        
        updateStatus(sprintf('Time-weighted change rate analysis completed for %d intervals (span: %.0f years)', ...
                    changeRateMap.numIntervals, totalTimeSpan/100));
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
        if isComprehensiveMode
            showComprehensiveMap();
        elseif isHeatmapOn
            showHeatmap();
        elseif isHighlightOn
            showHighlight();
        elseif isIncreaseOnlyOn
            showIncreaseOnly();
        elseif isDecreaseOnlyOn
            showDecreaseOnly();
        end
    end
    
    % Toggle for comprehensive map - KEEP ORIGINAL FUNCTIONALITY
    function toggleComprehensiveMap(~, ~)
        if get(comprehensiveToggle, 'Value')
            isComprehensiveMode = true;
            isHeatmapOn = false;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            set(comprehensiveToggle, 'String', 'Hide Superimposed');
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Basic Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            showComprehensiveMap();
        else
            isComprehensiveMode = false;
            set(comprehensiveToggle, 'String', 'Superimposed Map');
            axes(ax4);
            cla(ax4);
            title(ax4, 'Difference Analysis Results', 'FontSize', 13, 'FontWeight', 'bold');
            updateLamps(false, false);
        end
    end
    
    function toggleHeatmap(~, ~)
        if get(heatmapToggle, 'Value')
            isHeatmapOn = true;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            isComprehensiveMode = false;
            set(heatmapToggle, 'String', 'Hide Basic Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            set(comprehensiveToggle, 'Value', 0);
            set(comprehensiveToggle, 'String', 'Superimposed Map');
            showHeatmap();
        else
            isHeatmapOn = false;
            set(heatmapToggle, 'String', 'Basic Heatmap');
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
            isComprehensiveMode = false;
            set(highlightToggle, 'String', 'Hide Highlight');
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Basic Heatmap');
            set(comprehensiveToggle, 'Value', 0);
            set(comprehensiveToggle, 'String', 'superimposed Map');
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
    
    % KEEP ORIGINAL comprehensive map functionality combining change magnitude and rate
    function showComprehensiveMap(~, ~)
        if isempty(processedImgs) || selectedImg1 == selectedImg2
            msgbox('Please load images and select two different images', 'Warning');
            set(comprehensiveToggle, 'Value', 0);
            set(comprehensiveToggle, 'String', 'superimposed Map');
            isComprehensiveMode = false;
            return;
        end
        
        try
            % Set current mode
            isComprehensiveMode = true;
            isHeatmapOn = false;
            isHighlightOn = false;
            isIncreaseOnlyOn = false;
            isDecreaseOnlyOn = false;
            
            updateStatus('Calculating superimposed map...');
            
            % 1. Calculate basic change magnitude
            img1 = processedImgs{selectedImg1};
            img2 = processedImgs{selectedImg2};
            
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            diff = abs(gray2 - gray1);
            
            increase = gray2 > gray1;
            decrease = gray2 < gray1;
            significantChange = diff > currentThreshold;
            
            % 2. Calculate change rate analysis
            [rateData, hasIncrease, hasDecrease] = calculateChangeRateAnalysis(selectedImg1, selectedImg2);
            
            updateLamps(hasIncrease, hasDecrease);
            
            % 3. Create comprehensive color map
            [h, w, ~] = size(img1);
            comprehensiveImg = zeros(h, w, 3);
            
            % Normalize magnitude for intensity scaling
            maxDiff = max(diff(:));
            if maxDiff > 0
                normalizedMagnitude = diff / maxDiff;
            else
                normalizedMagnitude = zeros(size(diff));
            end
            
            % Get rate maps
            increaseRate = rateData.increaseRate;
            decreaseRate = rateData.decreaseRate;
            
            % Color encoding scheme:
            % - Hue: Direction and Speed combined
            % - Saturation: Change magnitude 
            % - Value: Overall intensity
            
            for i = 1:h
                for j = 1:w
                    if significantChange(i, j)
                        magnitude = normalizedMagnitude(i, j);
                        
                        if increase(i, j)
                            % Increase regions: Red to Orange spectrum
                            rate = increaseRate(i, j);
                            
                            if rate > 0.7  % Very fast increase - Pure Red
                                comprehensiveImg(i, j, 1) = 1.0 * magnitude;
                                comprehensiveImg(i, j, 2) = 0.0;
                                comprehensiveImg(i, j, 3) = 0.0;
                            elseif rate > 0.4  % Medium fast increase - Red-Orange
                                comprehensiveImg(i, j, 1) = 1.0 * magnitude;
                                comprehensiveImg(i, j, 2) = 0.3 * magnitude;
                                comprehensiveImg(i, j, 3) = 0.0;
                            elseif rate > 0.1  % Slow increase - Orange
                                comprehensiveImg(i, j, 1) = 1.0 * magnitude;
                                comprehensiveImg(i, j, 2) = 0.6 * magnitude;
                                comprehensiveImg(i, j, 3) = 0.0;
                            else  % Very slow increase - Yellow-Orange
                                comprehensiveImg(i, j, 1) = 1.0 * magnitude;
                                comprehensiveImg(i, j, 2) = 0.8 * magnitude;
                                comprehensiveImg(i, j, 3) = 0.2 * magnitude;
                            end
                            
                        elseif decrease(i, j)
                            % Decrease regions: Blue to Cyan spectrum
                            rate = decreaseRate(i, j);
                            
                            if rate > 0.7  % Very fast decrease - Pure Blue
                                comprehensiveImg(i, j, 1) = 0.0;
                                comprehensiveImg(i, j, 2) = 0.0;
                                comprehensiveImg(i, j, 3) = 1.0 * magnitude;
                            elseif rate > 0.4  % Medium fast decrease - Blue-Cyan
                                comprehensiveImg(i, j, 1) = 0.0;
                                comprehensiveImg(i, j, 2) = 0.3 * magnitude;
                                comprehensiveImg(i, j, 3) = 1.0 * magnitude;
                            elseif rate > 0.1  % Slow decrease - Cyan
                                comprehensiveImg(i, j, 1) = 0.0;
                                comprehensiveImg(i, j, 2) = 0.6 * magnitude;
                                comprehensiveImg(i, j, 3) = 1.0 * magnitude;
                            else  % Very slow decrease - Light Cyan
                                comprehensiveImg(i, j, 1) = 0.2 * magnitude;
                                comprehensiveImg(i, j, 2) = 0.8 * magnitude;
                                comprehensiveImg(i, j, 3) = 1.0 * magnitude;
                            end
                        end
                    end
                end
            end
            
            % 4. Display the comprehensive map
            axes(ax4);
            cla(ax4);
            imshow(comprehensiveImg);
            title(ax4, sprintf('Superimposed Heatmap (Th: %.2f)', currentThreshold), 'FontSize', 10);
            
            % 5. Add color legend
            addComprehensiveColorLegend();
            
            % 6. Display statistics
            displayComprehensiveStatistics(diff, increase, decrease, significantChange, rateData);
            updateStatus('superimposed map completed! Check color legend for interpretation.');
            
        catch ME
            updateStatus('superimposed map failed');
            errordlg(['superimposed map failed: ' ME.message], 'Error');
            updateLamps(false, false);
        end
    end
    
    % Add color legend for comprehensive map
    function addComprehensiveColorLegend()
        % Create a small legend in the corner of the axes
        hold(ax4, 'on');
        
        % Get current axes limits
        xlim_curr = get(ax4, 'XLim');
        ylim_curr = get(ax4, 'YLim');
        
        % Legend position (top-right corner)
        legendWidth = (xlim_curr(2) - xlim_curr(1)) * 0.15;
        legendHeight = (ylim_curr(2) - ylim_curr(1)) * 0.25;
        legendX = xlim_curr(2) - legendWidth - 10;
        legendY = ylim_curr(1) + 10;
        
        % Background rectangle for legend
        rectangle('Position', [legendX-5, legendY-5, legendWidth+10, legendHeight+10], ...
                 'FaceColor', [0, 0, 0, 0.8], 'EdgeColor', 'white', 'LineWidth', 1);
        
        % Color samples and labels
        sampleSize = legendHeight / 8;
        
        % Fast increase - Red
        rectangle('Position', [legendX, legendY, sampleSize, sampleSize], ...
                 'FaceColor', [1, 0, 0], 'EdgeColor', 'none');
        text(legendX + sampleSize + 2, legendY + sampleSize/2, 'Fast Inc', ...
             'Color', 'white', 'FontSize', 7, 'VerticalAlignment', 'middle');
        
        % Slow increase - Orange
        rectangle('Position', [legendX, legendY + sampleSize*1.5, sampleSize, sampleSize], ...
                 'FaceColor', [1, 0.6, 0], 'EdgeColor', 'none');
        text(legendX + sampleSize + 2, legendY + sampleSize*2, 'Slow Inc', ...
             'Color', 'white', 'FontSize', 7, 'VerticalAlignment', 'middle');
        
        % Fast decrease - Blue
        rectangle('Position', [legendX, legendY + sampleSize*3, sampleSize, sampleSize], ...
                 'FaceColor', [0, 0, 1], 'EdgeColor', 'none');
        text(legendX + sampleSize + 2, legendY + sampleSize*3.5, 'Fast Dec', ...
             'Color', 'white', 'FontSize', 7, 'VerticalAlignment', 'middle');
        
        % Slow decrease - Cyan
        rectangle('Position', [legendX, legendY + sampleSize*4.5, sampleSize, sampleSize], ...
                 'FaceColor', [0, 0.6, 1], 'EdgeColor', 'none');
        text(legendX + sampleSize + 2, legendY + sampleSize*5, 'Slow Dec', ...
             'Color', 'white', 'FontSize', 7, 'VerticalAlignment', 'middle');
        
        % Brightness note
        text(legendX, legendY + sampleSize*6.5, 'Brightness =', ...
             'Color', 'white', 'FontSize', 6, 'FontWeight', 'bold');
        text(legendX, legendY + sampleSize*7.2, 'Change Size', ...
             'Color', 'white', 'FontSize', 6, 'FontWeight', 'bold');
        
        hold(ax4, 'off');
    end
    
    % Display comprehensive statistics
    % 只需要修改 displayComprehensiveStatistics 函数
% Display comprehensive statistics
function displayComprehensiveStatistics(diff, increase, decrease, significantChange, rateData)
    totalPixels = numel(diff);
    changedPixels = sum(significantChange(:));
    increasedPixels = sum(increase(:) & significantChange(:));
    decreasedPixels = sum(decrease(:) & significantChange(:));
    
    % Fast vs slow changes
    fastIncreasePixels = sum(rateData.increaseRate(:) > 0.4);
    slowIncreasePixels = sum(rateData.increaseRate(:) > 0 & rateData.increaseRate(:) <= 0.4);
    fastDecreasePixels = sum(rateData.decreaseRate(:) > 0.4);
    slowDecreasePixels = sum(rateData.decreaseRate(:) > 0 & rateData.decreaseRate(:) <= 0.4);
    
    % Determine temporal order for statistics display
    [~, ~, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
    
    % 计算实际对比的图片数量
    timestamps = [metaData.timestamp];
    startTime = timestamps(selectedImg1);
    endTime = timestamps(selectedImg2);
    timeRangeIndices = find(timestamps >= min(startTime, endTime) & timestamps <= max(startTime, endTime));
    numComparedImages = length(timeRangeIndices);
    
    fprintf('=== Comprehensive Analysis Statistics ===\n');
    if isImg1Earlier
        fprintf('Temporal Range: %s → %s\n', imgNames{selectedImg1}, imgNames{selectedImg2});
    else
        fprintf('Temporal Range: %s → %s\n', imgNames{selectedImg2}, imgNames{selectedImg1});
    end
    fprintf('Images compared: %d\n', numComparedImages);  % 新增这一行
    fprintf('Total pixels: %d\n', totalPixels);
    fprintf('Changed pixels: %d (%.2f%%)\n', changedPixels, (changedPixels/totalPixels)*100);
    fprintf('--- Increases ---\n');
    fprintf('  Fast increases: %d (%.2f%%) - RED\n', fastIncreasePixels, (fastIncreasePixels/totalPixels)*100);
    fprintf('  Slow increases: %d (%.2f%%) - ORANGE\n', slowIncreasePixels, (slowIncreasePixels/totalPixels)*100);
    fprintf('--- Decreases ---\n');
    fprintf('  Fast decreases: %d (%.2f%%) - BLUE\n', fastDecreasePixels, (fastDecreasePixels/totalPixels)*100);
    fprintf('  Slow decreases: %d (%.2f%%) - CYAN\n', slowDecreasePixels, (slowDecreasePixels/totalPixels)*100);
    fprintf('Magnitude threshold: %.2f\n', currentThreshold);
    fprintf('Color brightness reflects change magnitude\n');
    fprintf('======================================\n');
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
            isComprehensiveMode = false;
            
            updateStatus('Calculating thermal-style heatmap...');
            
            img1 = processedImgs{selectedImg1};
            img2 = processedImgs{selectedImg2};
            
            gray1 = rgb2gray(img1);
            gray2 = rgb2gray(img2);
            diff = abs(gray2 - gray1);
            
            increase = gray2 > gray1;
            decrease = gray2 < gray1;
            significantChange = diff > currentThreshold;
            
            % Additional filtering: Remove very small changes
            strongSignificantChange = diff > (currentThreshold * 1.5);
            significantChange = significantChange & strongSignificantChange;
            
            hasIncrease = any(increase(:) & significantChange(:));
            hasDecrease = any(decrease(:) & significantChange(:));
            
            updateLamps(hasIncrease, hasDecrease);
            
            % Create thermal-style heatmap with proper color gradients
            [h, w, ~] = size(img1);
            heatmapImg = zeros(h, w, 3);
            
            % Process increase regions with warm color gradient
            increaseRegion = increase & significantChange;
            if any(increaseRegion(:))
                intensityMap = zeros(size(gray1));
                intensityMap(increaseRegion) = diff(increaseRegion);
                maxIncreaseIntensity = max(intensityMap(:));
                
                if maxIncreaseIntensity > 0
                    normalizedIntensity = intensityMap / maxIncreaseIntensity;
                    
                    for i = 1:h
                        for j = 1:w
                            if increaseRegion(i, j)
                                intensity = normalizedIntensity(i, j);
                                
                                if intensity <= 0.33
                                    factor = intensity / 0.33;
                                    heatmapImg(i, j, 1) = 0.3 + 0.7 * factor;
                                    heatmapImg(i, j, 2) = 0;
                                    heatmapImg(i, j, 3) = 0;
                                elseif intensity <= 0.66
                                    factor = (intensity - 0.33) / 0.33;
                                    heatmapImg(i, j, 1) = 1.0;
                                    heatmapImg(i, j, 2) = 0.5 * factor;
                                    heatmapImg(i, j, 3) = 0;
                                else
                                    factor = (intensity - 0.66) / 0.34;
                                    heatmapImg(i, j, 1) = 1.0;
                                    heatmapImg(i, j, 2) = 0.5 + 0.5 * factor;
                                    heatmapImg(i, j, 3) = 0;
                                end
                            end
                        end
                    end
                end
            end
            
            % Process decrease regions with cool color gradient
            decreaseRegion = decrease & significantChange;
            if any(decreaseRegion(:))
                intensityMap = zeros(size(gray1));
                intensityMap(decreaseRegion) = diff(decreaseRegion);
                maxDecreaseIntensity = max(intensityMap(:));
                
                if maxDecreaseIntensity > 0
                    normalizedIntensity = intensityMap / maxDecreaseIntensity;
                    
                    for i = 1:h
                        for j = 1:w
                            if decreaseRegion(i, j)
                                intensity = normalizedIntensity(i, j);
                                
                                if intensity <= 0.33
                                    factor = intensity / 0.33;
                                    heatmapImg(i, j, 1) = 0;
                                    heatmapImg(i, j, 2) = 0;
                                    heatmapImg(i, j, 3) = 0.3 + 0.7 * factor;
                                elseif intensity <= 0.66
                                    factor = (intensity - 0.33) / 0.33;
                                    heatmapImg(i, j, 1) = 0.3 * factor;
                                    heatmapImg(i, j, 2) = 0.3 * factor;
                                    heatmapImg(i, j, 3) = 1.0;
                                else
                                    factor = (intensity - 0.66) / 0.34;
                                    heatmapImg(i, j, 1) = 0.3;
                                    heatmapImg(i, j, 2) = 0.3 + 0.7 * factor;
                                    heatmapImg(i, j, 3) = 1.0;
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
            
            displayBasicStatistics(diff, increase, decrease, significantChange);
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
            isComprehensiveMode = false;
            
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
            
            % Create enhanced highlight overlay with pure, bright colors
            highlightImg = zeros(size(earlierImg));
            
            % Increase regions - Pure Bright Yellow
            increaseRegion = increase & significantChange;
            if any(increaseRegion(:))
                highlightImg(:,:,1) = highlightImg(:,:,1) + 1.0 * double(increaseRegion);
                highlightImg(:,:,2) = highlightImg(:,:,2) + 1.0 * double(increaseRegion);
            end
            
            % Decrease regions - Pure Bright Red
            decreaseRegion = decrease & significantChange;
            if any(decreaseRegion(:))
                highlightImg(:,:,1) = highlightImg(:,:,1) + 1.0 * double(decreaseRegion);
            end
            
            currentHighlightImg = highlightImg;
            
            axes(ax4);
            cla(ax4);
            
            % Use earlier image as base
            baseImg = earlierImg;
            
            % Enhanced blending for brighter highlights
            highlightIntensity = 0.8;
            maskIntensity = max(highlightImg, [], 3);
            
            resultImg = baseImg .* (1 - highlightIntensity * maskIntensity) + ...
                        highlightIntensity * highlightImg;
            
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;
            
            imshow(resultImg);
            title(ax4, sprintf('Highlight (Yellow=Inc, Red=Dec, Th: %.2f)', currentThreshold), 'FontSize', 11);
            
            displayBasicStatistics(diff, increase, decrease, significantChange);
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
            isComprehensiveMode = false;
            
            % Reset other toggles
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Basic Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            set(comprehensiveToggle, 'Value', 0);
            set(comprehensiveToggle, 'String', 'superimposed Map');
            
            % Determine temporal order
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            increase = gray_later > gray_earlier;
            significantChange = diff > currentThreshold;
            
            hasIncrease = any(increase(:) & significantChange(:));
            updateLamps(hasIncrease, false);
            
            % Use earlier image as base
            baseImg = earlierImg;
            highlightImg = zeros(size(earlierImg));
            highlightImg(:,:,1) = 1.0 * double(increase & significantChange);
            highlightImg(:,:,2) = 1.0 * double(increase & significantChange);
            
            axes(ax4);
            cla(ax4);
            
            highlightIntensity = 0.8;
            yellowMask = max(highlightImg(:,:,1), highlightImg(:,:,2));
            resultImg = baseImg .* (1 - highlightIntensity * yellowMask) + ...
                        highlightIntensity * highlightImg;
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;
            
            imshow(resultImg);
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
            isComprehensiveMode = false;
            
            % Reset other toggles
            set(heatmapToggle, 'Value', 0);
            set(heatmapToggle, 'String', 'Basic Heatmap');
            set(highlightToggle, 'Value', 0);
            set(highlightToggle, 'String', 'Highlight');
            set(comprehensiveToggle, 'Value', 0);
            set(comprehensiveToggle, 'String', 'superimposed Map');
            
            % Determine temporal order
            [earlierImg, laterImg, isImg1Earlier] = getTemporalOrder(selectedImg1, selectedImg2);
            
            gray_earlier = rgb2gray(earlierImg);
            gray_later = rgb2gray(laterImg);
            diff = abs(gray_later - gray_earlier);
            
            decrease = gray_later < gray_earlier;
            significantChange = diff > currentThreshold;
            
            hasDecrease = any(decrease(:) & significantChange(:));
            updateLamps(false, hasDecrease);
            
            % Use earlier image as base
            baseImg = earlierImg;
            highlightImg = zeros(size(earlierImg));
            highlightImg(:,:,1) = 1.0 * double(decrease & significantChange);
            
            axes(ax4);
            cla(ax4);
            
            highlightIntensity = 0.8;
            redMask = highlightImg(:,:,1);
            resultImg = baseImg .* (1 - highlightIntensity * redMask) + ...
                        highlightIntensity * highlightImg;
            resultImg = min(max(resultImg, 0), 1);
            resultImg = resultImg.^0.9;
            
            imshow(resultImg);
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
                
                % Show the earlier image
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
                    boundary = bwperim(increaseRegion);
                    se = strel('disk', 1);
                    boundary = imdilate(boundary, se);
                    increaseBoundary(:,:,1) = double(boundary);
                    increaseBoundary(:,:,2) = double(boundary);
                end
                
                if any(decreaseRegion(:))
                    boundary = bwperim(decreaseRegion);
                    se = strel('disk', 1);
                    boundary = imdilate(boundary, se);
                    decreaseBoundary(:,:,1) = double(boundary);
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
            delayTime = get(flickSpeedSlider, 'Value');
            numCycles = 3;
            
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
            
            % Create boundaries
            increaseBoundary = zeros(size(earlierImg));
            decreaseBoundary = zeros(size(earlierImg));
            
            if any(increaseRegion(:))
                boundary = bwperim(increaseRegion);
                se = strel('disk', 1);
                boundary = imdilate(boundary, se);
                increaseBoundary(:,:,1) = double(boundary);
                increaseBoundary(:,:,2) = double(boundary);
            end
            
            if any(decreaseRegion(:))
                boundary = bwperim(decreaseRegion);
                se = strel('disk', 1);
                boundary = imdilate(boundary, se);
                decreaseBoundary(:,:,1) = double(boundary);
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
                frames{frameIndex} = im2uint8(earlierImg);
                frameIndex = frameIndex + 1;
                
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
                exportData.analysisMode = 'unknown';
                
                % Determine current analysis mode
                if isComprehensiveMode
                    exportData.analysisMode = 'comprehensive';
                elseif isHeatmapOn
                    exportData.analysisMode = 'basicHeatmap';
                elseif isHighlightOn
                    exportData.analysisMode = 'highlight';
                elseif isIncreaseOnlyOn
                    exportData.analysisMode = 'increaseOnly';
                elseif isDecreaseOnlyOn
                    exportData.analysisMode = 'decreaseOnly';
                end
                
                save(fullpath, 'exportData');
                
                updateStatus(sprintf('Data exported to: %s', filename));
                msgbox('Data exported successfully!', 'Success');
            end
            
        catch ME
            errordlg(['Export failed: ' ME.message], 'Error');
        end
    end
    
    function displayBasicStatistics(diff, increase, decrease, significantChange)
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
            isComprehensiveMode = false;
            
            % Reset UI controls
            if isvalid(heatmapToggle)
                set(heatmapToggle, 'Value', 0);
                set(heatmapToggle, 'String', 'Basic Heatmap');
            end
            if isvalid(highlightToggle)
                set(highlightToggle, 'Value', 0);
                set(highlightToggle, 'String', 'Highlight');
            end
            if isvalid(comprehensiveToggle)
                set(comprehensiveToggle, 'Value', 0);
                set(comprehensiveToggle, 'String', 'superimposed Map');
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
