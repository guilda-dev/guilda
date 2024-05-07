classdef droop_DC1order < component.GFM.Inverter
    methods
        function obj = droop_DC1order()
            obj@component.GFM.Inverter()

            droop = component.GFM.ReferenceModel.droop();
            obj.set_reference_model(droop);

            Delay1order = component.GFM.DCsource.Delay1order_model();
            obj.set_dc_source(Delay1order);
            
        end
    end
end