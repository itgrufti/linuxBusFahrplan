#! /bin/bash

# =======================================================================================================================
# Title:		Bus- und Bahnfahrplan
# Authors:		Reinke, Wolfram & Rohde, Nils		
# Created:		14/05/15
# Last Revised:	14/05/15
#
# This comment is under construction
# (c)2014 under beerware license
# =======================================================================================================================

function printHelpMessage(){
		echo "Test";
}

while getopts hd:a:t: input
do
	case $input in
		
		h)	printHelpMessage;
			exit;;
		
		d)  departure=$OPTARG;;
		
		a)	arrival=$OPTARG;;
		
		t)	time=$OPTARG;;
		
		\?) printHelpMessage;
			exit;;
		
	esac
done

if [ -z "$time" ]
then
	time=$(date +%H:%M);
fi
echo "DEBUG"
echo $departure;
echo $arrival;
echo "END_DEBUG"


currentDate=$(date +%a%%2C+%d.%m.%g | sed s/Tue/Di/ | sed s/Wed/Mi/ | sed s/Th/Do/ | sed s/Sat/Sa/ | sed s/Su/So/ | sed s/Mon/Mo/);

url="http://reiseauskunft.bahn.de/bin/query.exe/dn?revia=yes&existOptimizePrice=1&country=DEU&dbkanal_007=L01_S01_D001_KIN0001_qf-bahn_LZ003&ignoreTypeCheck=yes&S=$departure&REQ0JourneyStopsSID=&REQ0JourneyStopsS0A=7&Z=$arrival&REQ0JourneyStopsZID=&REQ0JourneyStopsZ0A=7&trip-type=single&date=$currentDate&time=$time&timesel=depart&returnTimesel=depart&optimize=0&travelProfile=-1&adult-number=1&children-number=0&infant-number=0&tariffTravellerType.1=E&tariffTravellerReductionClass.1=0&tariffTravellerAge.1=&qf-trav-bday-1=&tariffTravellerReductionClass.2=0&tariffTravellerReductionClass.3=0&tariffTravellerReductionClass.4=0&tariffTravellerReductionClass.5=0&tariffClass=2&start=1&qf.bahn.button.suchen="

echo "Processing request...";

tmpFile="/tmp/fpl.html";
wget -O $tmpFile "$url" 2> /dev/null;
anzahlDurchlaeufe=3;
timeGet=2;
echo "Startbahnhof                      |Zielbahnhof                    |Abfahrtszeit |Ankunftszeit |Dauer  |Provider";
echo "----------------------------------|-------------------------------|-------------|-------------|-------|----------";
for (( i=1; i<=$anzahlDurchlaeufe; i++ ))
do
	startBhf=$(grep -Pzio '<div class="resultDep">\n(.*?)\n</div>' $tmpFile | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | head -n $i | tail -n 1);
	zielBhf=$(grep -Pzio '<td class="station stationDest pointer".*?>\n(.*?)\n</td>' $tmpFile | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | head -n $i | tail -n 1);
	
	duration=$(grep -Pzio '<td class="duration lastrow".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | head -n $i | tail -n 1);
	
	provider=$(grep -Pzio '<td class="products lastrow".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | head -n $i | tail -n 1);
	
	
	#timeAb=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '(?<=(>|\n))(.*?)(?=\n?(\&nbsp\;)?<[s\/])(?<!<\/s)' | head -n $timeGet | tail -n 1);
	timeAb=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	if ([ ${timeAb:0:1} = "+" ] || [ ${timeAb:0:1} = "-" ])
	then		

			let	timeGet=$timeGet+1;	
	timeAb=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	fi
	let timeGet=$timeGet+1;
	timeAn=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	
	if ([ ${timeAn:0:1} = "+" ] || [ ${timeAn:0:1} = "-" ])
	then
			let	timeGet=$timeGet+1;
	timeAn=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
					
	fi
	let timeGet=$timeGet+1;
	echo "$startBhf $zielBhf     $timeAb    $timeAn   $duration  $provider";
	
done

echo "This script is under construction";


