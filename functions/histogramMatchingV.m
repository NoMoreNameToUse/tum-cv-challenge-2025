
function imgsNorm = histogramMatchingV(imgs)
    % imgs: Zell-Array von RGB-Bildern
    % numBins: Anzahl der Histogramm-Bins
    % sigma: Sigma für Gauß-Glättung
    sigma = 1;
    numBins =255;
    
    N = numel(imgs);
    edges   = linspace(0,1,numBins+1);
    centers = edges(1:end-1) + diff(edges)/2;

    % 1) Gemeinsame Referenz-CDF berechnen
    allV = [];
    for i = 1:N
        hsvI = rgb2hsv(imgs{i});
        tmpV = hsvI(:,:,3);
        allV = [allV; tmpV(:)];    %#ok<AGROW>
    end
    counts       = histcounts(allV, edges);
    countsSmooth = imgaussfilt(counts, sigma);
    pdfRef       = countsSmooth / sum(countsSmooth);
    cdfRef       = cumsum(pdfRef);

    % Clip-Grenzen (1%/99%) festlegen
    tolLow  = find(cdfRef >= 0.01, 1, 'first');
    tolHigh = find(cdfRef <= 0.99, 1, 'last');
    vMin = centers(tolLow);
    vMax = centers(tolHigh);

    % 2) Histogram-Matching für jedes Bild
    imgsNorm = cell(size(imgs));
    for i = 1:N
        hsvI = rgb2hsv(imgs{i});
        V    = hsvI(:,:,3);

        % Quell-CDF berechnen
        countsSrc = histcounts(V(:), edges);
        pdfSrc    = countsSrc / sum(countsSrc);
        cdfSrc    = cumsum(pdfSrc);

        % Mapping-Funktion von Quell-CDF zu Ziel-Mittelpunkten
        mapFunc = interp1(cdfRef, centers, cdfSrc, 'linear', 'extrap');
        mapFunc(1)   = centers(1);
        mapFunc(end) = centers(end);

        % Auf V-Kanal anwenden (pchip für glattes Mapping)
        Vmatched = interp1(centers, mapFunc, V, 'pchip');

        % Pixel außerhalb der Clip-Grenzen beibehalten
        Vmatched(V <= vMin) = V(V <= vMin);
        Vmatched(V >= vMax) = V(V >= vMax);

        % Lokale Kontrastanpassung (CLAHE) für mehr Details in allen Szenen
        Vmatched = adapthisteq(Vmatched, 'ClipLimit', 0.02, 'Distribution', 'uniform');

        hsvI(:,:,3) = Vmatched;
        imgsNorm{i} = hsv2rgb(hsvI);
    end
    for i = 1:N
        hsvI = rgb2hsv(imgs{i});
        V    = hsvI(:,:,3);

        % Quell-CDF berechnen
        countsSrc = histcounts(V(:), edges);
        pdfSrc    = countsSrc / sum(countsSrc);
        cdfSrc    = cumsum(pdfSrc);

        % Mapping-Funktion von Quell-CDF zu Ziel-Mittelpunkten
        mapFunc = interp1(cdfRef, centers, cdfSrc, 'linear', 'extrap');
        mapFunc(1)   = centers(1);
        mapFunc(end) = centers(end);

        % Auf V-Kanal anwenden (pchip für glattes Mapping)
        Vmatched = interp1(centers, mapFunc, V, 'pchip');

        % Pixel außerhalb der Clip-Grenzen beibehalten
        Vmatched(V <= vMin) = V(V <= vMin);
        Vmatched(V >= vMax) = V(V >= vMax);

        hsvI(:,:,3) = Vmatched;
        imgsNorm{i} = hsv2rgb(hsvI);
    end
end