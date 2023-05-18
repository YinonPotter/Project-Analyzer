#!/bin/bash

#Yinon Potter Windows Forencics Project
#Student Code: s25
#Lecturer's name: Adonis Azzam
#Class Code: 7736/10

#Colors used in the script:
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
PINK='"\033[38;5;206m'
RESET='\e[0m'


#Check if the script was ran using the root user, if not exit the script
function rootcheck() {
if [ $(whoami) != "root" ]
then
	echo -e "$RED This Script Must Be Run As Root. $RESET"
	exit
fi
}

#Ask the user to input a selected file
function specifyfile() {
echo -e "$WHITE Please Enter A File To Analyze ( please enter full path): $RESET"
read filename
#Check if the file exists and if not call the function again to ask the user to input another file
if [ ! -f "$filename" ]
then
	echo -e "$RED The File Was Not Found $RESET"
	specifyfile
fi
}
#Check if Bulk_extractor is installed and if not update the system and install it
function bulk_check() {
be=$(dpkg -s bulk-extractor 2>/dev/null)
if [[ -z $be ]]
then
	echo -e "$YELLOW Bulk Extractor is not installed $RESET"
	echo -e "$YELLOW Installing Bulk Extractor $RESET"
	apt-get update 2>/dev/null && apt install bulk-extractor 2>/dev/null
	bulk_check
else
	echo -e "$CYAN ========================================================== $RESET"
#If Bulk_extractor is already installed notify the user and continue
	echo -e "$GREEN Bulk Extractor is installed $RESET"
fi
}
#Check if Foremost is installed and if not update the system and install it
function fore_check() {
fm=$(dpkg -s foremost 2>/dev/null)
if [[ -z $fm ]]
then
	echo -e "$YELLOW Foremost is not installed $RESET"
	echo -e "$YELLOW installing Foremost $RESET"
	apt-get update &>/dev/null && apt install foremost &>/dev/null
	fore_check
else
	echo -e "$GREEN Foremost is installed $RESET"
fi
}
#Check if Strings is installed and if not update the system and install it
function strings_check() {
st=$(dpkg -s binutils 2>/dev/null)
if [[ -z $st ]]
then
	echo -e "$YELLOW Strings is not installed $RESET"
	echo -e "$YELLOW Installing Strings $RESET"
	apt-get update &>/dev/null && apt install binutils &>/dev/null
	strings_check
else
	echo -e "$GREEN Strings is installed $RESET"
	echo -e "$CYAN ========================================================== $RESET"
fi
}
#Check if Volatility is installed and if not update the system and install it and unzip it and move the Volatility file to a new directory for easier access
function volatility_check() {
  volatil=$(locate -i volatility_2.6_lin64_standalone)
  if [ ! -f "$volatil" ]
  then
    echo -e "$CYAN ========================================================== $RESET"
    echo -e "$YELLOW Volatility is not installed $RESET"
    echo -e "$YELLOW Installing Volatility $RESET"
#Update the system and install Volatility
    apt-get update &>/dev/null && wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip &>/dev/null
#Unzip the Volatility zipped file
    unzip volatility_2.6_lin64_standalone.zip &>/dev/null
#Remove the Volatility zip file after unzipping it    
    rm volatility_2.6_lin64_standalone.zip &>/dev/null
#Give the Volatility file permissions
    chmod 711 volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone &>/dev/null
#Create a new directory for the Volatility tool and data
    mkdir -p extracted_data/volatility &>/dev/null
#Move the Volatility tool to the new directory for easier access
    mv $(pwd)/volatility_2.6_lin64_standalone/volatility_2.6_lin64_standalone extracted_data/volatility &>/dev/null
#Remove the old Volatility directory
	rm -rf $(pwd)/volatility_2.6_lin64_standalone &>/dev/null
#Notify the user Volatility was installed	
	echo -e "$GREEN Volatility is installed $RESET"
  else
    echo -e "$GREEN Volatility is installed $RESET"
  fi
}
#Call the installation checks functions for Bluk_extractor, Foremost and Strings
function installation_checks() {
bulk_check
fore_check
strings_check
}
#Extract information from the selected file using Bulk_extractor and save it to a new directory
function bulk_extract() {
	echo -e "$RED Extracting data using Bulk Extractor $RESET"
	bulk_extractor -o extracted_data/bulk_extractor $filename &>/dev/null
	echo -e "$GREEN Data extracted to extracted_data/bulk_extractor $RESET"
	echo -e "$CYAN ========================================================== $RESET"
	echo -e "$RED Checking for a pcap file $RESET"
#Look for a .pcap file in the extracted files
pcap=$(find extracted_data -name "*.pcap")
if [[ -z $pcap ]]
then
	echo -e "$RED A pcap file was not found $RESET"
else
#If a .pcap file was found, display the files name, location, size and the amount of packets in it
	echo -e "$GREEN A pcap file was found $RESET"
	dump=$(tcpdump -r $pcap 2>/dev/null | wc -l)
	echo -e "$PURPLE The file's name: $(basename $pcap) $RESET"
	echo -e "$PURPLE The file's location: $(dirname $pcap) $RESET"
	echo -e "$PURPLE The file's size: $(du -h $pcap | cut -f1) $RESET"
	echo -e "$PURPLE The number of packets in the file: $dump $RESET"
	echo -e "$CYAN ========================================================== $RESET"
fi
}
#Extract information from the selected file using Foremost and save it to a new directory
function foremost_extract() {
	echo -e "$CYAN ========================================================== $RESET"
	echo -e "$RED Extracting data with Foremost $RESET"
	foremost -t all $filename -o extracted_data/foremost &>/dev/null
	echo -e "$GREEN Data was extracted to extracted_data/foremost $RESET"
	echo -e "$CYAN ========================================================== $RESET"
}
#Extract information from the selected file using Strings and save it to a text file in a new directory
function strings_extract() {
	mkdir -p extracted_data/strings
	echo -e "$RED Extracting data with Strings $RESET"
	strings "$filename" > extracted_data/strings/stringsdata.txt
	echo -e "$GREEN Strings data was saved into extracted_data/strings/stringsdata.txt $RESET"
	echo -e "$CYAN ========================================================== $RESET"
}
#Extract information from the selected file using Volatility and save it to a new directory
function volatility_extract() {
	echo -e "$RED Starting analysis with Volatility $RESET"
#Find the image profile of the selected file
	imageprofile=$(extracted_data/volatility/./volatility_2.6_lin64_standalone -f "$filename" imageinfo 2>/dev/null | head -1 | tail +1 | awk '{print $4}' | cut -d ',' -f1)
#Notify the user of the image profile
	echo -e "$PURPLE The memory profile is: $imageprofile $RESET"
	sleep 1
	echo -e "$GREEN Running processes saved to extracted_data/volatility/pslist.txt $RESET"
#Extract running processes from the selected file and save them on a text file
	extracted_data/volatility/./volatility_2.6_lin64_standalone -f "$filename" --profile=$imageprofile pslist 2>/dev/null > extracted_data/volatility/pslist.txt
	echo -e "$GREEN Network connections saved to extracted_data/volatility/connscan.txt $RESET"
#Extract network connections from the selected file and save them on a text file
	extracted_data/volatility/./volatility_2.6_lin64_standalone -f "$filename" --profile=$imageprofile connscan 2>/dev/null > extracted_data/volatility/connscan.txt
	echo -e "$GREEN Registery information saved to extracted_data/volatility/hivelist.txt $RESET"
	echo -e "$CYAN ========================================================== $RESET"
#Extract Registery information from the selected file and save it on a text file
	extracted_data/volatility/./volatility_2.6_lin64_standalone -f "$filename" --profile=$imageprofile  hivelist 2>/dev/null > extracted_data/volatility/hivelist.txt
 }
