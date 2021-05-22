% Author: Richard Hoepfinger.
% Email: richhoepfinger@gmail.com
% FOR: UGA Small Satellite Research Lab.
% WORKS: Reads an excel file containing the locations of targets and a tle for a
% specified satellite. Makes a scheduler for when the satellite is above
% the UGA ground station and is avaliable for data downlink/uplink.
% FUTURE: Does the same for the rest of the targets on when it is able to
% take pictures and returns the angle of elevation of the sun for optimal
% picture taking. Returns a whole schedule for the satellite to follow
% provided it does not have an emergency.

excelfile = 'C:\Users\geoki\Desktop\SSRL\Master-List.xlsx';

%reads the excel file
data = readcell(excelfile);

% makes a new variable, then clears the first row
latandlong = data;
latandlong(1,:) = [];

% seperates the latitudes, longitudes, and names for each target
lat = cell2mat(latandlong(:,12)');
long = cell2mat(latandlong(:,13)');
names = cellstr(latandlong(:,1)');

% sets up the specified datetime range
startTime = datetime(2020,5,13,13,0,0);
stopTime = startTime + hours(6);
sampleTime = 30; %seconds

% adds the specified datetime range to a new satelliteScenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% makes the UGA groundstation fro data uplink and downlink from MOCI
minElevationAngle = 22;
name = "UGA";
gs = groundStation(sc, lat(84), long(84), ...
    'Name', name, ...
    'minElevationAngle',minElevationAngle);
lat(84) = [];
long(84) = [];
names(84) = [];
groundstations = gs;

%Parses through the ground stations giving each of them a name and
%location, adds them all to a new groundstations row vecor
for i = 1:length(lat)
    name = names(1,i);
    gs = groundStation(sc,lat(i),long(i), ...
        'Name', name);
    groundstations = [groundstations, gs];
end

% retrieves the two line element data from a tle file and adds it to the
% satellite scenario.
tleFile = "C:\Users\geoki\Desktop\SSRL\ZARYA.tle";
sat = satellite(sc,tleFile);

% adds a new camera to the stellite with a field of view of 2.1 degrees
name = sat.Name + " Camera";
cam = conicalSensor(sat, "Name",name,"MaxViewAngle",2.1);

% THIS AND ABOVE WORKS retrieves the access intervals for when the satellite passes over
% UGA and is in view of the satellite dish
ac = access(sat, groundstations(1));
intvls = accessIntervals(ac);
intvls2 = intvls;

% WORK IN PROGRESS, adds the rest of the groundstation accesses for when
% the satellite passes over each groundstatin and is in view of the camera
for i = 2:length(groundstations)
    ac = access(cam, groundstations(i));
    intvls2 = [intvls2;accessIntervals(ac)];
end
% should end up with intvls2 being a 86x8 table with the same values as
% intvls but for the different groundstations


% Found these two lines of code, they dont seem to work for what we want, but right now nothing is. 
% ac = [cam.Accesses];
% intvls2 = accessIntervals(ac);

% WORK IN PROGRESS should display the simulation showing all the groundstations and the
% satellite orbit
% fieldOfView(cam);
% try
%     v = satelliteScenarioViewer(sc);
% catch
% end
