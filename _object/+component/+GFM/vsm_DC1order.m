classdef vsm_DC1order < component.GFM.Inverter
    methods
        function obj = vsm_DC1order()
            obj@component.GFM.Inverter()

            vsm = component.GFM.ReferenceModel.vsm();
            obj.set_reference_model(vsm);

            Delay1order = component.GFM.DCsource.Delay1order_model();
            obj.set_dc_source(Delay1order);
        
        end
    end
end