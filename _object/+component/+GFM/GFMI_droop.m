classdef GFMI_droop < component.GFM.converter.main
    methods
        function obj = GFMI_droop()
            obj@component.GFM.converter.main()

            obj.reference_model = 'droop'     ;
            obj.dc_source       = 'Delay1order'  ;
            obj.vsc_controller  = 'low_level_cascade';
        end
    end
end