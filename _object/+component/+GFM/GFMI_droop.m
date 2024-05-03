classdef GFMI_droop < component.GFM.GFMI
    methods
        function obj = GFMI_droop()
            obj@component.GFM.GFMI()

            obj.set_reference_model = 'droop'     ;
            obj.set_dc_source       = 'Delay1order'  ;
            obj.set_vsc_controller  = 'low_level_cascade';
        end
    end
end