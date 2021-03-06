
%-----------------------------------------------%
% Begin Function:  endpoint                     %
%-----------------------------------------------%

function output = s3toEndpoint(input)

	global load_cases

	%
	% Variables at Start and End of each phase
	%
	Nph=length(input.phase);
	for k=1:Nph
		t0{k} = input.phase(k).initialtime;
		tf{k} = input.phase(k).finaltime;
		x0{k} = input.phase(k).initialstate;
		xf{k} = input.phase(k).finalstate;
	end

	s = input.parameter;

	dv_geo1 = s(1);
	dv_geo2 = s(2);
	dv_geo3 = s(3);
	dv_geo4 = s(4);
	dv_geo5 = s(5);
	dv_geo6 = s(6);

	% % OPTION A
	 dry_mass = compute_dry_mass_bis(dv_geo1,dv_geo2,dv_geo3,dv_geo4);

	% OPTION B
	dvs = reverse_variable_change(load_cases,dv_geo1,dv_geo2,dv_geo3,dv_geo4,dv_geo5,dv_geo6);
	dry_mass_current_step = input.phase(Nph).finalstate(7); % WITHOUT PAYLOAD MASS
	dry_mass = compute_dry_mass(dvs, dry_mass_current_step, input.auxdata);





	%
	% Objective Function:
	%
	output.objective = -xf{3}(4)/1000;

	%
	% phase links
	% event groups 1-5
	%
	output.eventgroup(1).event = [tf{1}-t0{2},xf{1}-x0{2}];
	output.eventgroup(2).event = [tf{2}-t0{3},xf{2}-x0{3}];
	output.eventgroup(3).event = [tf{3}-t0{4},xf{3}-x0{4}];
	output.eventgroup(4).event = [tf{4}-t0{5},xf{4}-x0{5}];
	output.eventgroup(5).event = [tf{5}-t0{6},xf{5}-x0{6}];

	%
	% mass losses at separation
	%

	output.eventgroup(3).event(1+7) = xf{3}(7) - x0{4}(7) - input.auxdata.us_mass;

	%
	% phase durations
	% event group 6
	%
	output.eventgroup(6).event = [...
	tf{1}-t0{1},...
	tf{2}-t0{2},...
	tf{3}-t0{3},...
	tf{4}-t0{4},...
	tf{5}-t0{5},...
	tf{6}-t0{6}];

	%
	% upper stage injection conditions
	% event group 7
	%
	r   = xf{3}(1);
	lon = xf{3}(2);
	lat = xf{3}(3);
	v   = xf{3}(4);
	gam = xf{3}(5);
	al  = xf{3}(6);
	[alt,lon,glat] = latgeo(int32(1),input.auxdata.re,input.auxdata.f_ell,r,lon,lat);
	output.eventgroup(7).event = [gam, alt];

	%
	% regularization for re-entry
	% event group 8
	%
	output.eventgroup(8).event = [input.phase(5).integral+input.phase(6).integral];

	%
	% final dry mass
	% event group 9
	%

	output.eventgroup(9).event = [xf{6}(7) - dry_mass];

	%
	% fuel limitations
	% event group 10
	%

	output.eventgroup(10).event = [x0{2}(7) - xf{2}(7) - input.auxdata.fuel_mass];

	%
	% landing heading
	% event group 11
	%

	al  = xf{6}(6);

	output.eventgroup(11).event = [al - 2*pi*floor(al/2/pi)];



end

%-----------------------------------------------%
% End Function:  endpoint                       %
%-----------------------------------------------%






