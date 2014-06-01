#! /bin/bash

# Busfahrplan-Shell-Script von Wolfram Reinke und Nils Rohde
# Emails:	WolframReinke@web.de
#			nils.rohde@core-control.de 

# Diese Funktion gibt die n-te Zeile der Eingabe zurück.
# Beispiel: cat test.txt | index 2 gibt die 2. Zeile zurück.
function index
{
	head -n $1 $2 | tail -n1
}

# Diese Funktion schreibt die Hilfenachricht auf die Ausgabe
function printHelpMessage
{
	echo ""
	echo "Busfahrplan-Script von Wolfram Reinke und Nils Rohde"
	echo "Benutzung:"
	echo -e "\tbfp.sh -s <Starthaltestelle> -z <Zielhaltestelle> [-t <Abfahrtszeit>] [-d|-a] [-f] [-r] [-v] "
	echo ""
	echo "Parameter:"
	echo -e "\t-s\tDie Starthaltestelle der Suche. Bitte geben Sie die Starthaltestelle in"
	echo -e "\t  \tAnführungszeichen an."
	echo -e "\t-z\tDie Zielhaltestelle der Suche. Bitte geben Sie die Zielhaltestelle in"
	echo -e "\t  \tAnführungszeichen an."
	echo -e "\t-t\tDie Abfahrtszeit. Wenn keine Zeit angegeben wird, wird die aktuelle Zeit verwendet."
	echo -e "\t  \tFormat: hh:mm."
	echo -e "\t-d\tLegt fest, dass die gegebene Zeit die gewünschte Abfahrtszeit ist. Das Gegenteil "
	echo -e "\t  \tdieser Option ist -a. Wird keine dieser Optionen angegeben, wird -d gewählt."
	echo -e "\t-a\tLegt fest, dass die gegebene Zeit die gewünschte Ankunftszeit ist. Das Gegenteil "
	echo -e "\t  \tdieser Option ist -d. Wird keine dieser Optionen angegeben, wird -d gewählt."
	echo -e "\t-h\tZeigt diese Hilfenachricht.";
	echo -e "\t-f\tDie Werte für <Starthaltestelle> und <Zielhaltestelle> werden als Favorit gespeichert."
	echo -e "\t  \tWenn bei einer späteren Suche diese Parameter wegelassen werden, werden die Favorit-"
	echo -e "\t  \tParameter verwendet."
	echo -e "\t-r\tLöscht die Favorit-Parameter, sodass beim Start wieder <Starthaltestelle> und"
	echo -e "\t  \t<Zielhaltestelle> angegeben werden müssen."
	echo -e "\t-q\tUnterdrückt Status-Ausgaben auf die Standardausgabe. So können die Busdaten leichter"
	echo -e "\t  \tin eine Datei umgeleitet werden."
	echo ""
}

# Favoriten-Datei
FAV_FILE="$HOME/.bfp.fav"

# Werte vorbelegen, um zu testen, ob der Benutzer etwas eingeben hat
START="nil"
DEST="nil"
FAVORITE="false"
SILENT="false"
MODE="depart"

# Benutzereingaben abfragen
while getopts hs:z:t:adfrq INPUT
do
	case $INPUT in
		
	# Hilfe anzeigen
	h)	printHelpMessage;
		exit;;
	
	# Starthaltestelle angegeben
	s)  START=$OPTARG;;
	
	# Zielhaltestelle angegeben
	z)	DEST=$OPTARG;;
	
	# Abfahrts-/Ankunftszeit angegeben
	t)	TIME=$OPTARG;;
	
	# Die gegebene Zeit ist die Abfahrtszeit. Dieser Wert wird direkt von 
	# bahn.de verwendet.
	a)	MODE="arrive";;
			
	# Die gegebene Zeit ist die Ankunftszeit. Dieser Wert wird direkt von
	# bahn.de verwendet,
	d)	MODE="depart";;
	
	# Benutzer will die Eingabe als favorit speichern
	f)	FAVORITE="true";;
	
	# Favorit resetten
	r)	rm "$FAV_FILE" 2> /dev/null \
		    && echo -e "Ihr Such-Favorit wurde gelöscht.\n" \
		    || echo -e "Ihr Such-Favorit war bereits gelöscht.\n" ;
		exit;;
	
	# Ausgaben auf die Standardausgabe sollen unterdrückt werden
	q)	SILENT="true";;
	
	# sonst Hilfenachricht anzeigen und exit
	\?) printHelpMessage;
		exit;;
		
	esac
done

# Wenn der Benutzer keine Zeit eingegeben hat, dann aktuelle Zeit verwenden.
if [ -z "$TIME" ]
then
    TIME=$(date +%H:%M)
fi

