function chaosSequence = chaosMap(mapType, varargin)
%
%   Generate a sequence of chaotic mappings of the specified type
%
%--------------------------------------------------------------------------
%
%   Syntax:
%
%   chaosSequence = chaosMap(mapType, sequenceLength)
%
%   chaosSequence = chaosMap(mapType, sequenceLength, mapParameter)
%
%   chaosSequence = chaosMap(mapType, sequenceLength, mapParameter, initialValue)
%
%--------------------------------------------------------------------------
% 
%   Input Parameters:
%
%   mapType        - String, specifying the type of chaotic mapping
%
%                    'logistic': Logistic map
%                                x(n+1) = r * x(t) * (1 - x(n))
%
%                    'tent': Tent map
%                            x(n+1) = { r * x(n)        if x(n) < 0.5
%                                       r * (1 - x(n))  if x(n) >= 0.5 }
%
%                    'chebyshev': Chebyshev map
%                                 x(n+1) = cos(r * arccos(x(n)))
%
%                    'cubic': antisymmetric Cubic map
%                             x(n+1) = r * x(n)^3 + (1 - r) * x(n)
%
%   sequenceLength - Positive integer, specifying the length of the chaotic sequence to be generated: k
%
%   mapParameter   - (Optional) Numeric scalar specifying the map parameter: r
%
%                    Range:：
%                    logistic: default 3.7, range (0, 4)
%
%                    tent: default 2，range (0, 2]
%
%                    chebyshev: default 2，range [2, +∞)
%
%                    cubic: default 4，range (0，4]
%
%   initialValue   - (Optional) Numeric scalar specifying the initial value: x(1)
%
%                    Default is a random value within the valid range:
%                    logistic: range (0, 1)
%
%                    tent: range (0, 1)
%
%                    chebyshev: range (-1, 1)
%
%                    cubic: range (-1, 1)                    
%
%--------------------------------------------------------------------------
%
%   Output:
%
%   chaosSequence - 1-D row vector, the generated chaotic sequence
%
%--------------------------------------------------------------------------
%
%   Examples:
%
%      % Generate a logistic chaotic sequence of length k=100, default r=3.7, random initial value
%      chaosSequence = chaosMap('logistic', 100);
%
%      % Generate a tent chaotic sequence of length k=200, r=4, random initial value
%      chaosSequence = chaosMap('tent', 200, 0.2);
%
%      %Generate a chebyshev chaotic sequence of length k=300, r=4, initial value x(1)=0.3
%      chaosSequence = chaosMap('chebyshev', 300, 4, 0.3);
%
%--------------------------------------------------------------------------
%
%   last update: 2024-08-30
%   Author: Jundong Chen 

% Input argument validation
narginchk(2, 4);
validMapTypes = {'logistic', 'tent', 'chebyshev', 'cubic'}; 
mapType = validatestring(mapType, validMapTypes, 'chaosMap', 'mapType',1);

% Parse input arguments
p = inputParser;
addRequired(p, 'mapType', @ischar);
addRequired(p, 'sequenceLength', @(x) validateattributes(x, {'numeric'}, {'positive', 'integer', 'scalar'}));
addOptional(p, 'mapParameter', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
addOptional(p, 'initialValue', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
parse(p, mapType, varargin{:});

sequenceLength = p.Results.sequenceLength;
mapParameter = p.Results.mapParameter;
initialValue = p.Results.initialValue;

% Set default parameters and valid ranges
switch mapType
    case 'logistic'
        defaultParam = 3.7;
        paramRange = [0, 4];
        valueRange = [0, 1];
    case 'tent'
        defaultParam = 2;
        paramRange = [0, 2];
        valueRange = [0, 1];
    case 'chebyshev'
        defaultParam = 2;
        paramRange = [2, Inf];
        valueRange = [-1, 1];
    case 'cubic'
        defaultParam = 4;
        paramRange = [0, 4];
        valueRange = [-1, 1];
    % TODO: Add a new mapping type here
    % case 'new_map_type'
    %     defaultParam = ...;
    %     paramRange = [...];
    %     valueRange = [...];
end

% Validate and set mapParameter
if isempty(mapParameter)
    mapParameter = defaultParam;
else
    validateattributes(mapParameter, {'numeric'}, {'scalar', '>=', paramRange(1), '<=', paramRange(2)}, 'chaosMap', 'mapParameter',3);
end

% Validate and set initialValue
if isempty(initialValue)
    initialValue = valueRange(1) + (valueRange(2) - valueRange(1)) * rand();
else
    validateattributes(initialValue, {'numeric'}, {'scalar', '>=', valueRange(1), '<=', valueRange(2)}, 'chaosMap', 'initialValue',4);
end

% Initialize output sequence
chaosSequence = zeros(1, sequenceLength);
chaosSequence(1) = initialValue;

% Generate chaotic sequence
try
    for i = 2:sequenceLength
        switch mapType
            case 'logistic'
                chaosSequence(i) = mapParameter * chaosSequence(i-1) * (1 - chaosSequence(i-1));
            case 'tent'
                if chaosSequence(i-1) < 0.5
                    chaosSequence(i) = mapParameter * chaosSequence(i-1);
                else
                    chaosSequence(i) = mapParameter * (1 - chaosSequence(i-1));
                end
            case 'chebyshev'
                chaosSequence(i) = cos(mapParameter * acos(chaosSequence(i-1)));
            case 'cubic'
                chaosSequence(i) = mapParameter * chaosSequence(i-1)^3 + (1 - mapParameter) * chaosSequence(i-1);
            % TODO: Add a new mapping type here
            % case 'new_map_type'
            %     chaosSequence(i) = ...;
        end
    end
catch ME
    error('chaosMap:CalculationError', 'Error during chaotic sequence generation: %s', ME.message);
end

end