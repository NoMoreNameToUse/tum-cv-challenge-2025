function varargout = timelapseAnimation(varargin)
% TIMELAPSEANIMATION - Time-lapse animation tool for original image sequences
% 
% Usage:
%   timelapseAnimation()                    % Standalone mode, folder selection dialog
%   timelapseAnimation(image_folder)        % Specify original image folder path
%   timelapseAnimation(image_list)          % Input original image file list
%   timelapseAnimation(image_cell_array)    % Input original image data array
%   fig_handle = timelapseAnimation(...)    % Return figure handle
%
% Input parameters:
%   image_folder     - Folder path containing original image time series
%   image_list       - List of original image file paths
%   image_cell_array - Cell array of original image data
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
    
    % Parse arguments and load data
    [image_data, image_files, folder_mode] = parseInputArguments(varargin{:});
    
    % Update application data
    app_data.image_data = image_data;
    app_data.image_files = image_files;
    app_data.folder_mode = folder_mode;
    app_data.current_img_idx = 1;
    app_data.total_frames = length(image_data);
    app_data.is_playing = false;
    
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
    handleError(ME, 'Error occurred during time-lapse animation initialization');
    if nargout > 0
        varargout{1} = [];
    end
end

%% ==================== Initialization Functions ====================
    function data = initializeAppData()
        % Initialize application data structure
        data = struct();
        data.current_folder = '';
        data.image_data = {};
        data.image_files = {};
        data.folder_mode = false;
        data.current_img_idx = 1;
        data.total_frames = 0;
        data.is_playing = false;
        data.animation_timer = [];
        
        % UI component handles
        data.fig_handle = [];
        data.main_axes = [];
        data.img_handle = [];
        data.frame_slider = [];
        data.frame_text = [];
        data.prev_button = [];
        data.next_button = [];
        data.play_button = [];
        data.pause_button = [];
        data.stop_button = [];
        data.speed_edit = [];
        data.loop_checkbox = [];
        data.info_text = [];
        data.folder_button = [];
    end

%% ==================== Argument Parsing Functions ====================
    function [image_data, image_files, folder_mode] = parseInputArguments(varargin)
        % Parse input arguments and load image data
        if nargin == 0
            % Standalone mode: user selects folder
            [image_data, image_files] = selectFolderAndLoadImages();
            folder_mode = true;
            
        elseif nargin == 1
            input_data = varargin{1};
            
            if ischar(input_data) || isstring(input_data)
                % Input is folder path
                [image_data, image_files] = loadImagesFromFolder(input_data);
                folder_mode = false;
                
            elseif iscell(input_data)
                if ischar(input_data{1}) || isstring(input_data{1})
                    % Input is file path list
                    [image_data, image_files] = loadImagesFromFileList(input_data);
                    folder_mode = false;
                else
                    % Input is image data array
                    image_data = input_data;
                    image_files = generateImageNames(length(image_data));
                    folder_mode = false;
                end
            else
                error('Input parameter format error');
            end
            
        else
            error('Incorrect number of input arguments. Please refer to help documentation for correct usage.');
        end
    end

