#!/usr/bin/env /bin/bash
function get_filename_from_bitly_url() {
    URL=$1
    FILENAME=$(/usr/bin/curl -L "$URL" | /bin/grep -o "/son/zip/.*\.[a-z]*" | /usr/bin/rev | /usr/bin/cut -d'/' -f1 | /usr/bin/rev)
    # Return the filename
    echo "$FILENAME"
}

function download_from_bitly_link_to_folder() {
    URL=$1
    PATH=$2
    FILENAME=$(get_filename_from_bitly_url "$URL")
    echo "--- Launching download from $URL to $PATH/$FILENAME ---"
    # retry loop
    for k in {1..3}; do
	/usr/bin/curl -L "$URL"  -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0' -H 'Accept: text/css,*/*;q=0.1' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: http://odgprod.com/' -H 'Cookie: 300gpBAK=R4178757645; 300gp=R3395838808; PHPSESSID=07544ee240a216a6b3c83e26a784c871' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --output "$PATH/$FILENAME" --retry 3 --retry-delay 10 --retry-max-time 30	
	if [ $? -eq 0 ]; then
	    break
	else
	    echo "Download $FILENAME failed... retry \#$k."
	fi
    done
    # All retrys have failed ... that sucks. We fucking exit.
    if [ $? -eq 0 ]; then
	echo "Successfully downloaded $FILENAME into folder $PATH."
    else
	echo "Download $FILENAME failed... all retrys have failed. WE EXIT THIS SHITTY PROGRAM !!!"
	exit 1
    fi
}

function get_download_links_from_odgprod_url() {
    URL=$1
    WEBPAGE_HTML=$(/usr/bin/curl "$URL" -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Cookie: PHPSESSID=07544ee240a216a6b3c83e26a784c871; 300gpBAK=R4178755467; 300gp=R3395838808' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0')

    WEBPAGE_HTML_LINKS=$(echo "$WEBPAGE_HTML" |  /bin/grep -o "<a[^>]*\/a>")
    WEBPAGE_DOWNLOAD_LINKS=$(echo "$WEBPAGE_HTML" | /bin/grep -o "href=\"http://bit[^\"]*\"" | /usr/bin/cut -d'"' -f2)
    # Return download links
    echo "$WEBPAGE_DOWNLOAD_LINKS"
}
    
DOWNLOAD_FOLDER="download"

# Here's an ODGProd URL: http://odgprod.com/2005/01/
# This webpage contains all albums from January 2001, along their download links.
# Here's what we'll do: we will iterate over all months from year 2004 to year 2020.
# So, from http://odgprod.com/2000/01/ to http://odgprod.com/2020/12/
BASE_URL="http://odgprod.com"
for i in {2018..2020}; do
    for j in {01..12}; do
	URL="$BASE_URL/$i/$j/"
	echo "Fetching download links from $URL"
	DOWNLOAD_LINKS=$(get_download_links_from_odgprod_url "$URL")
	echo "Downloak links found:"
	echo "$DOWNLOAD_LINKS"
	# Loop over download links gotten from the webpage
	for DOWNLOAD_LINK in $(echo "$DOWNLOAD_LINKS"); do
	    download_from_bitly_link_to_folder $DOWNLOAD_LINK $DOWNLOAD_FOLDER
	done
    done
done


echo "################ OriginalDubGathering Downloader Results #################"
echo " - Total number of albums on ODGProd : $TOTAL_ALBUMS"
echo " - Number of albums already present on your computer : $ALREADY_PRESENT_ALBUMS"
echo " - Number of albums downloaded this time : $DOWNLOADED_ALBUMS"
echo " - Number of albums that failed to download : $FAILED_ALBUMS"
echo " - TOTAL ALBUMS YOU HAVE : ${DOWNLOADED_ALBUMS+ALREADY_PRESENT_ALBUMS}/$TOTAL_ALBUMS"
echo "################ Script worked like a charm! Congratz! #################"
