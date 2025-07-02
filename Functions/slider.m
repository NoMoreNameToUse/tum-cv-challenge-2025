function varargout = curtainSliderDisplay(varargin)
% CURTAINSLIDERDISPLAY - Curtain slider display tool for two original image comparison
% 
% Usage:
%   curtainSliderDisplay()                    % Standalone mode, folder selection dialog
%   curtainSliderDisplay(img1, img2)          % Direct input of two original images
%   curtainSliderDisplay(img1, img2, titles)  % Input images and titles
%   fig_handle = curtainSliderDisplay(...)    % Return figure handle
%
% Input parameters:
%   img1, img2 - Two original images for comparison (image data or file paths)
%   titles     - Image titles (optional)
%
% Output parameters:
%   fig_handle - Generated figure window handle

% ==================== Global Variable Definition ====================
persistent app_data

%% ==================== Main Function Entry ====================
try
    % Initialize application data structure
    if isempty(app_data)
        app_data = initializeAppData();
    end
    
    % Parse arguments and determine mode
    [img1, img2, titles, folder_mode] = parseInputArguments(varargin{:});
    
    % Ensure consistent image sizes
    [img1, img2] = normalizeImageSizes(img1, img2);
    
    % Update application data
    app_data.current_img1 = img1;
    app_data.current_img2 = img2;
    app_data.current_titles = titles;
    app_data.folder_mode = folder_mode;
    app_data.image_width = size(img1, 2);
    app_data.image_height = size(img1, 1);
    app_data.is_scanning = false;
    
    % Create user interface
    createUserInterface();
    
    % Initial display
    updateDisplay();
    
    % Return figure handle
    if nargout > 0
        varargout{1} = app_data.fig_handle;
    end
    
catch ME
    % Error handling
    handleError(ME, 'Error occurred during curtain slider display initialization');
    if nargout > 0
        varargout{1} = [];
    end
end

%% ==================== Initialization Functions ====================
    function data = initializeAppData()
        % Initialize application data structure
        data = struct();
        data.current_folder = '';
        data.image_files = {};
        data.display_names = {};
        data.current_img1 = [];
        data.current_img2 = [];
        data.current_titles = {'Image 1', 'Image 2'};
        data.folder_mode = false;
        data.image_width = 0;
        data.image_height = 0;
        data.is_scanning = false;
        
        % UI component handles
        data.fig_handle = [];
        data.main_axes = [];
        data.img_handle = [];
        data.slider_handle = [];
        data.position_text = [];
        data.scan_button = [];
        data.popup1 = [];
        data.popup2 = [];
        data.folder_button = [];
    end

%% ==================== Argument Parsing Functions ====================
    function [img1, img2, titles, folder_mode] = parseInputArguments(varargin)
        % Parse input arguments
        if nargin == 0
            % Standalone mode: user selects image folder
            [img1, img2, titles] = selectFolderAndLoadImages();
            folder_mode = true;
            
        elseif nargin == 2
            img1 = varargin{1};
            img2 = varargin{2};
            titles = {'Original Image 1', 'Original Image 2'};
            folder_mode = false;
            
        elseif nargin == 3
            img1 = varargin{1};
            img2 = varargin{2};
            titles = varargin{3};
            folder_mode = false;
            
        else
            error('Incorrect number of input arguments. Please refer to help documentation for correct usage.');
        end
        
        % Load image data (if file paths are provided)
        img1 = loadImageData(img1);
        img2 = loadImageData(img2);
    end

