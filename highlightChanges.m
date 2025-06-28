%You can click "showHighlited" to test this function!!!!!


function highlightChanges(~, ~)
    global imgs imgNames ax5;

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

    % Calculate difference
    diff = abs(img1 - img2);
    
    % Adaptive threshold for change detection
    % Use Otsu's method to automatically determine threshold
    threshold = graythresh(diff);
    
    % Create binary mask for significant changes
    changeMask = diff > threshold;
    
    % Morphological operations to clean up the mask
    se = strel('disk', 2);
    changeMask = imopen(changeMask, se);  % Remove small noise
    changeMask = imclose(changeMask, se); % Fill small gaps
    
    % Create highlighted image
    % Start with the newer image (img2) as base
    baseImg = imgs{idxB};
    if size(baseImg, 3) == 1
        % Convert grayscale to RGB for highlighting
        highlightedImg = repmat(baseImg, [1, 1, 3]);
    else
        highlightedImg = baseImg;
    end
    
    % Resize highlighted image to match processed size
    highlightedImg = imresize(highlightedImg, sz);
    
    % Create colored overlay for changes
    % Red channel: highlight changed areas
    redOverlay = highlightedImg(:,:,1);
    redOverlay(changeMask) = 1.0;  % Set changed areas to bright red
    
    % Green channel: reduce in changed areas for contrast
    greenOverlay = highlightedImg(:,:,2);
    greenOverlay(changeMask) = greenOverlay(changeMask) * 0.3;
    
    % Blue channel: reduce in changed areas for contrast
    blueOverlay = highlightedImg(:,:,3);
    blueOverlay(changeMask) = blueOverlay(changeMask) * 0.3;
    
    % Combine channels
    highlightedImg(:,:,1) = redOverlay;
    highlightedImg(:,:,2) = greenOverlay;
    highlightedImg(:,:,3) = blueOverlay;
    
    % Alternative highlighting method: create contour overlay
    contours = edge(changeMask, 'canny');
    contourDilated = imdilate(contours, strel('disk', 1));
    
    % Add yellow contours around change regions
    highlightedImg(:,:,1) = max(highlightedImg(:,:,1), double(contourDilated));
    highlightedImg(:,:,2) = max(highlightedImg(:,:,2), double(contourDilated));
    highlightedImg(:,:,3) = highlightedImg(:,:,3) .* (1 - double(contourDilated));
    
    % Display the highlighted image
    axes(ax5);
    imshow(highlightedImg, []);
    
    % Calculate and display statistics
    totalPixels = numel(changeMask);
    changedPixels = sum(changeMask(:));
    changePercentage = (changedPixels / totalPixels) * 100;
    
    titleStr = sprintf('Highlighted Changes: %s vs %s\n%.2f%% Changed (Threshold: %.3f)', ...
                      imgNames{idxA}, imgNames{idxB}, changePercentage, threshold);
    title(ax5, titleStr, 'FontWeight', 'bold', 'Interpreter', 'none');

    % Set axis properties
    axis(ax5, 'off');
    axis(ax5, 'image');
    set(ax5, 'Units', 'pixels', 'Position', [590, 70, 420, 340]);
    
    % Optional: Display change statistics in command window
    fprintf('Change Detection Results:\n');
    fprintf('Images compared: %s vs %s\n', imgNames{idxA}, imgNames{idxB});
    fprintf('Threshold used: %.4f\n', threshold);
    fprintf('Changed pixels: %d / %d\n', changedPixels, totalPixels);
    fprintf('Change percentage: %.2f%%\n', changePercentage);
    fprintf('----------------------------------------\n');
end

function grayImg = im2grayIfRGB(img)
    % Helper function to convert RGB to grayscale if needed
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
end
