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


% --------UNTESTED----------
% bigdata = [];
% for i = 1:length(lat)
%     toAdd = [lat(i), long(i), names(i)]
%     bigdata = [bigdata; toAdd]
% end

% bigdata

% sets up the specified datetime range

startTime = datetime(2021,5,25,0,0,0);
stopTime = startTime + days(10);
sampleTime = 30; %seconds

% adds the specified datetime range to a new satelliteScenario
sc = satelliteScenario(startTime,stopTime,sampleTime);

% makes the UGA groundstation for data uplink and downlink from MOCI
minElevationAngle = 25;
name = names(84);
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

intervals = [];
for i = 1:86 
    event = access(cam, gsList(i));
    intvls = accessIntervals(event);
    intervals = [intervals; intvls];
end


%Calculating the maximum elevation between satellite and target during
%passover -----UNTESTED--------

% MOCIelevations = []

% for i = 2:length(intervals)
%     [el] = aer(intervals[i][2], moci, intervals[i][4]);
%     MOCIelevations = [MOCIelevations, intervals[i][2], el];
% end

% T3 = array2table(MOCIelevations)
% 
% writetable(T3, 'elevations.txt')

%Calculating the maxiumum elevation between sun and target during passover
% --------UNTESTED------------

% SUNelevations = []

% for i = 2:length(intervals)
%     for j = 1:length(lat)
%         if intervals[j][2] == bigdata[j][3]
%             la = bigdata[j][1];
%             lo = bigdata[j][2];
%         end
%     end
%     [Az El] = SolarAzEl(intervals[i][4], la, lo, 0)
%     elevation = [El]
%     SUNelevatons = [SUNelevations, El]
% end

% Formatting table in order to write to text file of raw data 
T1 = array2table(intervals)

T2 = splitvars(T1)

writetable(T2, 'access.txt');

% Cleaning up / ordering access data. This will be done via a python script
% using the scheduler functions that Conor already wrote a while back and
% are the same ones used in the SPOC STK Scheduler script. The idea for the
% matlab script, as i see it, is to produce the data. Then, using the
% python functions already written, we can create the schedule. 




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
    