%% ==================== Folder Selection and Image Loading ====================
    function [img1, img2, titles] = selectFolderAndLoadImages()
        % Select folder and load images
        folder_path = uigetdir('', 'Select folder containing images');
        if isequal(folder_path, 0)
            error('User cancelled folder selection');
        end
        
        % Scan image files
        [image_files, display_names] = scanImageFiles(folder_path);
        
        if isempty(image_files)
            error('No image files found in the selected folder!');
        end
        
        % Update global data
        app_data.current_folder = folder_path;
        app_data.image_files = image_files;
        app_data.display_names = display_names;
        
        % Default selection: first two images
        img1 = imread(image_files{1});
        if length(image_files) >= 2
            img2 = imread(image_files{2});
            titles = {display_names{1}, display_names{2}};
        else
            img2 = img1; % If only one image, duplicate display
            titles = {display_names{1}, display_names{1}};
        end
    end

    function [image_files, display_names] = scanImageFiles(folder_path)
        % Scan image files in folder
        image_extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff', '*.gif'};
        image_files = {};
        
        for i = 1:length(image_extensions)
            files = dir(fullfile(folder_path, image_extensions{i}));
            for j = 1:length(files)
                if ~files(j).isdir % Exclude directories
                    image_files{end+1} = fullfile(folder_path, files(j).name);
                end
            end
        end
        
        % Generate display names
        if ~isempty(image_files)
            [~, filenames, exts] = cellfun(@fileparts, image_files, 'UniformOutput', false);
            display_names = cellfun(@(x,y) [x,y], filenames, exts, 'UniformOutput', false);
        else
            display_names = {};
        end
    end

    function img_data = loadImageData(img_input)
        % Load image data
        if ischar(img_input) || isstring(img_input)
            try
                img_data = imread(img_input);
            catch ME
                error('Unable to read image file: %s', img_input);
            end
        else
            img_data = img_input;
        end
    end

    function [img1_norm, img2_norm] = normalizeImageSizes(img1, img2)
        % Ensure consistent image sizes
        [h1, w1, ~] = size(img1);
        [h2, w2, ~] = size(img2);
        
        if h1 ~= h2 || w1 ~= w2
            % Resize to smaller dimensions
            target_h = min(h1, h2);
            target_w = min(w1, w2);
            img1_norm = imresize(img1, [target_h, target_w]);
            img2_norm = imresize(img2, [target_h, target_w]);
        else
            img1_norm = img1;
            img2_norm = img2;
        end
    end

