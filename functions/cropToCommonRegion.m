% Docs: By Martin, branch main, commit 6c9757ae96306c14057f532a7159df33619ca35c

function croppedImgs = cropToCommonRegion(imgs)
    if isempty(imgs)
        error('Keine Bilder übergeben.');
    end

    % Gemeinsame Gültigkeitsmaske aller Bilder (basierend auf NaN, nicht Helligkeit)
    mask = true(size(rgb2gray(imgs{1})));
    for i = 1:numel(imgs)
        valid = all(~isnan(imgs{i}), 3);  % Nur gültige Pixel in allen Farbkanälen
        mask = mask & valid;
    end

    % Suche das größte Rechteck innerhalb der Maske mit nur gültigen Pixeln
    [rows, cols] = size(mask);
    histo = zeros(1, cols);
    maxArea = 0;
    cropRect = [1, 1, cols - 1, rows - 1]; % Fallback-Rechteck

    for r = 1:rows
        % Histogramm für aktuelle Zeile aufbauen
        for c = 1:cols
            if mask(r, c)
                histo(c) = histo(c) + 1;
            else
                histo(c) = 0;
            end
        end

        % Berechne größtes Rechteck in Histogramm
        h = [histo, 0];  % Sentinel anhängen
        stack = [];

        for i = 1:length(h)
            while ~isempty(stack) && h(i) < h(stack(end))
                height = h(stack(end));
                stack(end) = [];

                if isempty(stack)
                    width = i - 1;
                    x = 1;
                else
                    width = i - stack(end) - 1;
                    x = stack(end) + 1;
                end

                area = height * width;
                if area > maxArea
                    maxArea = area;
                    cropRect = [x, r - height + 1, width, height];
                end
            end
            stack(end+1) = i;
        end
    end

    % Bilder zuschneiden
    croppedImgs = cell(1, numel(imgs));
    for i = 1:numel(imgs)
        croppedImgs{i} = imcrop(imgs{i}, cropRect);
    end
end
