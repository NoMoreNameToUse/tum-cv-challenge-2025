function varargout = timelapseAnimation(varargin)
% TIMELAPSEANIMATION - Time series animation tool (with image preprocessing)
%
% ==================================================================================
% Function Description:
%   Play image sequences to show time-lapse effects, suitable for remote sensing imagery, time-lapse photography, etc.
%
% ==================================================================================
% Input Parameters:
%   1. timelapseAnimation()
%      - No parameter call, popup folder selection dialog
%      - Automatically load image sequence and perform preprocessing (registration + cropping)
%      - Create complete time series animation
%
%   2. timelapseAnimation(image_folder)
%      - image_folder: Folder path containing image sequence (string)
%      - Directly load images from specified folder without preprocessing
%      - Create animation sequence sorted by filename
%
%   3. timelapseAnimation(image_list)
%      - image_list: Image file path list (cell array)
%      - Load image files in specified order
%      - Suitable for custom image sequence order
%
%   4. timelapseAnimation(image_cell_array)
%      - image_cell_array: Image data array (cell array, each element is image matrix)
%      - Directly use loaded image data
%      - Suitable for image sequences in memory
%
%
% ==================================================================================
% External Functions:
%   1. loadImageSequence.m        - Load image sequence, extract metadata
%   2. preprocessImageSequence.m  - Image registration (alignment) processing  
%   3. cropToCommonRegion.m       - Crop to common visible region
%
% ==================================================================================
% Usage Examples:
%   % Example 1: Folder selection mode
%   timelapseAnimation();  % Popup folder selection, automatic preprocessing
%
%   % Example 2: Specify folder path
%   folder_path = 'C:\Images\TimeSeries\';
%   timelapseAnimation(folder_path);
%
%   % Example 3: Use image file list
%   image_files = {'img001.jpg', 'img002.jpg', 'img003.jpg'};
%   timelapseAnimation(image_files);
%
%   % Example 4: Use image data array
%   imgs = {imread('1.jpg'), imread('2.jpg'), imread('3.jpg')};
%   fig_handle = timelapseAnimation(imgs);
%
% ==================================================================================

% Persistent application data structure
persistent app_data

%% ================== Main Function Entry Point ==================
if isempty(app_data)
    % Initialize application data structure
    app_data = struct('folder_mode', false, 'image_data', {{}}, 'image_files', {{}}, ...
                     'processed_imgs', {{}}, 'metas', [], 'current_img_idx', 1, ...
                     'total_frames', 0, 'is_playing', false, 'animation_timer', []);
end

% Parse input parameters and load data
[image_data, image_files, folder_mode] = parseInputs(varargin{:});

% Update global application data
app_data.image_data = image_data;
app_data.image_files = image_files;
app_data.folder_mode = folder_mode;
app_data.current_img_idx = 1;
app_data.total_frames = length(image_data);

% Create user interface and initial display
createGUI();
updateDisplay();

% Return figure handle
if nargout > 0
    varargout{1} = app_data.fig_handle;
end

%% ================== Input Parameter Parser ==================
    function [image_data, image_files, folder_mode] = parseInputs(varargin)
        % Determine loading mode based on input parameter type
        switch nargin
            case 0
                % Mode 1: Folder selection + automatic preprocessing
                [image_data, image_files] = loadAndProcessFromFolder();
                folder_mode = true;
                
            case 1
                input_data = varargin{1};
                if ischar(input_data) || isstring(input_data)
                    % Mode 2: Input folder path
                    [image_data, image_files] = loadImagesFromFolder(input_data);
                elseif iscell(input_data)
                    if ischar(input_data{1}) || isstring(input_data{1})
                        % Mode 3: Input file path list
                        [image_data, image_files] = loadImagesFromFileList(input_data);
                    else
                        % Mode 4: Input image data array
                        image_data = input_data;
                        image_files = generateImageNames(length(image_data));
                    end
                else
                    error('timelapseAnimation:InvalidInput', 'Invalid input parameter format');
                end
                folder_mode = false;
                
            otherwise
                error('timelapseAnimation:InvalidArguments', 'Invalid number of input arguments');
        end
    end

