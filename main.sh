#! /bin/bash

# Busfahrplan-Shell-Script von Wolfram Reinke und Nils Rohde
# Emails:	WolframReinke@web.de
#		nils.rohde@core-control.de 

# Diese Funktion schreibt die Hilfenachricht auf die Ausgabe
function printHelpMessage(){
	echo "";
	echo "Busfahrplan-Script von Wolfram Reinke und Nils Rohde";
	echo "Benutzung:";
	echo -e "\tbfp.sh -s <Starthaltestelle> -z <Zielhaltestelle> [-t <Abfahrtszeit>] [-f] [-r] [-v]";
	echo "";
	echo "Parameter:";
	echo -e "\t-s\tDie Starthaltestelle der Suche. Bitte geben Sie die Starthaltestelle in";
	echo -e "\t  \tAnführungszeichen an.";
	echo -e "\t-z\tDie Zielhaltestelle der Suche. Bitte geben Sie die Zielhaltestelle in";
	echo -e "\t  \tAnführungszeichen an.";
	echo -e "\t-t\tDie Abfahrtszeit. Wenn keine Zeit angegeben wird, wird die aktuelle Zeit verwendet.";
	echo -e "\t  \tFormat: hh:mm.";
	echo -e "\t-h\tZeigt diese Hilfenachricht.";
	echo -e "\t-f\tDie Werte für <Starthaltestelle> und <Zielhaltestelle> werden als Favorit gespeichert.";
	echo -e "\t  \tWenn bei einer späteren Suche diese Parameter wegelassen werden, werden die Favorit-";
	echo -e "\t  \tParameter verwendet."
	echo -e "\t-r\tLöscht die Favorit-Parameter, sodass beim Start wieder <Starthaltestelle> und";
	echo -e "\t  \t<Zielhaltestelle> angegeben werden müssen.";
	echo -e "\t-q\tUnterdrückt Status-Ausgaben auf die Standardausgabe. So können die Busdaten leichter";
	echo -e "\t  \tin eine Datei umgeleitet werden.";
	echo "";
}

# Favoriten-Datei
favorites="bfp.fav";

# Werte vorbelegen, um zu testen, ob der Benutzer etwas eingeben hat
departure="nil";
arrival="nil";
favorit="false";
quite="false";

# Benutzereingaben abfragen
while getopts hs:z:t:frq input
do
	case $input in
		
		# Hilfe anzeigen
		h)	printHelpMessage;
			exit;;
		
		# Starthaltestelle angegeben
		s)  	departure=$OPTARG;;
		
		# Zielhaltestelle angegeben
		z)	arrival=$OPTARG;;
		
		# Abfahrtszeit angegeben
		t)	time=$OPTARG;;
		
		# Benutzer will die Eingabe als favorit speichern
		f)	favorit="true";;
		
		# Favorit resetten
		r)	rm "$favorites" 2> /dev/null \
			    && echo -e "Ihr Such-Favorit wurde gelöscht.\n" \
			    || echo -e "Ihr Such-Favorit war bereits gelöscht.\n" ;
			exit;;
		
		# Ausgaben auf die Standardausgabe sollen unterdrückt werden
		q)	quite="true";;
		
		# sonst Hilfenachricht anzeigen und exit
		\?) 	printHelpMessage;
			exit;;
		
	esac
done

# Hat der Benutzer Start und Ziel angegeben?
if ([ "$departure" = "nil" ] || [ "$arrival" = "nil" ])
then
    # Wenn nicht, dann wird in den Favoriten nach den benötigten Daten geschaut.
    if [ -e "$favorites" ] 
    then
	# Wenn beim laden der Favoriten etwas daneben geht, wird die Datei gelöscht
	# und der Benutzer über den Fehler informiert.
	departure=$(cat "$favorites" | head -n 1) \
	      || { echo "Ihr Such-Favorit konnte nicht aus $favorites geladen werden." 1>&2; rm "$favorites" 2> /dev/null; exit; }
	arrival=$(cat "$favorites" | head -n 2 | tail -n 1) \
	      || { echo "Ihr Such-Favorit konnte nicht aus $favorites geladen werden." 1>&2; rm "$favorites" 2> /dev/null; exit; }
    else
	# Stehen die Daten nicht in den Favoriten, dann werden Fehlermeldungen und die Hilfe
	# angezeigt.
	
	echo "";
	if [ "$departure" = "nil" ]
	then
	    echo "Sie müssen eine Starthaltestelle angeben oder als Favorit speichern (siehe Hilfe)" 1>&2;
	fi
	
	if [ "$arrival" = "nil" ]
	then
	    echo "Sie müssen eine Zielhaltestelle angeben oder als Favorit speichern (siehe Hilfe)" 1>&2;
	fi
	echo "";
	
	printHelpMessage;
	exit;
    fi
fi

if [ "$favorit" = "true" ]
then
    echo $departure > "$favorites";
    echo $arrival >> "$favorites";
    
    # Ausgabe unterdrücken?
    if [ "$quite" = "false" ]
    then
	echo "Ihre Suche wurde als Favorit gespeichert.";
    fi
fi

# Wenn der User keine Zeit eingegeben hat, dann aktuelle Zeit verwenden.
if [ -z "$time" ]
then
    time=$(date +%H:%M);
