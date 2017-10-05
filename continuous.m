%--------------------------------------%
% BEGIN: function s3toContinuous       %
%--------------------------------------%
function phaseout = s3toContinuous(input)

  engine_state = {'off' 'on' 'off' 'off' 'off' 'off'};
  pha = {'a' 'a' 'a' 'r' 'r' 'r'};

  Nph = length(input.phase);

  for k=1:Nph

    [dr,dlon,dlat,dv,dgam,dal,dm,da,db,d1,d2,d3,d4,pdyn,hr,nx,ny,nz,thu,cd,cl,rho,p,Tenv,mach,rey1m] = dynamics(input.phase(k),input.auxdata,engine_state(k),pha(k));

    phaseout(k).dynamics = [dr,dlon,dlat,dv,dgam,dal,dm,da,db,d1,d2,d3,d4];
    phaseout(k).path = [pdyn,hr,abs(nz)];

  end

  for k=4:6

    daoa=input.phase(k).control(:,1);
    dbnk=input.phase(k).control(:,2);

    phaseout(k).integrand = abs(daoa)+abs(dbnk);

  end

end
%------------------------------------%
% END: function s3toContinuous       %
%------------------------------------%