%% ================== Folder Loading and Preprocessing Workflow ==================
    function [image_data, image_files] = loadAndProcessFromFolder()
        % User selects folder and executes complete preprocessing workflow
        
        folder_path = uigetdir(pwd, 'Select folder containing image sequence');
        if isequal(folder_path, 0)
            error('timelapseAnimation:UserCancelled', 'User cancelled folder selection');
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
            
            % Convert to uint8 format to optimize display performance
            image_data = cell(length(croppedImgs), 1);
            for i = 1:length(croppedImgs)
                image_data{i} = im2uint8(croppedImgs{i});
            end
            
            % Generate display filenames based on metadata
            image_files = cell(length(metas), 1);
            for i = 1:length(metas)
                if ~isnan(metas(i).year)
                    if ~isnan(metas(i).month)
                        image_files{i} = sprintf('%04d-%02d', metas(i).year, metas(i).month);
                    else
                        image_files{i} = sprintf('%04d', metas(i).year);
                    end
                else
                    image_files{i} = metas(i).name;
                end
            end
            
        catch ME
            if ishandle(h_wait)
                close(h_wait);
            end
            rethrow(ME);
        end
    end

%% ================== Image Loading Function Collection ==================

    % Load images from specified folder
    function [image_data, image_files] = loadImagesFromFolder(folder_path)
        image_files = scanImageFiles(folder_path);
        if isempty(image_files)
            error('timelapseAnimation:NoImages', 'No image files found in specified folder!');
        end
        image_data = loadImageDataFromFiles(image_files);
    end

    % Load images from file list
    function [image_data, image_files] = loadImagesFromFileList(file_list)
        image_files = file_list;
        image_data = loadImageDataFromFiles(image_files);
    end

    % Scan image files in folder
    function image_files = scanImageFiles(folder_path)
        % Supported image file extensions
        extensions = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff', '*.gif'};
        image_files = {};
        
        % Search files by extension one by one
        for i = 1:length(extensions)
            files = dir(fullfile(folder_path, extensions{i}));
            for j = 1:length(files)
                if ~files(j).isdir
                    image_files{end+1} = fullfile(folder_path, files(j).name);
                end
            end
        end
        
        % Remove duplicates and sort
        if ~isempty(image_files)
            image_files = unique(image_files);
            image_files = sort(image_files);
        end
    end

    % Load image data from file path list
    function image_data = loadImageDataFromFiles(image_files)
        image_data = cell(length(image_files), 1);
        for i = 1:length(image_files)
            try
                image_data{i} = imread(image_files{i});
            catch
                % Use placeholder image if a file fails to load
                if i > 1
                    image_data{i} = image_data{i-1}; % Copy previous frame
                else
                    image_data{i} = zeros(480, 640, 3, 'uint8'); % Black placeholder
                end
                warning('timelapseAnimation:ImageLoadFailed', ...
                        'Unable to load image: %s', image_files{i});
            end
        end
    end

    % Generate default image names
    function image_files = generateImageNames(num_images)
        image_files = cell(num_images, 1);
        for i = 1:num_images
            image_files{i} = sprintf('Image_%d', i);
        end
    end

%% ================== Graphical User Interface Creation ==================
    function createGUI()
        % Create main window and all interface components
        
        % Create main window
        app_data.fig_handle = figure('Name', 'Time Series Animation Tool (with Preprocessing)', ...
            'NumberTitle', 'off', 'Position', [100, 100, 1200, 800], ...
            'Color', 'white', 'MenuBar', 'none', 'ToolBar', 'none', ...
            'CloseRequestFcn', @closeApplication);
        
        % Create image display area
        app_data.main_axes = axes('Position', [0.05, 0.3, 0.9, 0.65], 'XTick', [], 'YTick', []);
        
        % Initial display of first image
        app_data.img_handle = imshow(app_data.image_data{1}, 'Parent', app_data.main_axes);
        updateTitle();
        
        % Create interface control components
        createPlaybackControls(); % Playback control area
        createControlButtons(); % Function button area
    end

