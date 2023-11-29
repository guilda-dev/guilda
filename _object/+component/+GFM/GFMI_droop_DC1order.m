classdef GFMI_droop_DC1order < component.GFM.GFMI
    methods
        function obj = GFMI_droop_DC1order()
            obj@component.GFM.GFMI()

            droop = component.GFM.ReferenceModel.droop();
            obj.set_reference_model(droop);

            Delay1order = component.GFM.DCsource.Delay1order_model();
            obj.set_dc_source(Delay1order);
            
        end
    end
end