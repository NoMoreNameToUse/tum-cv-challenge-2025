function loadImageFolder(~, ~)
    global imgs imgNames ax1 ax2 ax3;

    folder = uigetdir;
    if folder == 0, return; end

    % Supported image extensions
    exts = {'*.jpg', '*.jpeg', '*.png', '*.bmp'};
    files = [];
    for i = 1:length(exts)
        files = [files; dir(fullfile(folder, exts{i}))];
    end

    if numel(files) < 2
        errordlg('At least two images are required.', 'Error');
        return;
    end

    % Extract timestamps (year and optional month) from filenames
    names = {files.name};
    timestamps = zeros(1, numel(names));
    for i = 1:numel(names)
        tokens = regexp(names{i}, '(\d{4})[_\-\.]?(\d{2})', 'tokens', 'once');
        if ~isempty(tokens)
            year = str2double(tokens{1});
            month = str2double(tokens{2});
            timestamps(i) = year * 100 + month;
        else
            yearOnly = regexp(names{i}, '\d{4}', 'match', 'once');
            if ~isempty(yearOnly)
                year = str2double(yearOnly);
                timestamps(i) = year * 100;
            else
                timestamps(i) = Inf; % invalid or no date info
            end
        end
    end

    % Sort by timestamp (ascending)
    [~, sortedIdx] = sort(timestamps);
    imgNamesAll = names(sortedIdx);
    filesSorted = files(sortedIdx);

   
    % Image selection logic
    if numel(filesSorted) > 3
        % More than 3 images: prompt user to select
        [sel, ok] = listdlg(...
            'PromptString', 'Select 3 images (auto-sorted by date)', ...
            'SelectionMode', 'multiple', ...
            'ListString', imgNamesAll, ...
            'Name', 'Select Images', ...
            'ListSize', [400, 300]);

        if ~ok || numel(sel) ~= 3
            errordlg('Please select exactly 3 images.', 'Selection Cancelled');
            return;
        end

        selectedNames = imgNamesAll(sel);
        selectedFiles = filesSorted(sel);

        % Re-sort selected images by timestamp
        selTimestamps = zeros(1, 3);
        for i = 1:3
            tokens = regexp(selectedNames{i}, '(\d{4})[_\-\.]?(\d{2})', 'tokens', 'once');
            if ~isempty(tokens)
                year = str2double(tokens{1});
                month = str2double(tokens{2});
                selTimestamps(i) = year * 100 + month;
            else
                yearOnly = regexp(selectedNames{i}, '\d{4}', 'match', 'once');
                if ~isempty(yearOnly)
                    selTimestamps(i) = str2double(yearOnly) * 100;
                else
                    selTimestamps(i) = Inf;
                end
            end
        end

        [~, idxSort] = sort(selTimestamps);
        selectedFiles = selectedFiles(idxSort);
        imgNames = selectedNames(idxSort);

    else
        % 3 or fewer images: use all (already sorted)
        selectedFiles = filesSorted;
        imgNames = imgNamesAll;
    end

   
    % Load and display images
    imgs = cell(1, 3);
    axList = {ax1, ax2, ax3};

    for i = 1:numel(selectedFiles)
        file = fullfile(folder, selectedFiles(i).name);
        img = imread(file);
        imgs{i} = im2double(img);

        cla(axList{i});
        imshow(imgs{i}, 'Parent', axList{i});

        % Display title with year/month
        y = regexp(imgNames{i}, '\d{4}', 'match', 'once');
        m = regexp(imgNames{i}, '(?<=\d{4}[_\-\.]?)\d{2}', 'match', 'once');
        if isempty(m)
            title(axList{i}, ['Image ', num2str(i), ': ', y], ...
                'FontWeight', 'bold', 'Interpreter', 'none');
        else
            title(axList{i}, ['Image ', num2str(i), ': ', y, '_', m], ...
                'FontWeight', 'bold', 'Interpreter', 'none');
        end
    end
end