%% ================== Playback Control Area ==================
    function createPlaybackControls()
        control_y = 0.18;
        
        % Frame selection slider
        slider_step = calculateSliderStep();
        app_data.frame_slider = uicontrol('Style', 'slider', ...
            'Min', 1, 'Max', app_data.total_frames, 'Value', 1, 'SliderStep', slider_step, ...
            'Units', 'normalized', 'Position', [0.05, control_y, 0.5, 0.03], ...
            'Callback', @(src,~) updateCurrentFrame(round(get(src, 'Value'))));
        
        % Current frame number display
        app_data.frame_text = uicontrol('Style', 'text', ...
            'String', sprintf('Frame: 1 / %d', app_data.total_frames), ...
            'Units', 'normalized', 'Position', [0.56, control_y-0.01, 0.08, 0.04], ...
            'FontSize', 10, 'BackgroundColor', 'white');
        
        % Frame navigation buttons
        frame_buttons = {
            {'◀', [0.65, control_y-0.01, 0.03, 0.04], @(~,~) prevFrame()};
            {'▶', [0.68, control_y-0.01, 0.03, 0.04], @(~,~) nextFrame()};
        };
        
        for i = 1:length(frame_buttons)
            uicontrol('Style', 'pushbutton', 'String', frame_buttons{i}{1}, ...
                'Units', 'normalized', 'Position', frame_buttons{i}{2}, ...
                'FontSize', 12, 'Callback', frame_buttons{i}{3});
        end
    end

