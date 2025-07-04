function varargout = curtainSliderDisplay(varargin)
% CURTAINSLIDERDISPLAY - Interactive curtain slider image comparison tool
%
% ==================================================================================
% Function Description:
%   Control "curtain" position through MOUSE DRAG to achieve dynamic comparison of two images
%
% ==================================================================================
% Input Parameters:
%   1. curtainSliderDisplay()
%      - No parameter call, popup folder selection dialog
%      - Automatically load image sequence and perform preprocessing (registration + cropping)
%      - Select the first two images for comparison
%
%   2. curtainSliderDisplay(img1, img2)
%      - img1, img2: Image data (matrix) or image file path (string)
%      - Directly compare two specified images without preprocessing
%      - Default titles are 'Image 1', 'Image 2'
%
%   3. curtainSliderDisplay(img1, img2, titles)
%      - img1, img2: Same as above
%      - titles: Image title cell array, e.g., {'Left Image', 'Right Image'}
%      - Custom image title display
%
% ==================================================================================
% Interactive Controls:
%   - MOUSE DRAG: Click and drag on the image to control curtain position
%   - LEFT CLICK: Set curtain position at click point
%   - DRAG: Real-time curtain position update during mouse movement
%
% ==================================================================================
% External Functions:
%   1. loadImageSequence.m        - Load image sequence, extract metadata
%   2. preprocessImageSequence.m  - Image registration (alignment) processing  
%   3. cropToCommonRegion.m       - Crop to common visible region
%
% ==================================================================================
% Usage Examples:
%   % Example 1: Folder selection mode (recommended)
%   curtainSliderDisplay();  % Popup folder selection, automatic preprocessing
%
%   % Example 2: Direct image input
%   img1 = imread('image1.jpg');
%   img2 = imread('image2.jpg');
%   curtainSliderDisplay(img1, img2);
%
%   % Example 3: With custom titles
%   titles = {'Before Processing', 'After Processing'};
%   fig_handle = curtainSliderDisplay(img1, img2, titles);
%
% ==================================================================================

% Persistent application data structure
persistent app_data

%% ================== Main Function Entry Point ==================
if isempty(app_data)
    % Initialize application data structure
    app_data = struct('folder_mode', false, 'image_files', {{}}, 'display_names', {{}}, ...
                     'processed_imgs', {{}}, 'metas', [], 'is_scanning', false, ...
                     'fig_handle', [], 'main_axes', [], 'img_handle', [], ...
                     'scan_button', [], 'popup1', [], 'popup2', [], ...
                     'is_dragging', false, 'current_curtain_pos', 0);
end

% Parse input parameters and determine working mode
[img1, img2, titles, folder_mode] = parseInputs(varargin{:});

% Ensure consistent image sizes
[img1, img2] = normalizeImageSizes(img1, img2);

% Update global application data
app_data.current_img1 = img1;
app_data.current_img2 = img2;
app_data.current_titles = titles;
app_data.folder_mode = folder_mode;
app_data.image_width = size(img1, 2);
app_data.image_height = size(img1, 1);
app_data.current_curtain_pos = round(app_data.image_width / 2);

% Create user interface and initial display
createGUI();
updateDisplay();

% Return figure handle
if nargout > 0
    varargout{1} = app_data.fig_handle;
end

%% ================== Input Parameter Parser ==================
    function [img1, img2, titles, folder_mode] = parseInputs(varargin)
        % Determine calling mode based on number of input parameters
        switch nargin
            case 0
                % Mode 1: Folder selection + automatic preprocessing
                [img1, img2, titles] = loadAndProcessFromFolder();
                folder_mode = true;
                
            case 2
                % Mode 2: Direct input of two images
                img1 = loadImage(varargin{1});
                img2 = loadImage(varargin{2});
                titles = {'Image 1', 'Image 2'};
                folder_mode = false;
                
            case 3
                % Mode 3: Input images + custom titles
                img1 = loadImage(varargin{1});
                img2 = loadImage(varargin{2});
                titles = varargin{3};
                folder_mode = false;
                
            otherwise
                error('curtainSliderDisplay:InvalidArguments', ...
                      'Invalid input arguments. Supports 0, 2, or 3 parameters. Please check help documentation.');
        end
    end