# Zeigt dem Benutzer die gewählte Zeit noch einmal an, und teilt ihm mit,
# ob es die Ankunfts- oder die Abfahrtszeit ist.
if [ "$MODE" = "depart" -a "$SILENT" = "false" ]
then
	echo "Abfahrtszeit: $TIME"
else
	echo "Ankunftszeit: $TIME"
fi

# Hat der Benutzer Start und Ziel angegeben?
if ([ "$START" = "nil" ] || [ "$DEST" = "nil" ])
then
    # Wenn nicht, dann wird in den Favoriten nach den benötigten Daten geschaut.
    if [ -e "$FAV_FILE" ] 
    then
		# Wenn beim laden der Favoriten etwas daneben geht, wird die Datei gelöscht
		# und der Benutzer über den Fehler informiert.
		START=$(cat "$FAV_FILE" | index 1) \
		|| { echo "Ihr Such-Favorit konnte nicht aus $FAV_FILE geladen werden." 1>&2; rm "$FAV_FILE" 2> /dev/null; exit; }
		DEST=$(cat "$FAV_FILE" | index 2) \
		|| { echo "Ihr Such-Favorit konnte nicht aus $FAV_FILE geladen werden." 1>&2; rm "$FAV_FILE" 2> /dev/null; exit; }
	else
		# Stehen die Daten nicht in den Favoriten, dann werden Fehlermeldungen und die Hilfe
		# angezeigt.
		echo ""
		
		if [ "$START" = "nil" ]
		then
			echo "Sie müssen eine Starthaltestelle angeben oder als Favorit speichern (siehe Hilfe)" 1>&2
		fi
	
		if [ "$DEST" = "nil" ]
		then
			echo "Sie müssen eine Zielhaltestelle angeben oder als Favorit speichern (siehe Hilfe)" 1>&2
		fi
		
		echo ""
		printHelpMessage
		exit
    fi
fi

if [ "$FAVORITE" = "true" ]
then
    echo $START > "$FAV_FILE"
    echo $DEST >> "$FAV_FILE"
    
    # Ausgabe unterdrücken?
    if [ "$SILENT" = "false" ]
    then
		echo "Ihre Suche wurde als Favorit gespeichert."
    fi
fi

# aktuelles Datum verwenden. 
CURRENT_DATE=$(date +%a%%2C+%d.%m.%g | sed s/Tue/Di/ | sed s/Wed/Mi/ | sed s/Th/Do/ | sed s/Sat/Sa/ | sed s/Su/So/ | sed s/Mon/Mo/)

