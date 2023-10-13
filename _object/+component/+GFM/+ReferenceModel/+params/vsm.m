function params = vsm(omega0)
    if nargin==0
        omega0 = 2*pi*60;
    end
    Dp = 1e5   / omega0 ;
    Jr = 2*1e3 / omega0 ;
    Kp = 0.001;
    Ki = 0.0021;
    Mf = 1;
    
    params = table(Jr,Dp,Kp,Ki,Mf);
end
% A. Tayyebi, D. Groß, A. Anta, F. Kupzog and F. Dörfler, 
% "Frequency Stability of Synchronous Machines and Grid-Forming Power Converters," 
% in IEEE Journal of Emerging and Selected Topics in Power Electronics,vol.8,no.2, pp.1004-1018, 
% June 2020, doi:10.1109/JESTPE.2020.2966524.