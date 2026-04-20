function c = build_component(~, key, varargin)
    switch key
        case 'load-impedance'
            c = component.load.impedance(varargin{:});
        case 'load-power'
            c = component.load.power(varargin{:});
        case 'gen-classical'
            c = component.generator.classical(varargin{:});
        case 'gen-1axis'
            c = component.generator.one_axis(varargin{:});
        case 'gen-park'
            c = component.generator.park(varargin{:});
        otherwise
            error('Bus:UnsupportedComponentType', 'Unsupported component type: %s', string(key));
    end
end