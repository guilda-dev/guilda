classdef droop < component.GFM.Inverter
    methods
        function obj = droop()
            obj@component.GFM.Inverter()

            obj.set_reference_model = 'droop'     ;
            obj.set_dc_source       = 'Delay1order'  ;
            obj.set_vsc_controller  = 'low_level_cascade';
        end
    end
end