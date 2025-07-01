classdef vsm1axis_DCconst < component.GFM.Inverter
    methods
        function obj = vsm1axis_DCconst()
            obj@component.GFM.Inverter();

            vsm1axis = component.GFM.ReferenceModel.vsm1axis();
            obj.set_reference_model(vsm1axis);

            Vconst = component.GFM.DCsource.Vconstant();
            obj.set_dc_source(Vconst);

        end
    end
end

