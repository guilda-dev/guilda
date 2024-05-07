classdef vsm_DCconst < component.GFM.Inverter
    methods
        function obj = vsm_DCconst()
            obj@component.GFM.Inverter();

            vsm = component.GFM.ReferenceModel.vsm();
            obj.set_reference_model(vsm);

            Vconst = component.GFM.DCsource.Vconstant();
            obj.set_dc_source(Vconst);

        end
    end
end