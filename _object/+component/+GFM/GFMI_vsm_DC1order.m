classdef GFMI_vsm_DC1order < component.GFM.GFMI
    methods
        function obj = GFMI_vsm_DC1order()
            obj@component.GFM.GFMI()

            vsm = component.GFM.ReferenceModel.vsm();
            obj.set_reference_model(vsm);

            Delay1order = component.GFM.DCsource.Delay1order_model();
            obj.set_dc_source(Delay1order);
        
        end
    end
end