%% ================== Folder Loading and Preprocessing Workflow ==================
    function [img1, img2, titles] = loadAndProcessFromFolder()
        % User selects folder containing image sequence
        folder_path = uigetdir('', 'Select folder containing image sequence');
        if isequal(folder_path, 0)
            error('curtainSliderDisplay:UserCancelled', 'User cancelled folder selection');
        end
        
        % Display preprocessing progress bar
        h_wait = waitbar(0, 'Loading image sequence...', 'Name', 'Image Preprocessing Progress');
        
        try
            % Step 1: Load image sequence and metadata
            waitbar(0.2, h_wait, 'Loading image sequence...');
            [imgs, metas] = loadImageSequence(folder_path);
            
            % Step 2: Image registration (alignment processing)
            waitbar(0.4, h_wait, 'Performing image registration...');
            [alignedImgs, tforms] = preprocessImageSequence(imgs);
            
            % Step 3: Crop to maximum common region
            waitbar(0.8, h_wait, 'Cropping to common region...');
            croppedImgs = cropToCommonRegion(alignedImgs);
            
            waitbar(1.0, h_wait, 'Preprocessing complete!');
            close(h_wait);
            
            % Store preprocessing results to application data
            app_data.current_folder = folder_path;
            app_data.processed_imgs = croppedImgs;
            app_data.metas = metas;
            app_data.display_names = createDisplayNames(metas);
            
            % Select first two images for initial display
            img1 = croppedImgs{1};
            img2 = croppedImgs{min(2, length(croppedImgs))};
            titles = app_data.display_names(1:min(2, length(app_data.display_names)));
            
            % Handle case with only one image
            if length(croppedImgs) == 1
                img2 = img1;
                titles{2} = titles{1};
            end
            
        catch ME
            if ishandle(h_wait)
                close(h_wait);
            end
            rethrow(ME);
        end
    end

%% ================== Display Name Generator ==================
    function names = createDisplayNames(metas)
        names = cell(1, length(metas));
        for i = 1:length(metas)
            if ~isnan(metas(i).year)
                if ~isnan(metas(i).month)
                    % Format: Year-Month (filename)
                    names{i} = sprintf('%04d-%02d (%s)', metas(i).year, metas(i).month, metas(i).name);
                else
                    % Format: Year (filename)
                    names{i} = sprintf('%04d (%s)', metas(i).year, metas(i).name);
                end
            else
                % Display filename only
                names{i} = metas(i).name;
            end
        end
    end

%% ================== Image Loader ==================
    function img_data = loadImage(img_input)
        % Support file path or image data input
        if ischar(img_input) || isstring(img_input)
            % Load from file
            img_data = im2uint8(imread(img_input));
        else
            % Use image data directly
            img_data = im2uint8(img_input);
        end
    end

%% ================== Image Size Normalization ==================
    function [img1_norm, img2_norm] = normalizeImageSizes(img1, img2)
        % Ensure two images have the same dimensions
        [h1, w1, ~] = size(img1);
        [h2, w2, ~] = size(img2);
        
        if h1 ~= h2 || w1 ~= w2
            % Resize to smaller dimensions (ensure full visibility)
            target_h = min(h1, h2);
            target_w = min(w1, w2);
            img1_norm = imresize(img1, [target_h, target_w]);
            img2_norm = imresize(img2, [target_h, target_w]);
        else
            img1_norm = img1;
            img2_norm = img2;
        end
    end

%% ================== Graphical User Interface Creation ==================
    function createGUI()
        % Create main window
        app_data.fig_handle = figure('Name', 'Interactive Curtain Slider Image Comparison Tool (Mouse Drag)', ...
            'NumberTitle', 'off', 'Position', [100, 100, 1200, 900], ...
            'Color', 'white', 'MenuBar', 'none', 'ToolBar', 'none', ...
            'Resize', 'off', 'CloseRequestFcn', @(~,~) delete(gcf));
        
        % Create image display area (larger since no slider needed)
        app_data.main_axes = axes('Position', [0.05, 0.25, 0.9, 0.7], 'XTick', [], 'YTick', []);
        
        % Initial display of curtain effect
        curtain_pos = app_data.current_curtain_pos;
        combined_img = createCurtainImage(app_data.current_img1, app_data.current_img2, curtain_pos);
        app_data.img_handle = imshow(combined_img, 'Parent', app_data.main_axes);
        
        % Set title with instruction
        title_str = 'Slider Display';

        title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
        
        % Setup interactive mouse controls
        setupMouseInteraction();
        
        % Create control buttons
        createControlButtons();
        
        % Folder mode requires image selectors
        if app_data.folder_mode
            createImageSelectors();
        end
    end