%% ==================== Folder Selection and Image Loading ====================
    function [image_data, image_files] = selectFolderAndLoadImages()
        % Select folder and load images
        folder_path = uigetdir(pwd, 'Select folder containing original image time series');
        if isequal(folder_path, 0)
            error('User cancelled folder selection');
        end
        
        % Scan image files
        image_files = scanImageFiles(folder_path);
        
        if isempty(image_files)
            error('No image files found in the selected folder!');
        end
        
        % Update global data
        app_data.current_folder = folder_path;
        
        % Load image data
        image_data = loadImageDataFromFiles(image_files);
    end

    function [image_data, image_files] = loadImagesFromFolder(folder_path)
        % Load images from specified folder
        image_files = scanImageFiles(folder_path);
        
        if isempty(image_files)
            error('No image files found in the specified folder!');
        end
        
        image_data = loadImageDataFromFiles(image_files);
    end

    function [image_data, image_files] = loadImagesFromFileList(file_list)
        % Load images from file list
        image_files = file_list;
        image_data = loadImageDataFromFiles(image_files);
    end

    function image_files = scanImageFiles(folder_path)
        % Scan image files in folder
        image_extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff', '*.gif', ...
                           '*.JPG', '*.JPEG', '*.PNG', '*.BMP', '*.TIF', '*.TIFF', '*.GIF'};
        image_files = {};
        
        for i = 1:length(image_extensions)
            pattern = fullfile(folder_path, image_extensions{i});
            files = dir(pattern);
            for j = 1:length(files)
                if ~files(j).isdir % Exclude directories
                    image_files{end+1} = fullfile(folder_path, files(j).name);
                end
            end
        end
        
        % Remove duplicates and sort
        if ~isempty(image_files)
            image_files = unique(image_files);
            image_files = sort(image_files);
        end
        
        fprintf('Found %d image files in folder "%s"\n', length(image_files), folder_path);
    end

    function image_data = loadImageDataFromFiles(image_files)
        % Load image data from file list
        image_data = cell(length(image_files), 1);
        fprintf('Loading %d original images...\n', length(image_files));
        
        for i = 1:length(image_files)
            try
                img = imread(image_files{i});
                image_data{i} = img;
                fprintf('Loaded: %s\n', image_files{i});
                
            catch ME
                fprintf('Loading failed: %s (%s)\n', image_files{i}, ME.message);
                % Create placeholder image
                if i > 1
                    image_data{i} = image_data{i-1}; % Use previous image
                else
                    image_data{i} = zeros(480, 640, 3, 'uint8'); % Create black image
                end
            end
        end
        
        fprintf('Original image loading completed!\n');
    end

    function image_files = generateImageNames(num_images)
        % Generate image names
        image_files = cell(num_images, 1);
        for i = 1:num_images
            image_files{i} = sprintf('Original_Image_%d', i);
        end
    end

