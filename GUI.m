function change_detection_gui()
    % Global variables
    global imgs imgNames ax1 ax2 ax3 ax4 ax5;

    imgs = {};
    imgNames = {};

    % Create main window
    f = figure('Name', 'Surface Change Detection GUI - Folder Import + Auto Sorting', ...
               'Position', [50, 30, 1600, 850]);

    % Top title
    uicontrol('Style', 'text', 'String', 'Surface Change Detection', ...
        'FontSize', 22, 'FontWeight', 'bold', ...
        'ForegroundColor', 'blue', 'HorizontalAlignment', 'center', ...
        'Position', [600, 800, 400, 40]);

    % Upper image row: ax1, ax2, ax3
    ax1 = axes('Parent', f, 'Units', 'pixels', 'Position', [100, 460, 420, 340]);
    ax2 = axes('Parent', f, 'Units', 'pixels', 'Position', [590, 460, 420, 340]);
    ax3 = axes('Parent', f, 'Units', 'pixels', 'Position', [1080, 460, 420, 340]);

    % Lower image row: ax4 = difference map, ax5 = highlighted map
    ax4 = axes('Parent', f, 'Units', 'pixels', 'Position', [100, 70, 420, 340]);
    ax5 = axes('Parent', f, 'Units', 'pixels', 'Position', [590, 70, 420, 340]);

    set([ax1 ax2 ax3 ax4 ax5], 'Visible', 'off');

    % Button panel (below ax3, 3 columns x 3 rows)
    labels = { ...
        'Load Folder', 'Reset', 'Exit';
        'Show Difference', 'Show Highlighted', 'Play Animation';
        'Segment Change', 'Generate Report', ''
    };
    callbacks = { ...
        @loadImageFolder, @resetGUI, @(~,~) close(f); 
        @showDifference, @highlightChanges, @playAnimation;
        @segmentChangeRegion, @generateReport, []
    };

    startX = 1080; startY = 330;
    btnW = 120; btnH = 40; dx = 20; dy = 20;

    for r = 1:3
        for c = 1:3
            label = labels{r, c};
            if ~isempty(label)
                uicontrol(f, 'Style', 'pushbutton', 'String', label, ...
                    'Position', [startX + (c-1)*(btnW+dx), startY - (r-1)*(btnH+dy), btnW, btnH], ...
                    'FontSize', 11, 'Callback', callbacks{r, c});
            end
        end
    end

    % Dropdown menus to select images for difference
    uicontrol(f, 'Style', 'text', 'String', 'Image A:', ...
        'Position', [1050, 60, 70, 20], 'HorizontalAlignment', 'left');
    uicontrol(f, 'Style', 'popupmenu', 'String', {'1', '2', '3'}, ...
        'Position', [1120, 60, 50, 25], 'Tag', 'popupA');

    uicontrol(f, 'Style', 'text', 'String', 'Image B:', ...
        'Position', [1180, 60, 70, 20], 'HorizontalAlignment', 'left');
    uicontrol(f, 'Style', 'popupmenu', 'String', {'1', '2', '3'}, ...
        'Position', [1250, 60, 50, 25], 'Tag', 'popupB');

    % Toggle pseudo-color display below ax4 (smaller size)
    uicontrol(f, 'Style', 'togglebutton', 'String', 'Toggle Pseudo-color Display', ...
        'Position', [230, 10, 160, 30], ...
        'FontSize', 10, 'Callback', @toggleColormap);
end

function toggleColormap(src, ~)
    global ax4;

    if get(src, 'Value')             % Enable pseudo-color
        colormap(ax4, hot);          % Try also: jet, parula, etc.
        colorbar(ax4);               % Show color bar
    else                             % Revert to grayscale
        colormap(ax4, gray);
        colorbar(ax4, 'off');        % Hide color bar
    end
end


