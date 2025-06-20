function diff = computeDifference(img1, img2)

    % Resize to the same dimensions
    minSize = min(size(img1), size(img2));
    img1 = imresize(img1, minSize(1:2));
    img2 = imresize(img2, minSize(1:2));

    % Calculate absolute difference
    diff = abs(img1 - img2);
end