%% ================== Mouse Interaction Setup ==================
    function setupMouseInteraction()
        % Set up mouse event handlers for interactive curtain control
        
        % Mouse button down event - start dragging
        set(app_data.fig_handle, 'WindowButtonDownFcn', @mouseDownCallback);
        
        % Mouse motion event - update curtain position while dragging
        set(app_data.fig_handle, 'WindowButtonMotionFcn', @mouseMoveCallback);
        
        % Mouse button up event - stop dragging
        set(app_data.fig_handle, 'WindowButtonUpFcn', @mouseUpCallback);
        
        % Set cursor style
        set(app_data.fig_handle, 'Pointer', 'crosshair');
    end

%% ================== Mouse Event Callbacks ==================
    function mouseDownCallback(~, ~)
        % Handle mouse button down event
        current_point = get(app_data.main_axes, 'CurrentPoint');
        
        % Check if click is within image bounds
        if isPointInAxes(current_point)
            app_data.is_dragging = true;
            
            % Convert axes coordinates to image pixel coordinates
            curtain_pos = convertAxesToImageCoords(current_point);
            
            % Update curtain position
            updateCurtainPosition(curtain_pos);
            
            % Change cursor to indicate dragging mode
            set(app_data.fig_handle, 'Pointer', 'left');
        end
    end

    function mouseMoveCallback(~, ~)
        % Handle mouse motion event
        if app_data.is_dragging
            current_point = get(app_data.main_axes, 'CurrentPoint');
            
            % Check if mouse is still within valid range
            if isPointInAxes(current_point)
                % Convert coordinates and update curtain
                curtain_pos = convertAxesToImageCoords(current_point);
                updateCurtainPosition(curtain_pos);
            end
        else
            % Update cursor based on position
            current_point = get(app_data.main_axes, 'CurrentPoint');
            if isPointInAxes(current_point)
                set(app_data.fig_handle, 'Pointer', 'crosshair');
            else
                set(app_data.fig_handle, 'Pointer', 'arrow');
            end
        end
    end

    function mouseUpCallback(~, ~)
        % Handle mouse button up event
        app_data.is_dragging = false;
        set(app_data.fig_handle, 'Pointer', 'crosshair');
    end

%% ================== Coordinate Conversion Utilities ==================
    function is_valid = isPointInAxes(current_point)
        % Check if the current point is within the axes bounds
        x = current_point(1, 1);
        y = current_point(1, 2);
        
        % Get axes limits
        xlim = get(app_data.main_axes, 'XLim');
        ylim = get(app_data.main_axes, 'YLim');
        
        is_valid = (x >= xlim(1) && x <= xlim(2) && y >= ylim(1) && y <= ylim(2));
    end

    function pixel_x = convertAxesToImageCoords(current_point)
        % Convert axes coordinates to image pixel coordinates
        x = current_point(1, 1);
        
        % Get current axes limits
        xlim = get(app_data.main_axes, 'XLim');
        
        % Convert to pixel coordinate (1-based indexing)
        pixel_x = round(((x - xlim(1)) / (xlim(2) - xlim(1))) * app_data.image_width + 0.5);
        
        % Clamp to valid range
        pixel_x = max(1, min(app_data.image_width, pixel_x));
    end

%% ================== Function Button Area ==================
    function createControlButtons()
        control_y = 0.15;
        
        % Curtain position quick control buttons
        position_buttons = {
            {'← Show Left', [0.3, control_y, 0.08, 0.04], @(src,evt) resetPosition('left')};
            {'Center', [0.39, control_y, 0.06, 0.04], @(src,evt) resetPosition('center')};
            {'Show Right →', [0.46, control_y, 0.08, 0.04], @(src,evt) resetPosition('right')};
        };
        
        for i = 1:length(position_buttons)
            uicontrol('Style', 'pushbutton', 'String', position_buttons{i}{1}, ...
                'Units', 'normalized', 'Position', position_buttons{i}{2}, ...
                'FontSize', 9, 'Callback', position_buttons{i}{3});
        end
        
        % Main function buttons
        function_buttons = {
            {'Reselect Folder', [0.05, 0.08, 0.12, 0.04], @selectNewFolder};
            {'Auto Scan', [0.56, control_y, 0.1, 0.04], @autoScanCallback};
            {'Save Scan GIF', [0.67, control_y, 0.13, 0.04], @saveAutoScanGIF};
        };
        
        for i = 1:length(function_buttons)
            if i == 2
                app_data.scan_button = uicontrol('Style', 'pushbutton', ...
                    'String', function_buttons{i}{1}, 'Units', 'normalized', ...
                    'Position', function_buttons{i}{2}, 'FontSize', 9, ...
                    'Callback', function_buttons{i}{3});
            else
                uicontrol('Style', 'pushbutton', 'String', function_buttons{i}{1}, ...
                    'Units', 'normalized', 'Position', function_buttons{i}{2}, ...
                    'FontSize', 9, 'Callback', function_buttons{i}{3});
            end
        end
        
        % Add instruction text
        uicontrol('Style', 'text', 'String', 'Instruction: Click and drag on the image to control curtain position', ...
            'Units', 'normalized', 'Position', [0.05, 0.005, 0.9, 0.025], ...
            'BackgroundColor', 'white', 'FontSize', 9, 'FontWeight', 'bold', ...
            'ForegroundColor', [0.2, 0.4, 0.8]);
    end

