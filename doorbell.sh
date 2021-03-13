#1/bin/bash

exec 2> /var/log/doorbell.log # send stderr from doorbell.sh to a log file. Since the version of Systemd I'm using is older, I can't specify a log file in the service file itself.
exec 1>&2 #This sends standard output and errors to the log file.

pin=26 #input GPIO pin here, not the pin number. Feel free to use this, but I picked GPIO26 since it's right next to ground.
timeout=10 #This is the timeout set so that the mp3 file won't be played more than onece in the time specified. I would recommend setting this to the length of the audio.
mp3File="{insert mp3 file to use as doorbell sound}"

gpioExists=$(ls /sys/class/gpio/gpio* | grep gpio$pin | wc -l) #Check to see if this particular GPIO number/pin already exists.

currEpochTime=$(date +%s) # Grab current epoch time. This is used to ensure that the mp3 sound file isn't played multiple times if someone rings the doorbell multiple times.

echo "Script started at " $(date) #I like to add this at the beginning of the script since it tells me in the log file when the file was started. Feel free to remove this.

if [ $gpioExists -lt 1 ] # If the GPIO pin hasn't been setup, do so now. If it has already been setup, don't do anything to it.
then
    echo $pin >/sys/class/gpio/export #Initializes the gpio pin

    echo 1 >/sys/class/gpio/gpio$pin/value #Set the gpio pin to default to high or 1 value

    echo high >/sys/class/gpio/gpio$pin/direction #Set the gpio pin to be input and default to high or 1
fi

while true; do # This loop runs indefinitely, and we're polling to see if someone pushed the doorbell button
    if [ $( cat /sys/class/gpio/gpio$pin/value) -eq 0 ] # The GPIO pin is set to high or 1 so that when a button is pushed, it's pulled down to low or 0. This is essentially closing the loop, triggering the mp3 file to be played
    then
        newEpochTime=$(date +%s) # If the doorbell button was pushed, grab the current time
        # We compare the current time to either the start time of the script or the last time a button press was detected.
        # If it has been at lesat timeout seconds since the last button press, play a mp3 file. This is so that we don't spam play the doorbell music.
        if [ $(($newEpochTime - $currEpochTime)) -ge $timeout ] 
        then
            currEpochTime=$newEpochTime # We set the currEpochTime variable to newEpochTime which is when the button was pressed.
            echo "ding dong" #This is for debugging than anything. Feel free to remove this if you don't want it to show up in the log file.
            mpg123 $mp3File #This is where the mp3 audio file gets played. Make sure that mpg123 is installed.
        fi
    fi

    sleep .5
done


