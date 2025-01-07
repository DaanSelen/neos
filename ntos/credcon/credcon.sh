#!/bin/bash

export DISPLAY=:0

# Some environmnet variables.
rdpFile="/home/user/Templates/remote-connection.rdp"

# A YAD loading bar to create the illusion that the system is doing something (which it is).
# The reason is that a non-technical person might not understand the fact that the system is doing something in the background.
show_loading_bar() {
    echo 'Starting loading bar'

    for ((i=1; i<=100; i++)); do
        echo $i | tee /dev/null
        echo "# $i%" | tee /dev/tty
        sleep 0.125
    done | yad --progress \
        --title='Loading' \
        --text='Connecting' \
        --width=400 \
        --height=200 \
        --button='Cancel' \
        --auto-kill \
        --auto-close
}

# Show credential input dialog this is to get the credentials for the RDP-session.
# Simple yet powerful, while not taking over the entire monitor.
show_credential_dialogue() {
    credentials=$(yad --form \
                  --title='Login' \
                  --text='Enter your credentials' \
                  --field='Email:' \
                  --field='Password:':H \
                  --button='Submit':0 \
                  --button='Cancel':1 \
                  --width=400 \
                  --height=200 \
                  --separator=',')

    result=$?
}

# Show dialogue with 'Connection failed', this is done to notice the user that something might not have gone completely right.
# The purpose for this is to display this once a connection failed, not when it succeeded.
show_connection_failure() {
    yad --form \
        --title='Connection Closed' \
        --text='Connection was Terminated.' \
        --button='Ok':0 \
        --width=400 \
        --height=200
}

# Main loop, because I am a bit used to that programming structure.
main() {
    show_credential_dialogue

    # Check if the input fields from the credential prompt are populated.
    if [ "$result" -eq 0 ]; then

        # Extract username and password from credentials (prompt).
        username=$(echo "$credentials" | awk -F',' '{print $1}')
        password=$(echo "$credentials" | awk -F',' '{print $2}')

        # Show the loading bar in the background, this is made because the FreeRDP session will take over the entire screen.
        show_loading_bar &

        # Start xfreerdp session in the background and get its process ID (PID).
        # This does not hinder the process from taking over the (screen/monitor) session.
        xfreerdp3 "$rdpFile" /u:"${username}" /p:"${password}" /drive:hotplug,* /cert:ignore &
        xfreerdp_pid=$!

        # Wait for the xfreerdp process up to $interval seconds, default 30.
        threshold=30
        elapsed=0
        interval=1

        # Keep track of how long the FreeRDP process is alive for.
        while kill -0 "$xfreerdp_pid" 2> /dev/null; do
            sleep "$interval"
            elapsed=$(($elapsed + $interval))

            # If xfreerdp has been running for more than 30 seconds, exit the loop (connection likely succeeded).
            if [ "$elapsed" -ge "$threshold" ]; then
                echo 'xfreerdp ran for more than 30 seconds Assuming success..'

                # Disown the FreeRDP process to make the script exit gracefully.
                disown "$xfreerdp_pid"

                # Kill all remaining YAD dialogues.
                pkill -f yad

                # Gracefully exit the script.
                exit 0
            fi
        done

        # If we exit the loop in under 30 seconds, it means xfreerdp terminated early, which likely means a failure to login/connect.
        echo "xfreerdp terminated early (less than '${threshold}' seconds)."

        # This is done to kill the loading bar process, because it will be followed-up by the "login_failed" dialogue.
        pkill -f yad

        show_connection_failure

        # Kill the bash process, this stops the background counting of the loading bar. While exiting gracefully!
        pkill -f bash &

        # Gracefully exit.
        exit 0
    fi
}

# Call main function
main