%% ================== Image Selection ==================
    function createImageSelectors()
        control_y = 0.04;  % 调整到更低位置，避免与按钮重叠
        
        % Left image selection dropdown
        uicontrol('Style', 'text', 'String', 'Left Image:', ...
            'Units', 'normalized', 'Position', [0.05, control_y, 0.08, 0.025], ...
            'BackgroundColor', 'white', 'FontSize', 9);
        
        app_data.popup1 = uicontrol('Style', 'popupmenu', ...
            'String', app_data.display_names, 'Value', 1, ...
            'Units', 'normalized', 'Position', [0.14, control_y, 0.25, 0.025], ...
            'FontSize', 8, 'Callback', @(src,~) updateImage(1, src));
        
        % Right image selection dropdown
        uicontrol('Style', 'text', 'String', 'Right Image:', ...
            'Units', 'normalized', 'Position', [0.41, control_y, 0.08, 0.025], ...
            'BackgroundColor', 'white', 'FontSize', 9);
        
        app_data.popup2 = uicontrol('Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', min(2, length(app_data.display_names)), ...
            'Units', 'normalized', 'Position', [0.5, control_y, 0.25, 0.025], ...
            'FontSize', 8, 'Callback', @(src,~) updateImage(2, src));
    end

%% ================== Display Update Function ==================
    function updateDisplay()
        % Update display with current curtain position
        updateCurtainPosition(app_data.current_curtain_pos);
    end

%% ================== Curtain Position Update ==================
    function updateCurtainPosition(curtain_pos)
        % Update curtain position and refresh display
        app_data.current_curtain_pos = curtain_pos;
        
        % Create curtain effect composite image
        new_img = createCurtainImage(app_data.current_img1, app_data.current_img2, curtain_pos);
        
        % Update image display
        if ishandle(app_data.img_handle)
            set(app_data.img_handle, 'CData', new_img);
        end
        
        drawnow;
    end

%% ================== Callback Function Collection ==================

    % Reselect folder callback
    function selectNewFolder(~, ~)
        try
            [new_img1, new_img2, new_titles] = loadAndProcessFromFolder();
            [new_img1, new_img2] = normalizeImageSizes(new_img1, new_img2);
            
            % Update application data
            app_data.current_img1 = new_img1;
            app_data.current_img2 = new_img2;
            app_data.current_titles = new_titles;
            app_data.folder_mode = true;
            app_data.image_width = size(new_img1, 2);
            app_data.image_height = size(new_img1, 1);
            app_data.current_curtain_pos = round(app_data.image_width / 2);
            
            % Rebuild image selectors
            if ishandle(app_data.popup1), delete(app_data.popup1); end
            if ishandle(app_data.popup2), delete(app_data.popup2); end
            createImageSelectors();
            
            updateDisplay();
            updateTitles();
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                errordlg(['Processing error: ' ME.message], 'Error');
            end
        end
    end

    % Image selection callback
    function updateImage(side, src)
        idx = get(src, 'Value');
        if side == 1
            app_data.current_img1 = app_data.processed_imgs{idx};
            app_data.current_titles{1} = app_data.display_names{idx};
        else
            app_data.current_img2 = app_data.processed_imgs{idx};
            app_data.current_titles{2} = app_data.display_names{idx};
        end
        
        % Update image size information
        app_data.image_width = size(app_data.current_img1, 2);
        app_data.image_height = size(app_data.current_img1, 1);
        
        % Reset curtain to center for new images
        app_data.current_curtain_pos = round(app_data.image_width / 2);
        
        updateDisplay();
        updateTitles();
    end

    % Position reset callback
    function resetPosition(pos_type)
        switch pos_type
            case 'left'
                new_pos = 1;                             % Fully show left image
            case 'center'
                new_pos = round(app_data.image_width/2);   % Center curtain
            case 'right'
                new_pos = app_data.image_width;          % Fully show right image
        end
        
        updateCurtainPosition(new_pos);
    end

    % Auto scan control callback
    function autoScanCallback(~, ~)
        if ~app_data.is_scanning
            % Start scanning
            app_data.is_scanning = true;
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'String', 'Stop Scan');
            end
            performAutoScan();
            % Scanning ended
            app_data.is_scanning = false;
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'String', 'Auto Scan');
            end
        else
            % Stop current scanning
            app_data.is_scanning = false;
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'String', 'Auto Scan');
            end
        end
    end

    % Perform auto scan animation
    function performAutoScan()
        step_size = max(1, round(app_data.image_width/50));
        
        % Scan from left to right
        for pos = 1:step_size:app_data.image_width
            if ~ishandle(app_data.fig_handle) || ~app_data.is_scanning
                break;
            end
            updateCurtainPosition(pos);
            pause(0.05);
        end
        
        % Scan from right to left
        for pos = app_data.image_width:-step_size:1
            if ~ishandle(app_data.fig_handle) || ~app_data.is_scanning
                break;
            end
            updateCurtainPosition(pos);
            pause(0.05);
        end
    end

    % Save GIF animation callback
    function saveAutoScanGIF(~, ~)
        [filename, pathname] = uiputfile('*.gif', 'Save Auto Scan GIF');
        if filename ~= 0
            [~, name, ~] = fileparts(filename);
            filename = [name, '.gif'];
            full_filename = fullfile(pathname, filename);
            
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'Enable', 'off', 'String', 'Creating GIF...');
            end
            
            createAutoScanGIF(full_filename);
            
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'Enable', 'on', 'String', 'Auto Scan');
            end
            
            msgbox(['Auto scan GIF saved successfully!' newline 'Location: ' full_filename], 'Success');
        end
    end

    % Update title display
    function updateTitles()
        if ishandle(app_data.main_axes)
            title_str = 'Slider Display';
            title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
        end
    end