fi

# aktuelles Datum verwenden. 
currentDate=$(date +%a%%2C+%d.%m.%g | sed s/Tue/Di/ | sed s/Wed/Mi/ | sed s/Th/Do/ | sed s/Sat/Sa/ | sed s/Su/So/ | sed s/Mon/Mo/);

# URL-Encoding auf die Eingaben anwenden, um Sonderzeichen wie Umlaute zu erlauben.
departure=$(echo -n "$departure" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg');
arrival=$(echo -n "$arrival" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg');
time=$(echo -n "$time" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg');

# URL konstruieren
url="http://reiseauskunft.bahn.de/bin/query.exe/dn?revia=yes&existOptimizePrice=1&country=DEU&dbkanal_007=L01_S01_D001_KIN0001_qf-bahn_LZ003&ignoreTypeCheck=yes&S=$departure&REQ0JourneyStopsSID=&REQ0JourneyStopsS0A=7&Z=$arrival&REQ0JourneyStopsZID=&REQ0JourneyStopsZ0A=7&trip-type=single&date=$currentDate&time=$time&timesel=depart&returnTimesel=depart&optimize=0&travelProfile=-1&adult-number=1&children-number=0&infant-number=0&tariffTravellerType.1=E&tariffTravellerReductionClass.1=0&tariffTravellerAge.1=&qf-trav-bday-1=&tariffTravellerReductionClass.2=0&tariffTravellerReductionClass.3=0&tariffTravellerReductionClass.4=0&tariffTravellerReductionClass.5=0&tariffClass=2&start=1&qf.bahn.button.suchen="

# Ausgabe unterdrücken?
if [ "$quite" = "false" ]
then
    echo "Ihre Anfrage wird bearbeitet...";
    echo "";
fi

tmpFile="/tmp/fpl.html";		# Datei, in die die heruntergeladene Seite gespeichert wird.
wget -O $tmpFile "$url" 2> /dev/null \
      || { echo "Die benötigten Daten konnten nicht geladen werden." 1>&2; exit; }

# Tabellenkopf ausgeben
printf "%-40s %-40s %-15s %-15s %-8s %-20s \n" "Startbahnhof" "Zielbahnhof" "Abfahrtszeit" "Ankunftszeit" "Dauer" "Verkehrsmittel";
echo -e "-----------------------------------------------------------------------------------------------------------------------------------------";

anzahlDurchlaeufe=3;	# Anzahl der Reisemöglichkeiten (die Deutsche Bahn Seite enthält immer 3 Reisemöglichkeiten)
timeGet=1;		# Die DB-Seite speichert An- und Ab-Zeit beide unter einem <td class="time"> Tag, daher muss hier
			# extra mitgezählt werden.
		
# Tabelle laden und ausgeben
for (( i=1; i<=$anzahlDurchlaeufe; i++ ))
do
	# Starthaltestelle, Zielhaltestelle, Dauer und Anbieter aus der HTML-Seite greppen
	startBhf=$(grep -Pzio '<div class="resultDep">\n(.*?)\n</div>' $tmpFile | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | head -n $i | tail -n 1);
	zielBhf=$(grep -Pzio '<td class="station stationDest pointer".*?>\n(.*?)\n</td>' $tmpFile | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | head -n $i | tail -n 1);
	duration=$(grep -Pzio '<td class="duration lastrow".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | head -n $i | tail -n 1);
	provider=$(grep -Pzio '<td class="products lastrow".*?>\n?(.*?)\n?</td>' $tmpFile | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | head -n $i | tail -n 1);
	
	# Die Abfahrtszeit greppen
	timeAb=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	
	# Auf der DB-Seite werden auch die Verspätungen angezeigt. Diese fangen mit + oder - an und
	# werden hier ausgefiltert
	if ([ ${timeAb:0:1} = "+" ] || [ ${timeAb:0:1} = "-" ])
	then	
	
	  # Zeit neu laden, da sonst die Verspätungen statt der Zeit ausgegeben würde. Der nächste Treffer von grep ist
	  # garantiert keine Verspätungsangabe mehr, die kommen immer abwechselnd
	  let	timeGet=$timeGet+1;	
	  timeAb=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	fi
	
	# Zähler hochzählen für die Ankunftszeit
	let timeGet=$timeGet+1;
	
	# Die Ankunftszeit greppen
	timeAn=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);
	
	# Auf der DB-Seite werden auch die Verspätungen angezeigt. Diese fangen mit + oder - an und
	# werden hier ausgefiltert
	if ([ ${timeAn:0:1} = "+" ] || [ ${timeAn:0:1} = "-" ])
	then
	  # Und wieder die Zeit neu laden.
	  let	timeGet=$timeGet+1;
	  timeAn=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $tmpFile | grep -Pzio '\d{1,2}\:\d{1,2}' | head -n $timeGet | tail -n 1);				
	fi
	
	# Zähler für den nächsten Schleifendurchlauf hochzählen
	let timeGet=$timeGet+1;
	
	# Die grade geladene Reisemöglichkeit ausgeben
	printf "%-40s %-40s %-15s %-15s %-8s %-20s" "$startBhf" "$zielBhf" $timeAb $timeAn $duration $provider;
	echo "";
done

# Leerzeile
echo "";




