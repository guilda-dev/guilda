Ei = 1;
Ej = 1.1;
X  = 1;

delta = linspace(-2*pi,2*pi,100);

T = @(delta) X * sqrt( Ei^2 + Ej^2 - 2*Ei*Ej*cos(delta) );
F = @(delta) T(delta) * cos(delta/2) *sign(delta); 

F_ = @(delta)delta;

figure
plot( delta, arrayfun(@(d)F(d),delta) )
grid on
ax = gca;
ax.XTick = (-2:1/8:2)*pi;
% ax.XTickLabel = {'-2\pi','-\frac{7}{4}\pi','-\frac{3}{2}\pi','-\frac{5}{4}\pi','-\pi','-\frac{3}{4}\pi','-\frac{1}{2}\pi','-\frac{1}{4}\pi','0','\frac{1}{4}\pi','\frac{1}{2}\pi','\frac{3}{4}\pi','\pi','\frac{5}{4}\pi','\frac{3}{2}\pi','\frac{7}{4}\pi','2\pi',};
% xticklabels(ax,{'-2\pi','-\frac{7}{4}\pi','-\frac{3}{2}\pi','-\frac{5}{4}\pi','-\pi','-\frac{3}{4}\pi','-\frac{1}{2}\pi','-\frac{1}{4}\pi','0','\frac{1}{4}\pi','\frac{1}{2}\pi','\frac{3}{4}\pi','\pi','\frac{5}{4}\pi','\frac{3}{2}\pi','\frac{7}{4}\pi','2\pi',},'Interpreter','latex')

