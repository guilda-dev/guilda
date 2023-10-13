function params = droop(varargin)
    Dw = 1e-3;
    Kp = 0.001;
    Ki = 0.5;
    
    params = table(Dw,Kp,Ki);
end
% A. Tayyebi, D. Groß, A. Anta, F. Kupzog and F. Dörfler, 
% "Frequency Stability of Synchronous Machines and Grid-Forming Power Converters," 
% in IEEE Journal of Emerging and Selected Topics in Power Electronics,vol.8,no.2, pp.1004-1018, 
% June 2020, doi: 10.1109/JESTPE.2020.2966524.