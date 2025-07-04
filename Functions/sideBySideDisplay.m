function varargout = sideBySideDisplay(varargin)
% SIDEBYSIDEDISPLAY - Synchronized side-by-side image comparison tool
%
% ==================================================================================
% Function Description:
%   Display two images side by side with SYNCHRONIZED zoom and pan operations
%
% ==================================================================================
% Key Features:
%   - Synchronized zoom: Zoom on left/right image, the other follows automatically
%   - Synchronized pan: Pan on one side, the other side moves accordingly  
%   - Coordinate mapping: Accurate position correspondence between images
%   - Independent or linked view modes
%
% ==================================================================================
% Input Parameters:
%   1. sideBySideDisplay()
%      - No parameter call, popup folder selection dialog
%      - Automatically load image sequence and perform preprocessing (registration + cropping)
%      - Select the first two images for side-by-side comparison
%
%   2. sideBySideDisplay(img1, img2)
%      - img1, img2: Image data (matrix) or image file path (string)
%      - Directly compare two specified images without preprocessing
%      - Default titles are 'Image 1', 'Image 2'
%
%   3. sideBySideDisplay(img1, img2, titles)
%      - img1, img2: Same as above
%      - titles: Image title cell array, e.g., {'Original', 'Processed'}
%      - Custom image title display
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
%   sideBySideDisplay();  % Popup folder selection, automatic preprocessing
%
%   % Example 2: Direct image file path input
%   sideBySideDisplay('image1.jpg', 'image2.jpg');
%
%   % Example 3: Direct image data input
%   img1 = imread('before.png');
%   img2 = imread('after.png');
%   sideBySideDisplay(img1, img2);
%
%   % Example 4: With custom titles
%   titles = {'Before Processing', 'After Processing'};
%   fig_handle = sideBySideDisplay(img1, img2, titles);
%
% ==================================================================================

% Persistent application data structure
persistent app_data

%% ================== Main Function Entry Point ==================
if isempty(app_data)
    % Initialize application data structure
    app_data = struct('folder_mode', false, 'image_files', {{}}, 'display_names', {{}}, ...
                     'processed_imgs', {{}}, 'metas', [], 'sync_enabled', true, ...
                     'updating_view', false);
end

% Parse input parameters and determine working mode
[img1, img2, titles, folder_mode] = parseInputs(varargin{:});

% Update global application data
app_data.current_img1 = img1;
app_data.current_img2 = img2;
app_data.current_titles = titles;
app_data.folder_mode = folder_mode;

% Calculate scale factors for coordinate mapping
app_data.scale_x = size(img2, 2) / size(img1, 2);  % Width scale factor
app_data.scale_y = size(img2, 1) / size(img1, 1);  % Height scale factor

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
                error('sideBySideDisplay:InvalidArguments', ...
                      'Invalid input arguments. Supports 0, 2, or 3 parameters. Please check help documentation.');
        end
    end

%% ================== Folder Loading and Preprocessing Workflow ==================
    function [img1, img2, titles] = loadAndProcessFromFolder()
        % User selects folder containing image sequence
        folder_path = uigetdir('', 'Select folder containing image sequence');
        if isequal(folder_path, 0)
            error('sideBySideDisplay:UserCancelled', 'User cancelled folder selection');
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
        % Create friendly display names based on metadata
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
        % Unified image loading function
        if ischar(img_input) || isstring(img_input)
            % Load image from file
            img_data = im2double(imread(img_input));
        else
            % Use image data directly, convert to double format
            img_data = im2double(img_input);
        end
    end