function dry_mass = compute_dry_mass_bis(dv_geo1,dv_geo2,dv_geo3,dv_geo4)

  % strake
  % x = 4.44779 y + 2.6669425 # - 5.11669
  a_strake = 4.44779;
  b_strake = 2.6669425;

  % lead
  % x = 0.551852 y + 8.672531 # 7.70679
  a_lead = 0.551852;
  b_lead_ini = 8.672531;
  b_lead = b_lead_ini + dv_geo1;

  % trail
  % x = -0.0549317 y + 13.984169525 # 14.0803 
  a_trail = -0.0549317;
  b_trail_ini = 13.984169525;
  b_trail = b_trail_ini + dv_geo2 + dv_geo4;

  wing_width_section_1_ini = 1.54;
  wing_width_section_2_ini = 2.41;
  wing_width_ini = wing_width_section_1_ini + wing_width_section_2_ini;
  wing_width = wing_width_ini + dv_geo3;
  wing_width_section_1 = (b_lead-b_strake)/(a_strake-a_lead);
  wing_width_section_2 = wing_width - wing_width_section_1;

  % Section 1
  % \int _ fuse_radius                          ^ (wing_width_section_1 + fuse_radius) [ (a_trail * y + b_trail) - (a_strake * y + b_strake)] dy

  x1 = 0.0;
  x2 = wing_width_section_1;
  a = a_trail;
  b = b_trail;
  c = a_strake;
  d = b_strake;

  area_1 = -1.0/2.0 * (x1 - x2) * (2.0*b - 2.0*d + (a - c) * (x1 + x2));

  % Section 2
  % \int _ (wing_width_section_1 + fuse_radius) ^ (wing_width + fuse_radius)           [ (a_trail * y + b_trail) - (a_lead * y + b_lead) ] dy

  x1 = wing_width_section_1;
  x2 = wing_width;
  a = a_trail;
  b = b_trail;
  c = a_lead;
  d = b_lead;

  area_2 = -1.0/2.0 * (x1 - x2) * (2.0*b - 2.0*d + (a - c) * (x1 + x2));

  % Mass

  area = area_1 + area_2;

  projected_area = 80.0 + 2.0*area;

%  dry_mass = 150.0 * projected_area - 10000.0;

  dry_mass = 90.0 * projected_area - 2900.0;

  % IS TOO HEAVY, WINGS DO NOT HAVE ENAUGH LIFT FOR LANDING PHASE
  % IS AT AOA 10 ALL THE TIME AND WING AREAS ARE GETTING AS BIG AS THEY CAN
  % REDUCING MAX SPEED ACHIEVABLE
  % dry_mass = 105.927 * projected_area - 697.025;

end


function dvs = reverse_variable_change(load_cases,dv_geo1,dv_geo2,dv_geo3,dv_geo4,dv_geo5,dv_geo6)

  sizes = size(load_cases);

  dvs = zeros(sizes(1),14);

  for index = 1:sizes(1)

        dv_mach = load_cases(index,1);
        Reynolds = load_cases(index,2);
        AoA = load_cases(index,3);

        dv_rey = log10(Reynolds) + 3.0/8.0*dv_mach - 7.0;
    
        if dv_mach >= 1.0
            dv_aoa = (AoA - (3.92857*dv_mach+3.57143)) / (1.78571*dv_mach+5.71429); % Supersonic
        else
            dv_aoa = AoA/7.5-1.0; % Subsonic
        end

        dv_nx = load_cases(index,4);
        dv_nz = load_cases(index,5);
        dv_thrust = load_cases(index,6);
        dv_pdyn = load_cases(index,7);
        dv_fuel_mass = load_cases(index,8);

        dv_mach      = min(    8.0, max(    1.1,      dv_mach));
        dv_rey       = min(    1.0, max(   -1.0,       dv_rey));
        dv_aoa       = min(    1.0, max(   -1.0,       dv_aoa));
        dv_nx        = min(    6.0, max(   -3.0,        dv_nx));
        dv_nz        = min(    3.0, max(   -6.0,        dv_nz));
        dv_thrust    = min(  3.0e6, max(    0.0,    dv_thrust));
        dv_pdyn      = min( 35.0e3, max( 1.0e-6,      dv_pdyn));
        dv_fuel_mass = min( 26.0e3, max(    0.0, dv_fuel_mass));

        dvs(index,:) = [dv_mach, dv_rey, dv_aoa, dv_nx, dv_nz, dv_thrust, dv_pdyn, dv_fuel_mass, dv_geo1, dv_geo2, dv_geo3, dv_geo4, dv_geo5, dv_geo6];

    end

end
