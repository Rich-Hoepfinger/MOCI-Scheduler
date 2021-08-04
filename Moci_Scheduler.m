% Author: Richard Hoepfinger, Ryan Hughes.
% Emails: richhoepfinger@gmail.com, rh39658@uga.edu
% FOR: UGA Small Satellite Research Lab.
% WORKS: Reads an excel file containing the locations of targets and a tle for a
% specified satellite. Makes a scheduler for when the satellite is above
% the UGA ground station and is avaliable for data downlink/uplink.
% FUTURE: Does the same for the rest of the targets on when it is able to
% take pictures and returns the angle of elevation of the sun for optimal
% picture taking. Returns a whole schedule for the satellite to follow
% provided it does not have an emergency.

targets = 'target_list.csv';

% Reads the excel file
data = readcell(targets);

% Makes a new variable
latandlong = data;

% seperates the latitudes, longitudes, and names for each target
lat = cell2mat(latandlong(:,2)');
long = cell2mat(latandlong(:,3)');
names = cellstr(latandlong(:,1)');


% sets up the specified datetime range

startTime = datetime(2021,6,10,0,0,0);
stopTime = startTime + hours(6);
sampleTime = 10; %seconds

% adds the specified datetime range to a new satelliteScenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% makes the UGA groundstation for data uplink and downlink from MOCI
minElevationAngle = 25;
name = 'Ground_Station';
gs = groundStation(sc, lat(84), long(84), ...
    'Name', name, ...
    'minElevationAngle', minElevationAngle);
lat(84) = [];
long(84) = [];
names(84) = [];

gsList = [gs];

% Parses through the ground stations giving each of them a name and
% location, adds them all to a new groundstations row vecor
for i = 1:length(lat)
    name = names(i);
    gs = groundStation(sc,lat(i),long(i), ...
        'Name', name, 'MinElevationAngle', minElevationAngle);
    gsList = [gsList, gs];
end

% adding moci satellite into simulation using 97 inclination and 500 km
% circular orbit
semiMajorAxis = 6878000;
eccentricity = 0;
inclination = 97;
rightAscentionOfAscendingNode = 0;
argumentOfPeriapsis = 0;
trueAnomaly = 0;

moci = satellite(sc,semiMajorAxis,eccentricity,inclination, ... 
    rightAscentionOfAscendingNode, argumentOfPeriapsis, trueAnomaly, ...
    "Name", "MOCI"); 

% adds a new camera to the stellite with a field of view of 4.8 degrees
camName = moci.Name + " Camera";
cam = conicalSensor(moci, "Name" , camName, "MaxViewAngle", 4.8, ...
    "MountingAngles", [0; 0; 0]);

% Creating table of access intervals (targets and GS) and writing to a text file
% To get the correct intervals, this should be between the camera and the
% list of ground stations, however due to the small FOV of the camera I get
% no access intervals when computing between the camera and the GS list over
% one day, which aleady takes about 15 min and I am not willing to wait
% hours to get a access file while problem shooting. Just computed LOS
% access between MOCI and GS list to have sample text file for scheduler. 

acs = [];
for i = 1:86 
    event = access(moci, gsList(i));
    acs = [acs, event];
end

intervals = accessIntervals(acs);

%Calculating the maximum elevation between satellite and target during
%passover

%MOCIelevations = []

%elevInter = 'testIntervals.csv';
%elevdata = readcell(elevInter);
%elevdatanew = elevdata;

%startTimes = cell2mat(elevdatanew(:,1)');
%endTimes = cell2mat(elevdatanew(:,2)');
%targetNames = cellstr(elevdatanew(:,3)');

%for i = 1:length(startTimes)
%    %Target name as string
%    targetInitial = targetNames(i);
%    
%    %Finding ground station object corresponding to specific name
%    for j = 1:length(lat)
%        if gsList(j).Name == targetInitial
%            target = gsList(j);
%        end
%    end
%    
%    %Start of interval as datetime
%    timeOne = startTimes(i)
%   
%   %End of interval as datetime
%    timeTwo = endTimes(i);
%    
%   %Determing max elevation over interval
%    maxEl = 0;
%    while timeOne < timeTwo
%        [az, elev, r] = aer(target, moci, timeOne);
%        if elev > maxEl
%            maxEl = elev;
%       timeOne + seconds(1);
%        
%    %Appending elevation and repective target to the list of elevations
%    MOCIelevations = [MOCIelevations; targetFinal, maxEl];
%end

%Writing list of satellite elevations to text file
%T3 = array2table(MOCIelevations)

%writetable(T3, 'elevations.txt')

%Calculating the maxiumum elevation between sun and target during passover
% --------UNTESTED------------

%SUNelevations = []

%for i = 2:length(intervals)
%    for j = 1:length(lat)
%        if intervals[j][2] == bigdata[j][3]
%            la = bigdata[j][1];
%            lo = bigdata[j][2];
%        end
%    end
%    [Az El] = SolarAzEl(intervals[i][4], la, lo, 0)
%    elevation = [El]
%    SUNelevatons = [SUNelevations, El]
%end

% Formatting table in order to write to text file of raw data 
T1 = array2table(intervals);

T2 = splitvars(T1);

sortedArray = sortrows(T2,4);

i = 2;
while i <= height(sortedArray)
    tupper = sortedArray{i-1,5};
    tlower = sortedArray{i-1,4};
    t = sortedArray{i,4};
    tf = isbetween(t,tlower,tupper);
    if tf == 1
        sortedArray(i,:) = [];
        currentheight = height(sortedArray);
        i = i - 1;
    end
    i = i + 1;
end


writetable(sortedArray, 'access.txt');






% Visualizing the scenario and making the MOCI Cameras FOV visible

%v = satelliteScenarioViewer(sc);
%fov = fieldOfView(cam([cam.Name] == "MOCI Camera"));




















% WORK IN PROGRESS, adds the rest of the groundstation accesses for when
% the satellite passes over each groundstatin and is in view of the camera
%for i = 2:length(groundstations)
%    ac = access(cam, groundstations(i));
%    intvls2 = [intvls2;accessIntervals(ac)];
%end
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


% Function that will take in an unordered access file following the form 
% NAME STARTTIME ENDTIME
% function [ordered] = order[unordered]
    