%% ==================== User Interface Creation ====================
    function createUserInterface()
        % Create main window
        createMainWindow();
        
        % Create image display area
        createImageDisplayArea();
        
        % Create playback control panel
        createPlaybackControls();
        
        % Create main control panel
        createControlPanel();
        
        % Create information display area
        createInfoDisplay();
    end

    function createMainWindow()
        % Create main window
        app_data.fig_handle = figure(...
            'Name', 'Time-lapse Animation - Original Images', ...
            'NumberTitle', 'off', ...
            'Position', [100, 100, 1200, 800], ...
            'Color', 'white', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'CloseRequestFcn', @closeApplication);
    end

    function createImageDisplayArea()
        % Create image display area
        app_data.main_axes = axes(...
            'Parent', app_data.fig_handle, ...
            'Position', [0.05, 0.3, 0.9, 0.65], ...
            'XTick', [], 'YTick', []);
        
        % Initial display of first image
        app_data.img_handle = imshow(app_data.image_data{1}, 'Parent', app_data.main_axes);
        updateTitle();
    end

    function createPlaybackControls()
        % Create playback control area
        control_y = 180;
        
        % Frame selection slider
        slider_step = calculateSliderStep();
        app_data.frame_slider = uicontrol(...
            'Style', 'slider', ...
            'Min', 1, 'Max', app_data.total_frames, ...
            'Value', 1, 'SliderStep', slider_step, ...
            'Position', [50, control_y, 500, 20], ...
            'Callback', @frameSliderCallback);
        
        % Current frame display
        app_data.frame_text = uicontrol(...
            'Style', 'text', ...
            'String', sprintf('Frame: 1 / %d', app_data.total_frames), ...
            'Position', [560, control_y-5, 80, 25], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white');
        
        % Previous/Next buttons
        app_data.prev_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', '◀', ...
            'Position', [650, control_y-5, 30, 25], ...
            'FontSize', 12, ...
            'Callback', @prevFrameCallback);
        
        app_data.next_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', '▶', ...
            'Position', [685, control_y-5, 30, 25], ...
            'FontSize', 12, ...
            'Callback', @nextFrameCallback);
    end

    function createControlPanel()
        % Create main control panel
        control_y = 140;
        button_width = 60;
        button_height = 30;
        spacing = 10;
        
        % Re-select folder button
        app_data.folder_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Select New Folder', ...
            'Position', [50, 50, 120, 25], ...
            'FontSize', 10, ...
            'Callback', @selectNewFolder);
        
        % Playback control buttons
        current_x = 50;
        
        app_data.play_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Play', ...
            'Position', [current_x, control_y, button_width, button_height], ...
            'Callback', @playCallback);
        current_x = current_x + button_width + spacing;
        
        app_data.pause_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Pause', ...
            'Position', [current_x, control_y, button_width, button_height], ...
            'Enable', 'off', ...
            'Callback', @pauseCallback);
        current_x = current_x + button_width + spacing;
        
        app_data.stop_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Stop', ...
            'Position', [current_x, control_y, button_width, button_height], ...
            'Enable', 'off', ...
            'Callback', @stopCallback);
        current_x = current_x + button_width + spacing;
        
        % Playback speed control
        uicontrol(...
            'Style', 'text', ...
            'String', 'Speed (fps):', ...
            'Position', [current_x, control_y+5, 100, 20], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white');
        current_x = current_x + 100;
        
        app_data.speed_edit = uicontrol(...
            'Style', 'edit', ...
            'String', '2', ...
            'Position', [current_x, control_y+5, 40, 20], ...
            'Callback', @speedCallback);
        current_x = current_x + 50;
        
        % Loop playback option
        app_data.loop_checkbox = uicontrol(...
            'Style', 'checkbox', ...
            'String', 'Loop', ...
            'Position', [current_x, control_y+5, 100, 20], ...
            'Value', 1, ...
            'BackgroundColor', 'white');
        
        % Export GIF function
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Export GIF', ...
            'Position', [50, 100, 100, 25], ...
            'Callback', @exportGIF);
    end

    function createInfoDisplay()
        % Create information display area
        app_data.info_text = uicontrol(...
            'Style', 'text', ...
            'String', getImageInfo(), ...
            'Position', [200, 50, 500, 40], ...
            'FontSize', 9, ...
            'HorizontalAlignment', 'left', ...
            'BackgroundColor', 'white');
    end

    function slider_step = calculateSliderStep()
        % Calculate slider step
        if app_data.total_frames > 1
            step1 = 1/(app_data.total_frames-1);
            step2 = max(0.1, step1);
            slider_step = [step1, step2];
        else
            slider_step = [1, 1];
        end
    end

%% ==================== Display Update Functions ====================
    function updateDisplay()
        % Update image display
        try
            updateCurrentFrame(app_data.current_img_idx);
        catch ME
            handleError(ME, 'Error occurred while updating image display');
        end
    end

    function updateCurrentFrame(new_idx)
        % Update current frame display
        try
            if new_idx < 1 || new_idx > app_data.total_frames
                return;
            end
            
            app_data.current_img_idx = new_idx;
            
            % Update image display
            if ishandle(app_data.img_handle)
                set(app_data.img_handle, 'CData', app_data.image_data{app_data.current_img_idx});
            end
            
            % Update slider
            if ishandle(app_data.frame_slider)
                set(app_data.frame_slider, 'Value', app_data.current_img_idx);
            end
            
            % Update frame count display
            if ishandle(app_data.frame_text)
                set(app_data.frame_text, 'String', ...
                    sprintf('Frame: %d / %d', app_data.current_img_idx, app_data.total_frames));
            end
            
            % Update title and information
            updateTitle();
            updateInfoDisplay();
            
        catch ME
            handleError(ME, 'Error occurred while updating current frame');
        end
    end

    function updateTitle()
        % Update title display
        try
            if ~isempty(app_data.image_files)
                [~, name, ext] = fileparts(app_data.image_files{app_data.current_img_idx});
                title_str = sprintf('Time-lapse - %s%s (%d/%d)', name, ext, ...
                                  app_data.current_img_idx, app_data.total_frames);
            else
                title_str = sprintf('Time-lapse - Frame %d/%d', ...
                                  app_data.current_img_idx, app_data.total_frames);
            end
            
            if ishandle(app_data.main_axes)
                title(app_data.main_axes, title_str, 'FontSize', 14, 'FontWeight', 'bold');
            end
        catch ME
            handleError(ME, 'Error occurred while updating title');
        end
    end

    function updateInfoDisplay()
        % Update information display
        try
            if ishandle(app_data.info_text)
                set(app_data.info_text, 'String', getImageInfo());
            end
        catch ME
            handleError(ME, 'Error occurred while updating information display');
        end
    end

