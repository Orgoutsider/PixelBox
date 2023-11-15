%--------------------------------------------------------------------------
%--             生成gamma校正所需的rom mif文件
%--------------------------------------------------------------------------
clear all
close all
clc

depth = 256;
width = 8; 
r = [0:1:255];
%--------------------------------------------------------------------------
%--                     sqrt开根
%--------------------------------------------------------------------------
s_qrt = 16*sqrt(r);  %开根 
z1    = round(s_qrt); 

fid = fopen('sqrt.dat','w');
% fprintf(fid,'depth= %d; \n',depth); 
% fprintf(fid,'width= %d; \n',width); 
% fprintf(fid,'address_radix=uns;\n'); 
% fprintf(fid,'data_radix = uns;\n'); 
% fprintf(fid,'Content Begin \n'); 
for(k=1:depth)
    if z1(k) <= 15
        fprintf(fid,'0%x\n',z1(k));
    else
        fprintf(fid,'%x\n',z1(k));
    end
end
% fprintf(fid,'end;');
%--------------------------------------------------------------------------
%--                     square开方
%--------------------------------------------------------------------------
s_quare = (1/256)*r.^2;   %平方
z2 = round(s_quare);

fid = fopen('square.dat','w');
% fprintf(fid,'depth= %d; \n',depth); 
% fprintf(fid,'width= %d; \n',width); 
% fprintf(fid,'address_radix=uns;\n'); 
% fprintf(fid,'data_radix = uns;\n'); 
% fprintf(fid,'Content Begin \n'); 
for(k=1:depth)
    if z2(k) <= 15
        fprintf(fid,'0%x\n',z2(k));
    else
        fprintf(fid,'%x\n',z2(k));
    end
end
% fprintf(fid,'end;');
%--------------------------------------------------------------------------
%--                     曲线展示
%--------------------------------------------------------------------------
hold on
plot(r);        %原曲线
plot(s_qrt);    %开根
plot(s_quare);  %开方
legend('原曲线','开根曲线','开方曲线');
hold off
