function resetGUI(~, ~)
    global imgs imgNames ax1 ax2 ax3 ax4 ax5;

    % Reset image containers
    imgs = cell(1, 3);
    imgNames = cell(1, 3);

    % List of all axes to be cleared
    axList = {ax1, ax2, ax3, ax4, ax5};

    % Clear content and titles of all axes
    for i = 1:length(axList)
        cla(axList{i});                  % Clear image
        title(axList{i}, '');            % Clear title
        set(axList{i}, 'Visible', 'off'); % hide axes
    end
end