%% ==================== Callback Functions ====================
    function selectNewFolder(~, ~)
        % Re-select folder callback function
        try
            % Stop current playback
            if app_data.is_playing
                stopPlayback();
            end
            
            [new_image_data, new_image_files] = selectFolderAndLoadImages();
            
            % Update application data
            app_data.image_data = new_image_data;
            app_data.image_files = new_image_files;
            app_data.folder_mode = true;
            app_data.current_img_idx = 1;
            app_data.total_frames = length(new_image_data);
            
            % Update slider range
            if ishandle(app_data.frame_slider)
                slider_step = calculateSliderStep();
                set(app_data.frame_slider, 'Min', 1, 'Max', app_data.total_frames, ...
                    'Value', 1, 'SliderStep', slider_step);
            end
            
            % Update display
            updateDisplay();
            
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                handleError(ME, 'Error occurred while re-selecting folder');
            end
        end
    end

    function frameSliderCallback(src, ~)
        % Frame selection slider callback function
        try
            new_idx = round(get(src, 'Value'));
            updateCurrentFrame(new_idx);
        catch ME
            handleError(ME, 'Error occurred during slider operation');
        end
    end

    function prevFrameCallback(~, ~)
        % Previous frame callback function
        try
            if app_data.current_img_idx > 1
                updateCurrentFrame(app_data.current_img_idx - 1);
            end
        catch ME
            handleError(ME, 'Error occurred while switching to previous frame');
        end
    end

    function nextFrameCallback(~, ~)
        % Next frame callback function
        try
            if app_data.current_img_idx < app_data.total_frames
                updateCurrentFrame(app_data.current_img_idx + 1);
            end
        catch ME
            handleError(ME, 'Error occurred while switching to next frame');
        end
    end

    function playCallback(~, ~)
        % Play callback function
        try
            if app_data.is_playing
                return;
            end
            
            app_data.is_playing = true;
            updatePlaybackButtons();
            
            % Get playback speed
            fps = getPlaybackSpeed();
            
            % Create timer
            timer_period = max(0.001, 1/fps);
            app_data.animation_timer = timer(...
                'Period', timer_period, ...
                'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @animationStep);
            start(app_data.animation_timer);
            
        catch ME
            handleError(ME, 'Error occurred while starting playback');
        end
    end

    function pauseCallback(~, ~)
        % Pause callback function
        try
            stopPlayback();
        catch ME
            handleError(ME, 'Error occurred while pausing playback');
        end
    end

    function stopCallback(~, ~)
        % Stop callback function
        try
            stopPlayback();
            updateCurrentFrame(1); % Return to first frame
        catch ME
            handleError(ME, 'Error occurred while stopping playback');
        end
    end

    function speedCallback(src, ~)
        % Speed control callback function
        try
            new_fps = str2double(get(src, 'String'));
            if isnan(new_fps) || new_fps <= 0
                set(src, 'String', '2');
            elseif new_fps > 1000
                set(src, 'String', '1000');
                msgbox('Maximum speed is 1000 fps', 'Speed Limit', 'help');
            end
        catch ME
            handleError(ME, 'Error occurred while setting playback speed');
        end
    end

    function animationStep(~, ~)
        % Animation step function
        try
            if ~ishandle(app_data.fig_handle)
                return;
            end
            
            next_idx = app_data.current_img_idx + 1;
            if next_idx > app_data.total_frames
                if ishandle(app_data.loop_checkbox) && get(app_data.loop_checkbox, 'Value')
                    next_idx = 1;
                else
                    pauseCallback();
                    return;
                end
            end
            
            updateCurrentFrame(next_idx);
            
        catch ME
            handleError(ME, 'Error occurred during animation playback');
        end
    end

    function exportGIF(~, ~)
        % Export GIF callback function
        try
            [filename, pathname] = uiputfile(...
                {'*.gif', 'GIF files (*.gif)'}, ...
                'Export GIF Animation');
            
            if isequal(filename, 0)
                return;
            end
            
            % Get playback speed
            fps = getPlaybackSpeed();
            delay_time = 1/fps;
            
            % Create progress dialog
            h_wait = waitbar(0, 'Exporting GIF animation...');
            
            try
                full_path = fullfile(pathname, filename);
                
                for i = 1:app_data.total_frames
                    % Convert to indexed image
                    [indexed_img, colormap_img] = rgb2ind(app_data.image_data{i}, 256);
                    
                    if i == 1
                        imwrite(indexed_img, colormap_img, full_path, 'gif', ...
                               'LoopCount', inf, 'DelayTime', delay_time);
                    else
                        imwrite(indexed_img, colormap_img, full_path, 'gif', ...
                               'WriteMode', 'append', 'DelayTime', delay_time);
                    end
                    
                    waitbar(i/app_data.total_frames, h_wait, ...
                           sprintf('Exporting GIF... (%d/%d)', i, app_data.total_frames));
                end
                
                close(h_wait);
                msgbox('GIF animation exported successfully!', 'Success', 'help');
                
            catch ME
                close(h_wait);
                handleError(ME, 'Export GIF failed');
            end
            
        catch ME
            handleError(ME, 'Error occurred while exporting GIF');
        end
    end

    function closeApplication(~, ~)
        % Close application
        try
            % Stop playback and clean up timer
            if app_data.is_playing
                stopPlayback();
            end
            
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
    function stopPlayback()
        % Stop playback
        if isvalid(app_data.animation_timer)
            stop(app_data.animation_timer);
            delete(app_data.animation_timer);
            app_data.animation_timer = [];
        end
        
        app_data.is_playing = false;
        updatePlaybackButtons();
    end

    function updatePlaybackButtons()
        % Update playback control button states
        try
            if app_data.is_playing
                if ishandle(app_data.play_button)
                    set(app_data.play_button, 'Enable', 'off');
                end
                if ishandle(app_data.pause_button)
                    set(app_data.pause_button, 'Enable', 'on');
                end
                if ishandle(app_data.stop_button)
                    set(app_data.stop_button, 'Enable', 'on');
                end
            else
                if ishandle(app_data.play_button)
                    set(app_data.play_button, 'Enable', 'on');
                end
                if ishandle(app_data.pause_button)
                    set(app_data.pause_button, 'Enable', 'off');
                end
                if ishandle(app_data.stop_button)
                    set(app_data.stop_button, 'Enable', 'off');
                end
            end
        catch ME
            handleError(ME, 'Error occurred while updating button states');
        end
    end

    function fps = getPlaybackSpeed()
        % Get playback speed
        try
            if ishandle(app_data.speed_edit)
                fps = str2double(get(app_data.speed_edit, 'String'));
                if isnan(fps) || fps <= 0
                    fps = 2;
                    set(app_data.speed_edit, 'String', '2');
                elseif fps > 1000
                    fps = 1000;
                    set(app_data.speed_edit, 'String', '1000');
                end
            else
                fps = 2;
            end
        catch ME
            fps = 2;
            handleError(ME, 'Error occurred while getting playback speed');
        end
    end

    function info_str = getImageInfo()
        % Get image information
        try
            if app_data.current_img_idx <= length(app_data.image_data)
                img = app_data.image_data{app_data.current_img_idx};
                [h, w, c] = size(img);
                info_str = sprintf('Image Info: %dx%d pixels, %d channels\nCurrent Time: %s', ...
                                  w, h, c, datestr(now, 'yyyy-mm-dd HH:MM:SS'));
            else
                info_str = 'No image data available';
            end
        catch ME
            info_str = 'Error getting image info';
            handleError(ME, 'Error occurred while getting image information');
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
        fprintf('Error in timelapseAnimation: %s\n', error_msg);
    end

end