%% ================== Graphical User Interface Creation ==================
    function createGUI()
        % Create main window and all interface components
        
        % Create main window
        app_data.fig_handle = figure('Name', 'Synchronized Side-by-Side Image Comparison Tool', ...
            'NumberTitle', 'off', 'Position', [100, 100, 1400, 700], ...
            'Color', 'white', 'MenuBar', 'none', 'ToolBar', 'none', ...
            'CloseRequestFcn', @(~,~) delete(gcf));
        
        % Create separate axes for left and right images
        app_data.left_axes = axes('Position', [0.05, 0.25, 0.42, 0.7]);
        app_data.right_axes = axes('Position', [0.53, 0.25, 0.42, 0.7]);
        
        % Setup synchronized zoom and pan
        setupSynchronizedView();
        
        % Create function button area
        createControlButtons();
        
        % Create information display area
        app_data.info_text = uicontrol('Style', 'text', 'String', '', ...
            'Units', 'normalized', 'Position', [0.02, 0.02, 0.7, 0.03], ...
            'BackgroundColor', 'white', 'HorizontalAlignment', 'left');
        
        % Folder mode requires image selectors
        if app_data.folder_mode
            createImageSelectors();
        end
    end

%% ================== Synchronized View Setup ==================
    function setupSynchronizedView()
        % Setup event listeners for synchronized zoom and pan operations
        
        % Initialize zoom and pan objects for the figure
        app_data.zoom_obj = zoom(app_data.fig_handle);
        app_data.pan_obj = pan(app_data.fig_handle);
        
        % Set initial zoom and pan state to off
        set(app_data.zoom_obj, 'Enable', 'off');
        set(app_data.pan_obj, 'Enable', 'off');
        
        % Add event listeners for left axes (zoom and pan)
        addlistener(app_data.left_axes, 'XLim', 'PostSet', @(src,evt) syncFromLeft('XLim'));
        addlistener(app_data.left_axes, 'YLim', 'PostSet', @(src,evt) syncFromLeft('YLim'));
        
        % Add event listeners for right axes (zoom and pan)
        addlistener(app_data.right_axes, 'XLim', 'PostSet', @(src,evt) syncFromRight('XLim'));
        addlistener(app_data.right_axes, 'YLim', 'PostSet', @(src,evt) syncFromRight('YLim'));
    end

%% ================== Synchronization Event Handlers ==================
    function syncFromLeft(property)
        % Synchronize right axes when left axes changes
        if app_data.sync_enabled && ~app_data.updating_view
            app_data.updating_view = true;
            
            try
                if strcmp(property, 'XLim')
                    % Synchronize X axis (horizontal position and zoom)
                    left_xlim = get(app_data.left_axes, 'XLim');
                    right_xlim = left_xlim * app_data.scale_x;
                    set(app_data.right_axes, 'XLim', right_xlim);
                    
                elseif strcmp(property, 'YLim')
                    % Synchronize Y axis (vertical position and zoom)
                    left_ylim = get(app_data.left_axes, 'YLim');
                    right_ylim = left_ylim * app_data.scale_y;
                    set(app_data.right_axes, 'YLim', right_ylim);
                end
            catch ME

            end
            
            app_data.updating_view = false;
        end
    end

    function syncFromRight(property)
        % Synchronize left axes when right axes changes
        if app_data.sync_enabled && ~app_data.updating_view
            app_data.updating_view = true;
            
            try
                if strcmp(property, 'XLim')
                    % Synchronize X axis (horizontal position and zoom)
                    right_xlim = get(app_data.right_axes, 'XLim');
                    left_xlim = right_xlim / app_data.scale_x;
                    set(app_data.left_axes, 'XLim', left_xlim);
                    
                elseif strcmp(property, 'YLim')
                    % Synchronize Y axis (vertical position and zoom)
                    right_ylim = get(app_data.right_axes, 'YLim');
                    left_ylim = right_ylim / app_data.scale_y;
                    set(app_data.left_axes, 'YLim', left_ylim);
                end
            catch ME

            end
            
            app_data.updating_view = false;
        end
    end

