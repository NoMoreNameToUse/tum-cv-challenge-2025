% Cuz there are no button for this function.
% You can open GUI.m, then change "ShowHighlighted" (line 3) 
% to "Change Intensity" and change "@highlightChanges" (line 37) 
% to "@showHeatmap". Don't forget to save them. Finally, you can
% click "Change Intensity" to test this function.


function showHeatmap(~, ~)
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

    % Calculate difference with enhanced processing
    rawDiff = abs(img1 - img2);
    
    % Apply Gaussian smoothing to reduce noise and create smoother transitions
    smoothedDiff = imgaussfilt(rawDiff, 1.5);
    
    % Enhance contrast using adaptive histogram equalization
    enhancedDiff = adapthisteq(smoothedDiff);
    
    % Calculate intensity statistics for better visualization
    meanDiff = mean(enhancedDiff(:));
    stdDiff = std(enhancedDiff(:));
    
    % Normalize to [0,1] with enhanced dynamic range
    % Use 99th percentile as upper bound to avoid outliers
    upperBound = prctile(enhancedDiff(:), 99);
    normalizedDiff = enhancedDiff / max(upperBound, eps);
    normalizedDiff = min(normalizedDiff, 1); % Clamp to [0,1]
    
    %% Change Intensity Heatmap (ax4)
    axes(ax4);
    
    % Create custom colormap: Blue (no change) -> Green -> Yellow -> Red (max change)
    customColormap = createCustomHeatmapColormap();
    
    % Display the heatmap
    h1 = imagesc(normalizedDiff);
    colormap(ax4, customColormap);
    
    % Add colorbar with labels
    cb1 = colorbar(ax4);
    cb1.Label.String = 'Change Intensity';
    cb1.Label.FontSize = 12;
    cb1.Label.FontWeight = 'bold';
    
    % Set colorbar ticks and labels
    cb1.Ticks = [0, 0.25, 0.5, 0.75, 1];
    cb1.TickLabels = {'No Change', 'Low', 'Medium', 'High', 'Max Change'};
    
    % Calculate change statistics
    totalPixels = numel(normalizedDiff);
    significantChange = sum(normalizedDiff(:) > 0.3); % Pixels with >30% change
    changePercentage = (significantChange / totalPixels) * 100;
    
    title(ax4, sprintf('Change Intensity Heatmap (%.1f%% significant change)\n%s vs %s', ...
                      changePercentage, imgNames{idxA}, imgNames{idxB}), ...
          'FontWeight', 'bold', 'Interpreter', 'none', 'FontSize', 11);
    
    axis(ax4, 'image');
    axis(ax4, 'off');
    
    % Print detailed statistics
    fprintf('\n=== HEATMAP ANALYSIS RESULTS ===\n');
    fprintf('Images compared: %s vs %s\n', imgNames{idxA}, imgNames{idxB});
    fprintf('Image dimensions: %d x %d pixels\n', sz(1), sz(2));
    fprintf('Mean change intensity: %.4f\n', meanDiff);
    fprintf('Standard deviation: %.4f\n', stdDiff);
    fprintf('Maximum change: %.4f\n', max(enhancedDiff(:)));
    fprintf('Pixels with significant change (>30%%): %d (%.2f%%)\n', significantChange, changePercentage);
    fprintf('99th percentile intensity: %.4f\n', upperBound);
    fprintf('================================\n\n');
end

function customMap = createCustomHeatmapColormap()
    % Create a custom colormap for better change visualization
    % Blue (no change) -> Cyan -> Green -> Yellow -> Orange -> Red (max change)
    
    n = 256;
    
    % Define key colors (RGB values)
    colors = [
        0.0, 0.0, 0.5;   % Dark blue (no change)
        0.0, 0.5, 1.0;   % Light blue
        0.0, 1.0, 1.0;   % Cyan
        0.0, 1.0, 0.0;   % Green
        1.0, 1.0, 0.0;   % Yellow
        1.0, 0.5, 0.0;   % Orange
        1.0, 0.0, 0.0;   % Red (max change)
    ];
    
    % Interpolate between key colors
    x = linspace(1, size(colors,1), size(colors,1));
    xi = linspace(1, size(colors,1), n);
    
    customMap = zeros(n, 3);
    for i = 1:3
        customMap(:,i) = interp1(x, colors(:,i), xi, 'linear');
    end
end



function grayImg = im2grayIfRGB(img)
    % Helper function to convert RGB to grayscale if needed
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
end
