classdef GFMI_vsm_DCconst < component.GFM.converter.main
    methods
        function obj = GFMI_vsm_DCconst()
            obj@component.GFM.converter.main();

            obj.set_reference_model('vsm');
            obj.set_dc_source('Vconst');
            obj.set_vsc_controller('low_level_cascade');
        end
    end
end