%-----------------------------------------------%
% Begin Function: write_outputs                 %
%-----------------------------------------------%

function [tstate,tctrl,ttime,tph,tphid] = write_outputs(interp,phases,type,auxdata)

engine_state = {'off' 'on' 'off' 'off' 'off' 'off'};
pha = {'a' 'a' 'a' 'r' 'r' 'r'};

d2r = pi/180;
r2d = 180/pi;

fname = ['./output/output_' type '.dat'];
fid = fopen(fname,'w');
fprintf(fid,'VARIABLES = "time","ph","h","lon","lat","v","gam","al","m","aoa","bank","dv1","dv2","dv3","dv4","pdyn","hr","nx","ny","nz","thu","cd","cl","rho","p","Tenv","mach","rey1m"\n');

for ip = phases

    data = interp.phase(ip);

    time = data.time;

    r = data.state(:,1);
    lon = data.state(:,2);
    lat = data.state(:,3);
    v = data.state(:,4);
    gam = data.state(:,5);
    al = data.state(:,6);
    m = data.state(:,7);
    aoa = data.state(:,8);
    bank = data.state(:,9);

    dv1 = data.state(:,9+1);
    dv2 = data.state(:,9+2);
    dv3 = data.state(:,9+3);
    dv4 = data.state(:,9+4);

    [dr,dlon,dlat,dv,dgam,dal,dm,da,db,d1,d2,d3,d4,pdyn,hr,nx,ny,nz,thu,cd,cl,rho,p,Tenv,mach,rey1m] = dynamics(data,auxdata,engine_state(ip),pha(ip));

    daoa = data.control(:,1);
    dbank = data.control(:,2);

    ddv1 = data.control(:,2+1);
    ddv2 = data.control(:,2+2);
    ddv3 = data.control(:,2+3);
    ddv4 = data.control(:,2+4);

    for k = 1:length(time)

        [alt,lon_conv,glat_conv] = latgeo(int32(1),auxdata.re,auxdata.f_ell,r(k),lon(k),lat(k));
        h = alt/1000;

        fprintf(fid,'%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n',...
            time(k),ip,h,lon(k)*r2d,lat(k)*r2d,v(k),gam(k)*r2d,al(k)*r2d,m(k),aoa(k)*r2d,bank(k)*r2d,dv1(k),dv2(k),dv3(k),dv4(k),...
            pdyn(k),hr(k),nx(k),ny(k),nz(k),thu(k),cd(k),cl(k),rho(k),p(k),Tenv(k),mach(k),rey1m(k));

    end

end

fclose(fid);

end
%-----------------------------------------------%
% End Function:  write_outputs                  %
%-----------------------------------------------%