#Function for displaying the general statistics of the analysis
function displaydata() {
time=$(date)
numoffiles=$(find /extracted_data -type f -not -empty | wc -l)
#Display the analysis time
	echo -e "$WHITE Time of analysis: $time $RESET"
#Display the number of files extracted during the analysis
	echo -e "$WHITE Number of files found: $numoffiles $RESET"
	echo -e "$CYAN ========================================================== $RESET"
}
#Log the name, time, and number of files extracted of the analysis into a new report.txt file
function saveresults() {
	echo "File name: $filename" >> extracted_data/report.txt
	echo "Files extracted: $numoffiles" >> extracted_data/report.txt
	echo "Time of extraction: $time" >> extracted_data/report.txt
}

#Call the function for checking if the script was run as root
	rootcheck
#Call the fucntion to ask the user to input a file
	specifyfile
#Call the function to run the installation check for the required tools
	installation_checks
#Create a new directory for all the extracted data	
	mkdir -p extracted_data
#Give the extracted data directory permissions
	chmod -R 711 extracted_data
#Ask the user for the file type of the selected file and read the input
	echo -e "$WHITE Is the file an HDD file or Mem file?(HDD/MEM): $RESET"
	read filetype
#If the file type is HDD call the Foremost, Bluk_extractor and Strings extraction functions
	if [ $filetype == HDD ] || [ $filetype == hdd ]
	then
		foremost_extract
		strings_extract
		bulk_extract
		fi
#If the file type is MEM call the Volatility installation check and the Volatility, Foremost, Bluk_extractor and Strings extraction functions
	if [ $filetype == MEM ] || [ $filetype == mem ]
	then
	volatility_check
	foremost_extract
	strings_extract
	bulk_extract
	volatility_extract
	fi
#Call the function to display the analysis data to the user
	displaydata
#Call the funtion to save the analysis results to the report.txt file
	saveresults
#cd to the extracted_data folder	
	cd extracted_data
#Zip all the extracted data and the report.txt file into the extraction.zip zip file and then move the zipped file to the original directory the script was run from and notify the user
	zip -r extraction.zip . report.txt &>/dev/null && mv extraction.zip .. && echo -e "$RED All files are zipped and saved as extraction.zip $RESET"
	echo -e "$PINK tupal $RESET"