%% ==================== User Interface Creation ====================
    function createUserInterface()
        % Create main window
        createMainWindow();
        
        % Create image display area
        createImageDisplayArea();
        
        % Create slider control area
        createSliderControls();
        
        % Create control panel
        createControlPanel();
        
        % If folder mode, create image selection controls
        if app_data.folder_mode
            createImageSelectionControls();
        end
        
        % Create information display area
        createInfoDisplay();
    end

    function createMainWindow()
        % Create main window
        app_data.fig_handle = figure(...
            'Name', 'Curtain Slider - Original Images Comparison', ...
            'NumberTitle', 'off', ...
            'Position', [100, 100, 1200, 900], ...
            'Color', 'white', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'Resize', 'off', ...
            'CloseRequestFcn', @closeApplication);
    end

    function createImageDisplayArea()
        % Create image display area
        app_data.main_axes = axes(...
            'Parent', app_data.fig_handle, ...
            'Position', [0.05, 0.35, 0.9, 0.6], ...
            'XTick', [], 'YTick', []);
        
        % Initial image display
        curtain_pos = round(app_data.image_width / 2);
        combined_img = createCurtainImage(app_data.current_img1, app_data.current_img2, curtain_pos);
        app_data.img_handle = imshow(combined_img, 'Parent', app_data.main_axes);
        
        title(app_data.main_axes, ...
            sprintf('Curtain Comparison: %s ←→ %s', app_data.current_titles{1}, app_data.current_titles{2}), ...
            'FontSize', 14, 'FontWeight', 'bold');
    end

    function createSliderControls()
        % Create slider control area
        slider_y = 0.25;
        
        % Main slider
        app_data.slider_handle = uicontrol(...
            'Style', 'slider', ...
            'Min', 1, 'Max', app_data.image_width, ...
            'Value', round(app_data.image_width/2), ...
            'Units', 'normalized', ...
            'Position', [0.1, slider_y, 0.4, 0.03], ...
            'Callback', @sliderCallback);
        
        % Slider labels
        uicontrol(...
            'Style', 'text', ...
            'String', app_data.current_titles{1}, ...
            'Units', 'normalized', ...
            'Position', [0.05, slider_y-0.04, 0.12, 0.03], ...
            'FontSize', 11, 'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'center');
        
        uicontrol(...
            'Style', 'text', ...
            'String', app_data.current_titles{2}, ...
            'Units', 'normalized', ...
            'Position', [0.43, slider_y-0.04, 0.12, 0.03], ...
            'FontSize', 11, 'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'center');
        
        % Position display
        app_data.position_text = uicontrol(...
            'Style', 'text', ...
            'String', sprintf('Curtain Position: %d / %d', round(app_data.image_width/2), app_data.image_width), ...
            'Units', 'normalized', ...
            'Position', [0.2, slider_y+0.03, 0.16, 0.03], ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'center');
    end

    function createControlPanel()
        % Create control panel
        control_y = 0.25;
        button_width = 0.08;
        button_height = 0.04;
        spacing = 0.01;
        
        % Button position calculation
        current_x = 0.58;
        
        % Re-select folder button
        app_data.folder_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Select New Folder', ...
            'Units', 'normalized', ...
            'Position', [0.05, 0.08, 0.12, 0.04], ...
            'FontSize', 10, ...
            'Callback', @selectNewFolder);
        
        % Position control buttons
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', '← Show Left', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y, button_width, button_height], ...
            'FontSize', 9, ...
            'Callback', @(src, evt) resetPosition('left'));
        current_x = current_x + button_width + spacing;
        
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Center', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y, 0.06, button_height], ...
            'FontSize', 9, ...
            'Callback', @(src, evt) resetPosition('center'));
        current_x = current_x + 0.06 + spacing;
        
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Show Right →', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y, button_width, button_height], ...
            'FontSize', 9, ...
            'Callback', @(src, evt) resetPosition('right'));
        
        % Animation control buttons
        app_data.scan_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Auto Scan', ...
            'Units', 'normalized', ...
            'Position', [0.58, control_y-0.05, 0.1, button_height], ...
            'FontSize', 9, ...
            'Callback', @autoScanCallback);
        
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Save Auto Scan GIF', ...
            'Units', 'normalized', ...
            'Position', [0.69, control_y-0.05, 0.13, button_height], ...
            'FontSize', 9, ...
            'Callback', @saveAutoScanGIF);
    end

    function createImageSelectionControls()
        % Create image selection controls
        control_y = 0.15;
        
        % Left image selection label
        uicontrol(...
            'Style', 'text', ...
            'String', 'Left Image:', ...
            'Units', 'normalized', ...
            'Position', [0.05, control_y, 0.08, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
        
        % Left image selection dropdown
        app_data.popup1 = uicontrol(...
            'Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [0.14, control_y, 0.25, 0.03], ...
            'FontSize', 9, ...
            'Callback', @updateLeftImage);
        
        % Right image selection label
        uicontrol(...
            'Style', 'text', ...
            'String', 'Right Image:', ...
            'Units', 'normalized', ...
            'Position', [0.41, control_y, 0.08, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
        
        % Right image selection dropdown
        app_data.popup2 = uicontrol(...
            'Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', min(2, length(app_data.display_names)), ...
            'Units', 'normalized', ...
            'Position', [0.5, control_y, 0.25, 0.03], ...
            'FontSize', 9, ...
            'Callback', @updateRightImage);
    end

    function createInfoDisplay()
        % Create information display area
        img_info = sprintf('Image Size: %dx%d pixels', app_data.image_width, app_data.image_height);
        uicontrol(...
            'Style', 'text', ...
            'String', img_info, ...
            'Units', 'normalized', ...
            'Position', [0.05, 0.04, 0.3, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
    end

%% ==================== Display Update Functions ====================
    function updateDisplay()
        % Update image display
        try
            curtain_pos = round(app_data.image_width / 2);
            updateCurtainImage(curtain_pos);
            
        catch ME
            handleError(ME, 'Error occurred while updating image display');
        end
    end

    function updateCurtainImage(curtain_pos)
        % Update curtain image display
        try
            % Create curtain effect image
            new_img = createCurtainImage(app_data.current_img1, app_data.current_img2, curtain_pos);
            
            % Update display
            if ishandle(app_data.img_handle)
                set(app_data.img_handle, 'CData', new_img);
            end
            
            % Update position display
            if ishandle(app_data.position_text)
                set(app_data.position_text, 'String', ...
                    sprintf('Curtain Position: %d / %d', curtain_pos, app_data.image_width));
            end
            
            drawnow;
            
        catch ME
            handleError(ME, 'Error occurred while updating curtain image');
        end
    end

    function updateTitles()
        % Update title display
        try
            if ishandle(app_data.main_axes)
                title(app_data.main_axes, ...
                    sprintf('Curtain Comparison: %s ←→ %s', app_data.current_titles{1}, app_data.current_titles{2}), ...
                    'FontSize', 14, 'FontWeight', 'bold');
            end
        catch ME
            handleError(ME, 'Error occurred while updating title');
        end
    end

%% ==================== Callback Functions ====================
    function selectNewFolder(~, ~)
        % Re-select folder callback function
        try
            [new_img1, new_img2, new_titles] = selectFolderAndLoadImages();
            
            % Ensure consistent image sizes
            [new_img1, new_img2] = normalizeImageSizes(new_img1, new_img2);
            
            % Update application data
            app_data.current_img1 = new_img1;
            app_data.current_img2 = new_img2;
            app_data.current_titles = new_titles;
            app_data.folder_mode = true;
            app_data.image_width = size(new_img1, 2);
            app_data.image_height = size(new_img1, 1);
            
            % Update slider range
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Min', 1, 'Max', app_data.image_width, ...
                    'Value', round(app_data.image_width/2));
            end
            
            % Delete old dropdown menus
            if ishandle(app_data.popup1)
                delete(app_data.popup1);
            end
            if ishandle(app_data.popup2)
                delete(app_data.popup2);
            end
            
            % Recreate image selection controls
            createImageSelectionControls();
            
            % Update display
            updateDisplay();
            updateTitles();
            
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                handleError(ME, 'Error occurred while re-selecting folder');
            end
        end
    end

    function sliderCallback(src, ~)
        % Slider callback function
        try
            curtain_pos = round(get(src, 'Value'));
            updateCurtainImage(curtain_pos);
        catch ME
            handleError(ME, 'Error occurred during slider operation');
        end
    end

    function resetPosition(pos_type)
        % Reset position callback function
        try
            switch pos_type
                case 'left'
                    new_pos = 1;
                case 'center'
                    new_pos = round(app_data.image_width/2);
                case 'right'
                    new_pos = app_data.image_width;
            end
            
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Value', new_pos);
            end
            updateCurtainImage(new_pos);
            
        catch ME
            handleError(ME, 'Error occurred while resetting position');
        end
    end

    function autoScanCallback(~, ~)
        % Auto scan callback function
        try
            if ~app_data.is_scanning
                % Start scanning
                app_data.is_scanning = true;
                if ishandle(app_data.scan_button)
                    set(app_data.scan_button, 'String', 'Stop Scan');
                end
                
                % Execute scan animation
                performAutoScan();
                
                % Stop scanning
                app_data.is_scanning = false;
                if ishandle(app_data.scan_button)
                    set(app_data.scan_button, 'String', 'Auto Scan');
                end
            else
                % Stop scanning
                app_data.is_scanning = false;
                if ishandle(app_data.scan_button)
                    set(app_data.scan_button, 'String', 'Auto Scan');
                end
            end
            
        catch ME
            handleError(ME, 'Error occurred during auto scan');
        end
    end

    function performAutoScan()
        % Execute auto scan animation
        step_size = max(1, round(app_data.image_width/50)); % Complete scan in 50 steps
        
        % Left to right
        for pos = 1:step_size:app_data.image_width
            if ~ishandle(app_data.fig_handle) || ~app_data.is_scanning
                break;
            end
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Value', pos);
            end
            updateCurtainImage(pos);
            pause(0.05);
        end
        
        % Right to left
        for pos = app_data.image_width:-step_size:1
            if ~ishandle(app_data.fig_handle) || ~app_data.is_scanning
                break;
            end
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Value', pos);
            end
            updateCurtainImage(pos);
            pause(0.05);
        end
    end

    function updateLeftImage(src, ~)
        % Update left image
        try
            if ~isempty(app_data.image_files)
                selected_idx = get(src, 'Value');
                new_img1 = imread(app_data.image_files{selected_idx});
                app_data.current_titles{1} = app_data.display_names{selected_idx};
                
                % Ensure consistent image sizes
                [new_img1, app_data.current_img2] = normalizeImageSizes(new_img1, app_data.current_img2);
                app_data.current_img1 = new_img1;
                
                % Update image size information
                app_data.image_width = size(app_data.current_img1, 2);
                app_data.image_height = size(app_data.current_img1, 1);
                
                % Update slider range
                if ishandle(app_data.slider_handle)
                    current_val = get(app_data.slider_handle, 'Value');
                    new_val = min(current_val, app_data.image_width);
                    set(app_data.slider_handle, 'Min', 1, 'Max', app_data.image_width, 'Value', new_val);
                end
                
                % Update display
                updateCurtainImage(round(app_data.image_width/2));
                updateTitles();
            end
        catch ME
            handleError(ME, 'Error occurred while updating left image');
        end
    end

    function updateRightImage(src, ~)
        % Update right image
        try
            if ~isempty(app_data.image_files)
                selected_idx = get(src, 'Value');
                new_img2 = imread(app_data.image_files{selected_idx});
                app_data.current_titles{2} = app_data.display_names{selected_idx};
                
                % Ensure consistent image sizes
                [app_data.current_img1, new_img2] = normalizeImageSizes(app_data.current_img1, new_img2);
                app_data.current_img2 = new_img2;
                
                % Update image size information
                app_data.image_width = size(app_data.current_img1, 2);
                app_data.image_height = size(app_data.current_img1, 1);
                
                % Update slider range
                if ishandle(app_data.slider_handle)
                    current_val = get(app_data.slider_handle, 'Value');
                    new_val = min(current_val, app_data.image_width);
                    set(app_data.slider_handle, 'Min', 1, 'Max', app_data.image_width, 'Value', new_val);
                end
                
                % Update display
                updateCurtainImage(round(app_data.image_width/2));
                updateTitles();
            end
        catch ME
            handleError(ME, 'Error occurred while updating right image');
        end
    end

    function saveAutoScanGIF(~, ~)
        % Save auto scan GIF
        try
            % Show save dialog
            [filename, pathname] = uiputfile(...
                {'*.gif', 'GIF files (*.gif)'}, ...
                'Save Auto Scan as GIF');
            
            if isequal(filename, 0)
                return;
            end
            
            % Ensure file extension is .gif
            [~, name, ext] = fileparts(filename);
            if ~strcmpi(ext, '.gif')
                filename = [name, '.gif'];
            end
            
            full_filename = fullfile(pathname, filename);
            
            % Temporarily disable Auto Scan button
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'Enable', 'off', 'String', 'Creating GIF...');
            end
            
            % Generate GIF
            createAutoScanGIF(full_filename);
            
            % Restore button
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'Enable', 'on', 'String', 'Auto Scan');
            end
            
            msgbox(['Auto Scan GIF saved successfully!' newline 'Location: ' full_filename], 'Success', 'help');
            
        catch ME
            % Restore button
            if ishandle(app_data.scan_button)
                set(app_data.scan_button, 'Enable', 'on', 'String', 'Auto Scan');
            end
            handleError(ME, 'Error occurred while saving GIF');
        end
    end

    function createAutoScanGIF(filename)
        % Create auto scan GIF
        delay_time = 0.1;
        step_size = max(1, round(app_data.image_width/30));
        
        frame_count = 0;
        colormap_created = false;
        gif_colormap = [];
        
        % Left to right scan
        for pos = 1:step_size:app_data.image_width
            if ~ishandle(app_data.fig_handle)
                break;
            end
            
            % Update image
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Value', pos);
            end
            updateCurtainImage(pos);
            
            % Capture current frame
            current_img = get(app_data.img_handle, 'CData');
            
            % Process GIF frame
            if ~colormap_created
                [indexed_img, gif_colormap] = rgb2ind(current_img, 256, 'dither');
                colormap_created = true;
                imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                       'Loopcount', inf, 'DelayTime', delay_time);
            else
                indexed_img = rgb2ind(current_img, gif_colormap, 'dither');
                imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                       'WriteMode', 'append', 'DelayTime', delay_time);
            end
            
            frame_count = frame_count + 1;
            pause(0.02);
        end
        
        % Right to left scan
        for pos = app_data.image_width:-step_size:1
            if ~ishandle(app_data.fig_handle)
                break;
            end
            
            % Update image
            if ishandle(app_data.slider_handle)
                set(app_data.slider_handle, 'Value', pos);
            end
            updateCurtainImage(pos);
            
            % Capture current frame
            current_img = get(app_data.img_handle, 'CData');
            indexed_img = rgb2ind(current_img, gif_colormap, 'dither');
            imwrite(indexed_img, gif_colormap, filename, 'gif', ...
                   'WriteMode', 'append', 'DelayTime', delay_time);
            
            frame_count = frame_count + 1;
            pause(0.02);
        end
    end

    function closeApplication(~, ~)
        % Close application
        try
            % Stop scanning
            app_data.is_scanning = false;
            
            if ishandle(app_data.fig_handle)
                delete(app_data.fig_handle);
            end
            
            % Clear persistent variables
            clear app_data;
            
        catch ME
            % Delete window even if error occurs
            if ishandle(app_data.fig_handle)
                delete(app_data.fig_handle);
            end
        end
    end

%% ==================== Utility Functions ====================
    function curtain_img = createCurtainImage(img1, img2, curtain_pos)
        % Create curtain effect image
        try
            [h, w, c] = size(img1);
            curtain_img = zeros(h, w, c, 'like', img1);
            
            curtain_pos = max(1, min(w, round(curtain_pos)));
            
            % Left side shows img1, right side shows img2
            if curtain_pos > 1
                curtain_img(:, 1:curtain_pos-1, :) = img1(:, 1:curtain_pos-1, :);
            end
            if curtain_pos <= w
                curtain_img(:, curtain_pos:end, :) = img2(:, curtain_pos:end, :);
            end
            
            % Add curtain line
            if curtain_pos > 1 && curtain_pos <= w
                curtain_img(:, curtain_pos, 1) = 255; % Red line
                curtain_img(:, curtain_pos, 2) = 0;
                curtain_img(:, curtain_pos, 3) = 0;
            end
            
        catch ME
            handleError(ME, 'Error occurred while creating curtain image');
            curtain_img = img1; % Return default image
        end
    end

    function handleError(ME, context)
        % Unified error handling function
        error_msg = sprintf('%s\nError details: %s', context, ME.message);
        
        % Display error dialog
        if ishandle(app_data.fig_handle)
            errordlg(error_msg, 'Error', 'modal');
        else
            fprintf('Error: %s\n', error_msg);
        end
        
        % Log error to command window
        fprintf('Error in curtainSliderDisplay: %s\n', error_msg);
    end

end