%% ================== Core Utility Functions ==================

    % Create curtain effect composite image (core algorithm)
    function curtain_img = createCurtainImage(img1, img2, curtain_pos)
        % Input:
        %   img1 - Left image
        %   img2 - Right image  
        %   curtain_pos - Curtain position (pixel coordinate)
        % Output:
        %   curtain_img - Composite curtain effect image
        
        [h, w, c] = size(img1);
        curtain_img = zeros(h, w, c, 'like', img1);
        
        % Ensure curtain position is within valid range
        curtain_pos = max(1, min(w, round(curtain_pos)));
        
        % Left side shows img1, right side shows img2
        if curtain_pos > 1
            curtain_img(:, 1:curtain_pos-1, :) = img1(:, 1:curtain_pos-1, :);
        end
        if curtain_pos <= w
            curtain_img(:, curtain_pos:end, :) = img2(:, curtain_pos:end, :);
        end
        
        % Add red curtain dividing line
        if curtain_pos > 1 && curtain_pos <= w
            curtain_img(:, curtain_pos, 1) = 255; % Red channel
            curtain_img(:, curtain_pos, 2) = 0;   % Green channel
            curtain_img(:, curtain_pos, 3) = 0;   % Blue channel
        end
    end

    % Create and save auto scan GIF
    function createAutoScanGIF(filename)
        delay_time = 0.1;  % GIF frame delay
        step_size = max(1, round(app_data.image_width/30));
        colormap_created = false;
        gif_colormap = [];
        
        % Left to right scan frames
        for pos = 1:step_size:app_data.image_width
            if ~ishandle(app_data.fig_handle)
                break;
            end
            
            updateCurtainPosition(pos);
            
            current_img = get(app_data.img_handle, 'CData');
            
            if ~colormap_created
                % Create first frame and establish color mapping
                [indexed_img, gif_colormap] = rgb2ind(current_img, 256, 'dither');
                colormap_created = true;
                imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                       'Loopcount', inf, 'DelayTime', delay_time);
            else
                % Add subsequent frames
                indexed_img = rgb2ind(current_img, gif_colormap, 'dither');
                imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                       'WriteMode', 'append', 'DelayTime', delay_time);
            end
            pause(0.02);
        end
        
        % Right to left scan frames
        for pos = app_data.image_width:-step_size:1
            if ~ishandle(app_data.fig_handle)
                break;
            end
            
            updateCurtainPosition(pos);
            
            current_img = get(app_data.img_handle, 'CData');
            indexed_img = rgb2ind(current_img, gif_colormap, 'dither');
            imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                   'WriteMode', 'append', 'DelayTime', delay_time);
            pause(0.02);
        end
    end

end