%% ================== Function Button Area ==================
    function createControlButtons()
        % Create unified layout for all function buttons
        
        % Button configuration: {display text, position [x,y,w,h], callback function}
        buttons = {
            {'Reselect Folder', [0.02, 0.15, 0.12, 0.05], @selectNewFolder};
            {'Save as JPG', [0.15, 0.15, 0.1, 0.05], @saveImage};
            {'Reset View', [0.26, 0.15, 0.08, 0.05], @resetView};
            {'Zoom Tool', [0.35, 0.15, 0.08, 0.05], @enableZoom};
            {'Pan Tool', [0.44, 0.15, 0.08, 0.05], @enablePan};
            {'Toggle Sync', [0.53, 0.15, 0.1, 0.05], @toggleSync};
        };
        
        % Batch create buttons
        for i = 1:length(buttons)
            if i == 6  % Toggle Sync button
                app_data.sync_button = uicontrol('Style', 'pushbutton', 'String', buttons{i}{1}, ...
                    'Units', 'normalized', 'Position', buttons{i}{2}, ...
                    'Callback', buttons{i}{3}, 'BackgroundColor', [0.7, 1.0, 0.7]);
            else
                uicontrol('Style', 'pushbutton', 'String', buttons{i}{1}, ...
                    'Units', 'normalized', 'Position', buttons{i}{2}, ...
                    'Callback', buttons{i}{3});
            end
        end
        
        % Add instruction text
        uicontrol('Style', 'text', ...
            'String', 'Instructions: Use Zoom/Pan tools to navigate. Synchronization keeps both images aligned.', ...
            'Units', 'normalized', 'Position', [0.65, 0.15, 0.33, 0.05], ...
            'BackgroundColor', 'white', 'FontSize', 9, 'FontWeight', 'bold', ...
            'ForegroundColor', [0.2, 0.4, 0.8], 'HorizontalAlignment', 'left');
    end

%% ================== Image Selectors (Folder Mode) ==================
    function createImageSelectors()
        % Create image selection dropdown menus
        
        % Left image selector
        uicontrol('Style', 'text', 'String', 'Left Image:', ...
            'Units', 'normalized', 'Position', [0.02, 0.1, 0.08, 0.03], ...
            'BackgroundColor', 'white');
        
        app_data.popup1 = uicontrol('Style', 'popupmenu', ...
            'String', app_data.display_names, 'Value', 1, ...
            'Units', 'normalized', 'Position', [0.11, 0.1, 0.25, 0.03], ...
            'Callback', @(src,~) updateImage(1, src));
        
        % Right image selector
        uicontrol('Style', 'text', 'String', 'Right Image:', ...
            'Units', 'normalized', 'Position', [0.38, 0.1, 0.08, 0.03], ...
            'BackgroundColor', 'white');
        
        app_data.popup2 = uicontrol('Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', min(2, length(app_data.display_names)), ...
            'Units', 'normalized', 'Position', [0.47, 0.1, 0.25, 0.03], ...
            'Callback', @(src,~) updateImage(2, src));
    end

%% ================== Display Update Function ==================
    function updateDisplay()
        % Update main image display content with separate axes
        
        % Convert to uint8 format for display
        img1_display = im2uint8(app_data.current_img1);
        img2_display = im2uint8(app_data.current_img2);
        
        % Disable synchronization during image update
        app_data.updating_view = true;
        
        % Display left image
        imshow(img1_display, 'Parent', app_data.left_axes);
        title(app_data.left_axes, app_data.current_titles{1}, 'FontSize', 11, 'FontWeight', 'bold');
        
        % Display right image  
        imshow(img2_display, 'Parent', app_data.right_axes);
        title(app_data.right_axes, app_data.current_titles{2}, 'FontSize', 11, 'FontWeight', 'bold');
        
        % Add preprocessing indicator to titles if in folder mode
        if app_data.folder_mode
            title(app_data.left_axes, ['[Registered & Cropped] ' app_data.current_titles{1}], ...
                'FontSize', 10, 'FontWeight', 'bold');
            title(app_data.right_axes, ['[Registered & Cropped] ' app_data.current_titles{2}], ...
                'FontSize', 10, 'FontWeight', 'bold');
        end
        
        % Re-enable synchronization
        app_data.updating_view = false;
        
        % Update image information display
        updateImageInfo();
        
        % Update scale factors for new images
        app_data.scale_x = size(img2_display, 2) / size(img1_display, 2);
        app_data.scale_y = size(img2_display, 1) / size(img1_display, 1);
    end

