classdef GFMI_vsm < component.GFM.converter.main
    methods
        function obj = GFMI_vsm()
            obj@component.GFM.converter.main()

            obj.set_reference_model('vsm');
            obj.set_dc_source('Delay1order');
            obj.set_vsc_controller('low_level_cascade');
        end
    end
end