%% ================== Function Button Area ==================
    function createControlButtons()
        control_y = 0.12;
        
        % Playback control button group
        createPlaybackButtons(control_y);
        
        % Speed control components
        createSpeedControls(control_y);
        
        % Main function buttons
        createMainButtons();
        
        % Information display area
        app_data.info_text = uicontrol('Style', 'text', 'String', getImageInfo(), ...
            'Units', 'normalized', 'Position', [0.05, 0.01, 0.5, 0.04], ...
            'FontSize', 9, 'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
    end

    % Create playback control buttons
    function createPlaybackButtons(control_y)
        % Play button
        app_data.play_button = uicontrol('Style', 'pushbutton', ...
            'String', 'Play', 'Units', 'normalized', ...
            'Position', [0.05, control_y, 0.06, 0.04], 'Callback', @playCallback);
        
        % Pause button
        app_data.pause_button = uicontrol('Style', 'pushbutton', ...
            'String', 'Pause', 'Units', 'normalized', ...
            'Position', [0.12, control_y, 0.06, 0.04], 'Enable', 'off', ...
            'Callback', @pauseCallback);
        
        % Stop button
        app_data.stop_button = uicontrol('Style', 'pushbutton', ...
            'String', 'Stop', 'Units', 'normalized', ...
            'Position', [0.19, control_y, 0.06, 0.04], 'Enable', 'off', ...
            'Callback', @stopCallback);
    end

    % Create speed control components
    function createSpeedControls(control_y)
        % Speed label
        uicontrol('Style', 'text', 'String', 'Speed (fps):', ...
            'Units', 'normalized', 'Position', [0.26, control_y+0.01, 0.08, 0.02], ...
            'BackgroundColor', 'white');
        
        % Speed input box
        app_data.speed_edit = uicontrol('Style', 'edit', 'String', '2', ...
            'Units', 'normalized', 'Position', [0.35, control_y+0.005, 0.04, 0.03], ...
            'Callback', @speedCallback);
        
        % Loop playback checkbox
        app_data.loop_checkbox = uicontrol('Style', 'checkbox', 'String', 'Loop Playback', ...
            'Units', 'normalized', 'Position', [0.4, control_y+0.01, 0.08, 0.02], ...
            'Value', 1, 'BackgroundColor', 'white');
    end

    % Create main function buttons
    function createMainButtons()
        function_buttons = {
            {'Reselect Folder', [0.05, 0.06, 0.12, 0.04], @selectNewFolder};
            {'Export GIF', [0.18, 0.06, 0.08, 0.04], @exportGIF};
        };
        
        for i = 1:length(function_buttons)
            if i == 1
                app_data.folder_button = uicontrol('Style', 'pushbutton', ...
                    'String', function_buttons{i}{1}, 'Units', 'normalized', ...
                    'Position', function_buttons{i}{2}, 'Callback', function_buttons{i}{3});
            else
                uicontrol('Style', 'pushbutton', 'String', function_buttons{i}{1}, ...
                    'Units', 'normalized', 'Position', function_buttons{i}{2}, ...
                    'Callback', function_buttons{i}{3});
            end
        end
    end

%% ================== Playback Control Logic ==================

    % Calculate slider step size
    function slider_step = calculateSliderStep()
        if app_data.total_frames > 1
            step1 = 1/(app_data.total_frames-1); % Single step size
            step2 = max(0.1, step1); % Page step size
            slider_step = [step1, step2];
        else
            slider_step = [1, 1];
        end
    end

    % Update current frame display
    function updateCurrentFrame(new_idx)
        % Boundary check
        if new_idx < 1 || new_idx > app_data.total_frames
            return;
        end
        
        app_data.current_img_idx = new_idx;
        
        % Update image display
        if ishandle(app_data.img_handle)
            set(app_data.img_handle, 'CData', app_data.image_data{app_data.current_img_idx});
        end
        
        % Update slider position
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
    end

    % Update title display
    function updateTitle()
        if ~isempty(app_data.image_files) && app_data.current_img_idx <= length(app_data.image_files)
            title_str = sprintf('Time Series Animation - %s (%d/%d)', ...
                app_data.image_files{app_data.current_img_idx}, ...
                app_data.current_img_idx, app_data.total_frames);
        else
            title_str = sprintf('Time Series Animation - Frame %d/%d', ...
                app_data.current_img_idx, app_data.total_frames);
        end
        
        if app_data.folder_mode
            title_str = [title_str ' [Registered and Cropped]'];
        end
        
        if ishandle(app_data.main_axes)
            title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
        end
    end

    % Update information display
    function updateInfoDisplay()
        if ishandle(app_data.info_text)
            set(app_data.info_text, 'String', getImageInfo());
        end
    end

    % Update display
    function updateDisplay()
        updateCurrentFrame(app_data.current_img_idx);
    end

%% ================== Callback Function Collection ==================

    % Reselect folder callback
    function selectNewFolder(~, ~)
        try
            % Stop current playback
            if app_data.is_playing
                stopPlayback();
            end
            
            [new_image_data, new_image_files] = loadAndProcessFromFolder();
            
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
            
            updateDisplay();
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                errordlg(['Processing error: ' ME.message], 'Error');
            end
        end
    end

    % Frame navigation callback functions
    function prevFrame()
        if app_data.current_img_idx > 1
            updateCurrentFrame(app_data.current_img_idx - 1);
        end
    end

    function nextFrame()
        if app_data.current_img_idx < app_data.total_frames
            updateCurrentFrame(app_data.current_img_idx + 1);
        end
    end

    % Playback control callback functions
    function playCallback(~, ~)
        if app_data.is_playing
            return;  % Already playing
        end
        
        app_data.is_playing = true;
        updatePlaybackButtons();
        
        % Create and start timer
        fps = getPlaybackSpeed();
        timer_period = max(0.001, 1/fps);
        app_data.animation_timer = timer('Period', timer_period, ...
            'ExecutionMode', 'fixedRate', 'TimerFcn', @animationStep);
        start(app_data.animation_timer);
    end

    function pauseCallback(~, ~)
        stopPlayback();
    end

    function stopCallback(~, ~)
        stopPlayback();
        updateCurrentFrame(1); % Return to first frame
    end

    % Speed setting callback
    function speedCallback(src, ~)
        new_fps = str2double(get(src, 'String'));
        if isnan(new_fps) || new_fps <= 0
            set(src, 'String', '2'); % Restore default value
        elseif new_fps > 1000
            set(src, 'String', '1000');
            msgbox('Maximum speed is 1000 fps', 'Speed Limit');
        end
    end

    % Animation step function (timer callback)
    function animationStep(~, ~)
        if ~ishandle(app_data.fig_handle)
            return;
        end
        
        next_idx = app_data.current_img_idx + 1;
        if next_idx > app_data.total_frames
            % Check if loop playback is enabled
            if ishandle(app_data.loop_checkbox) && get(app_data.loop_checkbox, 'Value')
                next_idx = 1; % Return to first frame
            else
                pauseCallback(); % Stop playback
                return;
            end
        end
        
        updateCurrentFrame(next_idx);
    end

    % GIF export callback
    function exportGIF(~, ~)
        [filename, pathname] = uiputfile('*.gif', 'Export GIF Animation');
        if filename == 0
            return;
        end
        
        [~, name, ~] = fileparts(filename);
        filename = [name, '.gif'];
        full_path = fullfile(pathname, filename);
        
        fps = getPlaybackSpeed();
        delay_time = 1/fps;
        
        h_wait = waitbar(0, 'Exporting GIF animation...');
        
        try
            for i = 1:app_data.total_frames
                % Convert to indexed color image
                [indexed_img, colormap_img] = rgb2ind(app_data.image_data{i}, 256);
                
                if i == 1
                    % Create GIF file
                    imwrite(indexed_img, colormap_img, full_path, 'gif', ...
                           'LoopCount', inf, 'DelayTime', delay_time);
                else
                    % Add subsequent frames
                    imwrite(indexed_img, colormap_img, full_path, 'gif', ...
                           'WriteMode', 'append', 'DelayTime', delay_time);
                end
                
                waitbar(i/app_data.total_frames, h_wait, ...
                       sprintf('Exporting GIF... (%d/%d)', i, app_data.total_frames));
            end
            
            close(h_wait);
            msgbox('GIF animation exported successfully!', 'Success');
        catch ME
            close(h_wait);
            errordlg(['GIF export failed: ' ME.message], 'Error');
        end
    end

    % Window close callback
    function closeApplication(~, ~)
        try
            % Stop playback and clean up resources
            if app_data.is_playing
                stopPlayback();
            end
            if ishandle(app_data.fig_handle)
                delete(app_data.fig_handle);
            end
            clear app_data;
        catch
            % Force close
            if ishandle(app_data.fig_handle)
                delete(app_data.fig_handle);
            end
        end
    end

%% ================== Utility Functions ==================

    % Stop playback
    function stopPlayback()
        if isvalid(app_data.animation_timer)
            stop(app_data.animation_timer);
            delete(app_data.animation_timer);
            app_data.animation_timer = [];
        end
        app_data.is_playing = false;
        updatePlaybackButtons();
    end

    % Update playback button states
    function updatePlaybackButtons()
        if app_data.is_playing
            if ishandle(app_data.play_button), set(app_data.play_button, 'Enable', 'off'); end
            if ishandle(app_data.pause_button), set(app_data.pause_button, 'Enable', 'on'); end
            if ishandle(app_data.stop_button), set(app_data.stop_button, 'Enable', 'on'); end
        else
            if ishandle(app_data.play_button), set(app_data.play_button, 'Enable', 'on'); end
            if ishandle(app_data.pause_button), set(app_data.pause_button, 'Enable', 'off'); end
            if ishandle(app_data.stop_button), set(app_data.stop_button, 'Enable', 'off'); end
        end
    end

    % Get playback speed
    function fps = getPlaybackSpeed()
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
    end

    % Get image information string
    function info_str = getImageInfo()
        if app_data.current_img_idx <= length(app_data.image_data)
            img = app_data.image_data{app_data.current_img_idx};
            [h, w, c] = size(img);
            info_str = sprintf('Image Info: %dx%d pixels, %d channels', w, h, c);
            if app_data.folder_mode
                info_str = [info_str ' | Images automatically registered and cropped'];
            end
        else
            info_str = 'No image data';
        end
    end

end
