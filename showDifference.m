function showDifference(~, ~)
    global imgs imgNames ax4;

    % Read selected indices from dropdowns
    popupA = findobj('Tag', 'popupA');
    popupB = findobj('Tag', 'popupB');

    idxA = popupA.Value;
    idxB = popupB.Value;

    % Safety check
    if isempty(imgs) || idxA > numel(imgs) || idxB > numel(imgs) ...
            || isempty(imgs{idxA}) || isempty(imgs{idxB})
        errordlg('Please load and select two valid images.', 'Error');
        return;
    end

    % Convert to grayscale if needed
    img1 = im2grayIfRGB(imgs{idxA});
    img2 = im2grayIfRGB(imgs{idxB});

    % Resize to same size
    sz = min([size(img1); size(img2)], [], 1);
    img1 = imresize(img1, sz);
    img2 = imresize(img2, sz);


    % Difference
    diff = abs(img1 - img2);

    % Display
    axes(ax4);
    imshow(diff, []);
    title(ax4, ['Difference Map: ', imgNames{idxA}, ' vs ', imgNames{idxB}], ...
          'FontWeight', 'bold', 'Interpreter', 'none');

    axis(ax4, 'off');
    axis(ax4, 'image');
    set(ax4, 'Units', 'pixels', 'Position', [100, 70, 420, 340]);
end

function grayImg = im2grayIfRGB(img)
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
end
