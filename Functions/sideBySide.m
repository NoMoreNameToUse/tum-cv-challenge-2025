function varargout = sideBySideDisplay(varargin)
% SIDEBYSIDEDISPLAY - Side-by-side image comparison display tool
% 
% Usage:
%   sideBySideDisplay()                    % Standalone mode, folder selection dialog
%   sideBySideDisplay(img1, img2)          % Direct input of two original images
%   sideBySideDisplay(img1, img2, titles)  % Input images and titles
%   fig_handle = sideBySideDisplay(...)    % Return figure handle
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
    
    % Update application data
    app_data.current_img1 = img1;
    app_data.current_img2 = img2;
    app_data.current_titles = titles;
    app_data.folder_mode = folder_mode;
    
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
    handleError(ME, 'Error occurred during image comparison display initialization');
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
        
        % UI component handles
        data.fig_handle = [];
        data.main_axes = [];
        data.popup1 = [];
        data.popup2 = [];
        data.info_text = [];
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

%% ==================== User Interface Creation ====================
    function createUserInterface()
        % Create main window
        createMainWindow();
        
        % Create control panel
        createControlPanel();
        
        % Create image display area
        createImageDisplayArea();
        
        % If folder mode, create image selection controls
        if app_data.folder_mode
            createImageSelectionControls();
        end
    end

    function createMainWindow()
        % Create main window
        app_data.fig_handle = figure(...
            'Name', 'Side by Side - Original Images Comparison', ...
            'NumberTitle', 'off', ...
            'Position', [100, 100, 1400, 800], ...
            'Color', 'white', ...
            'MenuBar', 'none', ...
            'ToolBar', 'none', ...
            'CloseRequestFcn', @closeApplication);
    end

    function createImageDisplayArea()
        % Create image display area
        subplot_pos = [0.05, 0.2, 0.9, 0.75]; % [left, bottom, width, height]
        app_data.main_axes = subplot('Position', subplot_pos);
    end

    function createControlPanel()
        % Create control panel
        panel_height = 0.15;
        control_y = 0.02;
        button_width = 0.12;
        button_height = 0.05;
        spacing = 0.01;
        
        % Button position calculation
        current_x = 0.02;
        
        % Re-select folder button
        app_data.folder_button = uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Select New Folder', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y+0.08, button_width, button_height], ...
            'FontSize', 10, ...
            'Callback', @selectNewFolder);
        current_x = current_x + button_width + spacing;
        
        % Save button
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Save as JPG', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y+0.08, button_width, button_height], ...
            'FontSize', 10, ...
            'Callback', @saveComparisonJPG);
        current_x = current_x + button_width + spacing;
        
        % Reset view button
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Reset View', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y+0.08, 0.1, button_height], ...
            'FontSize', 10, ...
            'Callback', @resetView);
        current_x = current_x + 0.1 + spacing;
        
        % Zoom tool button
        uicontrol(...
            'Style', 'pushbutton', ...
            'String', 'Zoom Tool', ...
            'Units', 'normalized', ...
            'Position', [current_x, control_y+0.08, 0.1, button_height], ...
            'FontSize', 10, ...
            'Callback', @enableZoom);
        
        % Image information display area
        app_data.info_text = uicontrol(...
            'Style', 'text', ...
            'String', '', ...
            'Units', 'normalized', ...
            'Position', [0.02, control_y, 0.7, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
    end

    function createImageSelectionControls()
        % Create image selection controls
        control_y = 0.02;
        
        % Left image selection label
        uicontrol(...
            'Style', 'text', ...
            'String', 'Left Image:', ...
            'Units', 'normalized', ...
            'Position', [0.02, control_y+0.04, 0.08, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
        
        % Left image selection dropdown
        app_data.popup1 = uicontrol(...
            'Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [0.11, control_y+0.04, 0.25, 0.03], ...
            'FontSize', 9, ...
            'Callback', @updateLeftImage);
        
        % Right image selection label
        uicontrol(...
            'Style', 'text', ...
            'String', 'Right Image:', ...
            'Units', 'normalized', ...
            'Position', [0.38, control_y+0.04, 0.08, 0.03], ...
            'FontSize', 10, ...
            'BackgroundColor', 'white', ...
            'HorizontalAlignment', 'left');
        
        % Right image selection dropdown
        app_data.popup2 = uicontrol(...
            'Style', 'popupmenu', ...
            'String', app_data.display_names, ...
            'Value', min(2, length(app_data.display_names)), ...
            'Units', 'normalized', ...
            'Position', [0.47, control_y+0.04, 0.25, 0.03], ...
            'FontSize', 9, ...
            'Callback', @updateRightImage);
    end

%% ==================== Display Update Functions ====================
    function updateDisplay()
        % Update image display
        try
            % Create side-by-side display image
            combined_img = [app_data.current_img1, app_data.current_img2];
            
            % Display merged image
            imshow(combined_img, 'Parent', app_data.main_axes);
            
            % Add dividing line
            hold(app_data.main_axes, 'on');
            [h, w, ~] = size(app_data.current_img1);
            line(app_data.main_axes, [w, w], [1, h], 'Color', 'red', 'LineWidth', 3);
            hold(app_data.main_axes, 'off');
            
            % Add title
            title(app_data.main_axes, ...
                sprintf('Original Images Comparison: %s  |  %s', ...
                app_data.current_titles{1}, app_data.current_titles{2}), ...
                'FontSize', 14, 'FontWeight', 'bold', 'Color', 'black');
            
            % Set axis properties
            axis(app_data.main_axes, 'image');
            axis(app_data.main_axes, 'off');
            
            % Update image information
            updateImageInfo();
            
        catch ME
            handleError(ME, 'Error occurred while updating image display');
        end
    end

    function updateImageInfo()
        % Update image information display
        try
            img1_info = sprintf('Left: %dx%d', size(app_data.current_img1, 2), size(app_data.current_img1, 1));
            img2_info = sprintf('Right: %dx%d', size(app_data.current_img2, 2), size(app_data.current_img2, 1));
            info_str = sprintf('%s    |    %s', img1_info, img2_info);
            
            if ishandle(app_data.info_text)
                set(app_data.info_text, 'String', info_str);
            end
        catch ME
            handleError(ME, 'Error occurred while updating image information');
        end
    end

%% ==================== Callback Functions ====================
    function selectNewFolder(~, ~)
        % Re-select folder callback function
        try
            [new_img1, new_img2, new_titles] = selectFolderAndLoadImages();
            
            % Update application data
            app_data.current_img1 = new_img1;
            app_data.current_img2 = new_img2;
            app_data.current_titles = new_titles;
            app_data.folder_mode = true;
            
            % Update dropdown menus
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
            
        catch ME
            if ~strcmp(ME.message, 'User cancelled folder selection')
                handleError(ME, 'Error occurred while re-selecting folder');
            end
        end
    end

    function updateLeftImage(src, ~)
        % Update left image
        try
            if ~isempty(app_data.image_files)
                selected_idx = get(src, 'Value');
                app_data.current_img1 = imread(app_data.image_files{selected_idx});
                app_data.current_titles{1} = app_data.display_names{selected_idx};
                updateDisplay();
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
                app_data.current_img2 = imread(app_data.image_files{selected_idx});
                app_data.current_titles{2} = app_data.display_names{selected_idx};
                updateDisplay();
            end
        catch ME
            handleError(ME, 'Error occurred while updating right image');
        end
    end

    function saveComparisonJPG(~, ~)
        % Save comparison image as JPG format
        try
            % Create current comparison image
            combined_img = [app_data.current_img1, app_data.current_img2];
            
            % Show save dialog
            [filename, pathname] = uiputfile(...
                {'*.jpg', 'JPEG files (*.jpg)'}, ...
                'Save Side by Side Comparison as JPG');
            
            if ~isequal(filename, 0)
                % Ensure file extension is .jpg
                [~, name, ext] = fileparts(filename);
                if ~strcmpi(ext, '.jpg')
                    filename = [name, '.jpg'];
                end
                
                % Save image
                imwrite(combined_img, fullfile(pathname, filename), 'jpg', 'Quality', 95);
                msgbox('Image successfully saved as JPG format!', 'Success', 'help');
            end
            
        catch ME
            handleError(ME, 'Error occurred while saving image');
        end
    end

    function resetView(~, ~)
        % Reset view
        try
            if ishandle(app_data.main_axes)
                axis(app_data.main_axes, 'image');
                axis(app_data.main_axes, 'tight');
            end
            
            if ishandle(app_data.fig_handle)
                zoom(app_data.fig_handle, 'off');
                pan(app_data.fig_handle, 'off');
            end
            
            % Redisplay
            updateDisplay();
            
        catch ME
            handleError(ME, 'Error occurred while resetting view');
        end
    end

    function enableZoom(~, ~)
        % Enable zoom tool
        try
            if ishandle(app_data.fig_handle)
                zoom(app_data.fig_handle, 'on');
            end
        catch ME
            handleError(ME, 'Error occurred while enabling zoom tool');
        end
    end

    function closeApplication(~, ~)
        % Close application
        try
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
        fprintf('Error in sideBySideDisplay: %s\n', error_msg);
    end

end