function [imgs, metas] = loadImageSequence(folderPath)
    exts = {'*.jpg', '*.jpeg', '*.png', '*.bmp'};
    files = [];
    for i = 1:length(exts)
        files = [files; dir(fullfile(folderPath, exts{i}))];
    end

    if numel(files) < 2
        error('Mindestens zwei Bilder benötigt.');
    end

    names = {files.name};
    timestamps = zeros(1, numel(names));
    metas = struct('name', {}, 'timestamp', {}, 'year', {}, 'month', {});

    for i = 1:numel(names)
        name = names{i};
        tokens = regexp(name, '(?<year>\d{4})[_\-\.]?(?<month>\d{2})?', 'names');
        
        if isfield(tokens, 'year')
            year = str2double(tokens.year);
        else
            year = NaN;
        end

        if isfield(tokens, 'month') && ~isempty(tokens.month)
            month = str2double(tokens.month);
        else
            month = NaN;
        end

        if isnan(year)
            timestamps(i) = Inf;
        else
            if isnan(month)
                timestamps(i) = year * 100;
            else
                timestamps(i) = year * 100 + month;
            end
        end

        metas(i).name = name;
        metas(i).year = year;
        metas(i).month = month;
        metas(i).timestamp = timestamps(i);
    end

    % Sortieren
    [~, sortedIdx] = sort(timestamps);
    files = files(sortedIdx);
    metas = metas(sortedIdx);

    % Bilder laden
    imgs = cell(1, numel(files));
    for i = 1:numel(files)
        imgs{i} = im2double(imread(fullfile(folderPath, files(i).name)));
    end
end
