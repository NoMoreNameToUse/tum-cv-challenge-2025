function varargout = ImageAnalysisToolkit(tool_type, varargin)
% IMAGEANALYSISTOOLKIT - Unified interface for image analysis toolkit
%
% ==================================================================================
% Main Calling Format:
%   ImageAnalysisToolkit(tool_type, ...)
%   fig_handle = ImageAnalysisToolkit(tool_type, ...)
%
% ==================================================================================
% Input Parameters:
%   tool_type - Tool type (string), supports the following options:
%
%   1. 'sidebyside' 
%      - Side-by-side image comparison tool
%      - Calls: sideBySideDisplay.m
%      - Supports image preprocessing (registration and cropping)
%
%   2. 'slider'  
%      - Curtain slider comparison tool
%      - Calls: curtainSliderDisplay.m
%      - Supports sliding curtain effect comparison
%
%   3. 'timelapse'
%      - Time series animation tool
%      - Calls: timelapseAnimation.m
%      - Supports image sequence playback and export
%
% ==================================================================================
% Required Scripts:
%   • sideBySideDisplay.m      - Side-by-side comparison tool
%   • curtainSliderDisplay.m   - Curtain slider comparison tool  
%   • timelapseAnimation.m     - Time series animation tool
%   • loadImageSequence.m      - Image sequence loading
%   • preprocessImageSequence.m - Image preprocessing (registration)
%   • cropToCommonRegion.m     - Common region cropping
%
% ==================================================================================
% Usage Examples:
%
%   % Example 1: Side-by-side comparison tool (folder selection mode)
%   ImageAnalysisToolkit('sidebyside');
%
%   % Example 2: Curtain slider tool (direct image input)
%   img1 = imread('before.jpg');
%   img2 = imread('after.jpg'); 
%   ImageAnalysisToolkit('slider', img1, img2);
%
%   % Example 3: Time series animation (specified folder)
%   folder_path = 'C:\images\sequence\';
%   ImageAnalysisToolkit('timelapse', folder_path);
%
%   % Example 4: Get figure handle
%   fig_handle = ImageAnalysisToolkit('sidebyside', img1, img2, {'Before', 'After'});
%
% ==================================================================================

%% ================== Input Parameter Validation ==================
if nargin < 1
    error('ImageAnalysisToolkit:MissingArguments', ...
          ['Must specify tool type.\n' ...
           'Supported types: ''sidebyside'', ''slider'', ''timelapse''\n' ...
           'Please check code comments for detailed information.']);
end

if ~ischar(tool_type) && ~isstring(tool_type)
    error('ImageAnalysisToolkit:InvalidToolType', ...
          'Tool type must be a string. Please use ''sidebyside'', ''slider'', ''timelapse''.');
end

tool_type = lower(char(tool_type));

%% ================== Tool Routing and Invocation ==================
try
    switch tool_type
        case {'sidebyside', 'side-by-side', 'side_by_side'}
            
            if nargout > 0
                varargout{1} = sideBySideDisplay(varargin{:});
            else
                sideBySideDisplay(varargin{:});
            end
            
        case {'slider', 'curtain', 'curtain_slider'}
            
            if nargout > 0
                varargout{1} = curtainSliderDisplay(varargin{:});
            else
                curtainSliderDisplay(varargin{:});
            end
            
        case {'timelapse', 'time_lapse', 'animation'}
            
            if nargout > 0
                varargout{1} = timelapseAnimation(varargin{:});
            else
                timelapseAnimation(varargin{:});
            end
            
        otherwise
            % ========== Unknown tool type error handling ==========
            error('ImageAnalysisToolkit:UnknownToolType', ...
                  ['Unknown tool type: ''%s''\n\n' ...
                   'Supported tool types:\n' ...
                   '  • ''sidebyside''  - Side-by-side image comparison tool\n' ...
                   '  • ''slider''     - Curtain slider comparison tool\n' ...
                   '  • ''timelapse''  - Time series animation tool\n\n' ...
                   'Usage example: ImageAnalysisToolkit(''sidebyside'')'], tool_type);
    end
    
catch ME
    
    % Check if it's a file dependency issue
    if contains(ME.message, 'Undefined function')
        missing_func = extractMissingFunction(ME.message);
        error_msg = sprintf(['Error calling image analysis tool:\n' ...
                            'Tool type: %s\n' ...
                            'Error reason: Missing dependency file ''%s.m''\n\n' ...
                            'Solutions:\n' ...
                            '1. Ensure %s.m file is in MATLAB current path\n' ...
                            '2. Use addpath(''folder_path'') to add folder containing the file\n' ...
                            '3. Check if filename spelling is correct'], ...
                           tool_type, missing_func, missing_func);
    else
        % Other types of errors
        error_msg = sprintf(['Error calling image analysis tool:\n' ...
                            'Tool type: %s\n' ...
                            'Error message: %s\n\n' ...
                            'Suggestions:\n' ...
                            '1. Check if input parameters are correct\n' ...
                            '2. Ensure all dependency files are available'], ...
                           tool_type, ME.message);
    end
    
    error('ImageAnalysisToolkit:ToolExecutionError', error_msg);
end

end

%% ================== Helper Functions ==================
function missing_func = extractMissingFunction(error_msg)
    
    % Try to match common "Undefined function" error patterns
    pattern = 'Undefined function ''(\w+)''';
    tokens = regexp(error_msg, pattern, 'tokens');
    
    if ~isempty(tokens)
        missing_func = tokens{1}{1};
    else
        pattern = '''(\w+)'' is not recognized';
        tokens = regexp(error_msg, pattern, 'tokens');
        if ~isempty(tokens)
            missing_func = tokens{1}{1};
        else
            missing_func = 'unknown_function';
        end
    end
end