%% ================== Information Display Update ==================
    function updateImageInfo()
        % Update bottom image information text
        if ishandle(app_data.info_text)
            info_str = sprintf('Left: %dx%d  |  Right: %dx%d  |  Scale: %.3fx, %.3fy', ...
                size(app_data.current_img1, 2), size(app_data.current_img1, 1), ...
                size(app_data.current_img2, 2), size(app_data.current_img2, 1), ...
                app_data.scale_x, app_data.scale_y);
            
            if app_data.sync_enabled
                info_str = [info_str ' | Sync: ON'];
            else
                info_str = [info_str ' | Sync: OFF'];
            end
            
            if app_data.folder_mode
                info_str = [info_str ' | Images automatically registered and cropped'];
            end
            set(app_data.info_text, 'String', info_str);
        end
    end

%% ================== Callback Function Collection ==================

    % Reselect folder callback
    function selectNewFolder(~, ~)
        try
            [new_img1, new_img2, new_titles] = loadAndProcessFromFolder();
            
            % Update application data
            app_data.current_img1 = new_img1;
            app_data.current_img2 = new_img2;
            app_data.current_titles = new_titles;
            app_data.folder_mode = true;
            
            % Rebuild image selectors
            if ishandle(app_data.popup1), delete(app_data.popup1); end
            if ishandle(app_data.popup2), delete(app_data.popup2); end
            createImageSelectors();
            
            % Update display
            updateDisplay();
            
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                errordlg(['Processing error: ' ME.message], 'Error');
            end
        end
    end

    % Image selection callback (folder mode)
    function updateImage(side, src)
        idx = get(src, 'Value');
        
        if side == 1
            % Update left image
            app_data.current_img1 = app_data.processed_imgs{idx};
            app_data.current_titles{1} = app_data.display_names{idx};
        else
            % Update right image
            app_data.current_img2 = app_data.processed_imgs{idx};
            app_data.current_titles{2} = app_data.display_names{idx};
        end
        
        % Refresh display
        updateDisplay();
    end

    % Save image callback
    function saveImage(~, ~)
        % Save current side-by-side comparison result as JPG file
        
        % Create composite image for saving
        img1_display = im2uint8(app_data.current_img1);
        img2_display = im2uint8(app_data.current_img2);
        combined_img = [img1_display, img2_display];
        
        % File save dialog
        [filename, pathname] = uiputfile('*.jpg', 'Save Side-by-Side Comparison');
        if filename ~= 0
            % Ensure file extension is .jpg
            [~, name, ~] = fileparts(filename);
            filename = [name, '.jpg'];
            
            % Save image
            imwrite(combined_img, fullfile(pathname, filename), 'jpg');
            msgbox('Image saved successfully!', 'Success');
        end
    end

    % Reset view callback
    function resetView(~, ~)
        % Reset both image displays to original state
        app_data.updating_view = true;
        
        % Turn off zoom and pan modes
        set(app_data.zoom_obj, 'Enable', 'off');
        set(app_data.pan_obj, 'Enable', 'off');
        
        % Reset both axes properties
        axis(app_data.left_axes, 'image');
        axis(app_data.right_axes, 'image');
        
        app_data.updating_view = false;
        
        % Redisplay images
        updateDisplay();
    end

    % Enable zoom tool callback
    function enableZoom(~, ~)
        % Enable zoom mode for both axes
        set(app_data.pan_obj, 'Enable', 'off'); % Turn off pan first
        set(app_data.zoom_obj, 'Enable', 'on'); % Enable zoom
    end

    % Enable pan tool callback  
    function enablePan(~, ~)
        % Enable pan mode for both axes
        set(app_data.zoom_obj, 'Enable', 'off'); % Turn off zoom first
        set(app_data.pan_obj, 'Enable', 'on'); % Enable pan
    end

    % Toggle synchronization callback
    function toggleSync(~, ~)
        % Toggle synchronization on/off
        app_data.sync_enabled = ~app_data.sync_enabled;
        
        % Update button appearance
        if app_data.sync_enabled
            set(app_data.sync_button, 'String', 'Sync: ON', 'BackgroundColor', [0.7, 1.0, 0.7]);
        else
            set(app_data.sync_button, 'String', 'Sync: OFF', 'BackgroundColor', [1.0, 0.7, 0.7]);
        end
        
        % Update info display
        updateImageInfo();
    end

end