# URL-Encoding auf die Eingaben anwenden, um Sonderzeichen wie Umlaute zu erlauben.
START=$(echo -n "$START" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
DEST=$(echo -n "$DEST" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')
TIME=$(echo -n "$TIME" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg')

# URL konstruieren
URL="http://reiseauskunft.bahn.de/bin/query.exe/dn?revia=yes&existOptimizePrice=1&country=DEU&dbkanal_007=L01_S01_D001_KIN0001_qf-bahn_LZ003&ignoreTypeCheck=yes&S=$START&REQ0JourneyStopsSID=&REQ0JourneyStopsS0A=7&Z=$DEST&REQ0JourneyStopsZID=&REQ0JourneyStopsZ0A=7&trip-type=single&date=$CURRENT_DATE&time=$TIME&timesel=$MODE&returnTimesel=depart&optimize=0&travelProfile=-1&adult-number=1&children-number=0&infant-number=0&tariffTravellerType.1=E&tariffTravellerReductionClass.1=0&tariffTravellerAge.1=&qf-trav-bday-1=&tariffTravellerReductionClass.2=0&tariffTravellerReductionClass.3=0&tariffTravellerReductionClass.4=0&tariffTravellerReductionClass.5=0&tariffClass=2&start=1&qf.bahn.button.suchen="

# Ausgabe unterdrücken?
if [ "$SILENT" = "false" ]
then
    echo "Ihre Anfrage wird bearbeitet..."
    echo ""
fi

HTML_FILE="/tmp/fpl.html"		# Datei, in die die heruntergeladene Seite gespeichert wird.
wget -O "$HTML_FILE" "$URL" 2> /dev/null \
      || { echo "Die benötigten Daten konnten nicht geladen werden." 1>&2; exit; }
      
if [ -z "$(grep -Pzio '(?<=<div class=\"resultDep\">\n)(.*?)(?=\n</div>)' $HTML_FILE)" ]
then
	echo -e "reiseauskunft.bahn.de konnte Ihre Anfrage nicht bearbeiten.\n" 1>&2
	exit
fi

# Tabellenkopf ausgeben
printf "%-40s %-40s %-15s %-15s %-8s %-20s \n" "Startbahnhof" "Zielbahnhof" "Abfahrtszeit" "Ankunftszeit" "Dauer" "Verkehrsmittel"
echo -e "-----------------------------------------------------------------------------------------------------------------------------------------"

COUNT=3			# Anzahl der Reisemöglichkeiten (die Deutsche Bahn Seite enthält immer 3 Reisemöglichkeiten)
TIME_INDEX=1	# Die DB-Seite speichert An- und Ab-Zeit beide unter einem <td class="time"> Tag, daher muss hier
				# extra mitgezählt werden.
		
# Tabelle laden und ausgeben
for (( i=1; i<=$COUNT; i++ ))
do
	# grep Parameter:
	# 	P - Verwendung der Syntax für Reguläre Ausdrücke wie in Perl. Die benötigten Konstrukte lookahead und lookbehind stünden
	#		sonst nicht zur Verfügung.
	# 	z -	Multiline Mode wird aktiviert, da sich die Suchmuster über mehrere Zeilen erstrecken.
	# 	i - Groß-/Kleinschreibung wird ignoriert.
	# 	o -	Gibt nur Treffer aus, nicht die ganze Zeile. Da -z quasi alle Zeilen in eine Zeile schreibt, würde ohne diese
	#		Option jedes mal die ganze Datei zurückgegeben werden.

	# Starthaltestelle, Zielhaltestelle, Dauer und Anbieter aus der HTML-Seite greppen
	STATION_START=$(grep -Pzio '<div class="resultDep">\n(.*?)\n</div>' $HTML_FILE | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | index $i)
	STATION_DEST=$(grep -Pzio '<td class="station stationDest pointer".*?>\n(.*?)\n</td>' $HTML_FILE | grep -Pzio '(?<=>\n)(.*?)(?=\n<)' | index $i)
	DURATION=$(grep -Pzio '<td class="duration lastrow".*?>\n?(.*?)\n?</td>' $HTML_FILE | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | index $i)
	PROVIDER=$(grep -Pzio '<td class="products lastrow".*?>\n?(.*?)\n?</td>' $HTML_FILE | grep -Pzio '(?<=(>|\n))(.*?)(?=(\n|<))' | index $i)
	
	# Die Abfahrtszeit greppen
	TIME_DEPARTURE=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $HTML_FILE | grep -Pzio '\d{1,2}\:\d{1,2}' | index $TIME_INDEX)
	
	# Auf der DB-Seite werden auch die Verspätungen angezeigt. Diese fangen mit + oder - an und
	# werden hier ausgefiltert
	if ([ ${TIME_DEPARTURE:0:1} = "+" ] || [ ${TIME_DEPARTURE:0:1} = "-" ])
	then	
	
	  # Zeit neu laden, da sonst die Verspätungen statt der Zeit ausgegeben würde. Der nächste Treffer von grep ist
	  # garantiert keine Verspätungsangabe mehr, die kommen immer abwechselnd
	  let TIME_INDEX=$TIME_INDEX+1
	  TIME_DEPARTURE=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $HTML_FILE | grep -Pzio '\d{1,2}\:\d{1,2}' | index $TIME_INDEX)
	fi
	
	# Zähler hochzählen für die Ankunftszeit
	let TIME_INDEX=$TIME_INDEX+1
	
	# Die Ankunftszeit greppen
	TIME_ARRIVAL=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $HTML_FILE | grep -Pzio '\d{1,2}\:\d{1,2}' | index $TIME_INDEX)
	
	# Auf der DB-Seite werden auch die Verspätungen angezeigt. Diese fangen mit + oder - an und
	# werden hier ausgefiltert
	if ([ ${TIME_ARRIVAL:0:1} = "+" ] || [ ${TIME_ARRIVAL:0:1} = "-" ])
	then
	  # Und wieder die Zeit neu laden.
	  let TIME_INDEX=$TIME_INDEX+1
	  TIME_ARRIVAL=$(grep -Pzio '<td class="time".*?>\n?(.*?)\n?.*?</td>' $HTML_FILE | grep -Pzio '\d{1,2}\:\d{1,2}' | index $TIME_INDEX)				
	fi
	
	# Zähler für den nächsten Schleifendurchlauf hochzählen
	let TIME_INDEX=$TIME_INDEX+1
	
	# Die geladenen Werte können nocht HTML-Tags und HTML-Codes enthalten. Diese werden hiermit entfernt
	STATION_START=$(echo "$STATION_START" | w3m -dump -T text/html)
	STATION_DEST=$(echo "$STATION_DEST" | w3m -dump -T text/html)
	PROVIDER=$(echo "$PROVIDER" | w3m -dump -T text/html)
	
	# Die grade geladene Reisemöglichkeit ausgeben
	printf "%-40s %-40s %-15s %-15s %-8s %-20s" "$STATION_START" "$STATION_DEST" "$TIME_DEPARTURE" "$TIME_ARRIVAL" "$DURATION" "$PROVIDER"
	echo ""
done

# Leerzeile ausgeben und temporäre Datei wieder löschen
echo ""
rm $HTML_FILE




