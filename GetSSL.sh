#!/bin/sh

# Created by: David Nahodyl, Blue Feather
# Contact: contact@bluefeathergroup.com
# Updated by: Santiago Atienza Ferro, Inytel
# Contact: satienza@inytel.com

# Need help? We can set this up to run on your server for you! Send an email to 
# contact@bluefeathergroup.com or give a call at (770) 765-6258

function usage() {
    cat <<USAGE

    WARNING! THIS SCRIPT WILL RESTART FILEMAKER SERVER!

    Creates an SSL Certificate from the Let's Encrypt Certificate Authority (CA) to
    encypt data in motion for FileMaker. Certbot requires that port 80 be forwarded
    to your server.
    
    Must be run as root.

    Options:
        -d | --domain               Set the domain.
        -e | --email                Set the contact email.
        -s | --server-path          Set the path to the FileMaker Server directory.
        -p | --preferred-challenges Set the verification mode.

        --no-confirm                Skip confirmation. Suggested for use in scripts.

	    -h, --help, --usage:    	Print this help message.

    Domain:
    --domain
        Change the domain variable to the domain/subdomain for which you would like
        an SSL Certificate
        "fms.mycompany.com"

    Email:
    --email
        Change the contact email address to your real email address so that Let's Encrypt
        can contact you if there are any problems
        "myemail@mycompoany.com"

    Server Path:
    --server-path
        Enter the path to your FileMaker Server directory, ending in a slash 
        "/Library/FileMaker Server/" 

    Preferred Challenges:
    --preferred-challenges
        Select one:
            - html: uses port 80 through the server to verify the certificate.
            - dns: uses a TXT record in the domain DNS to verfy the certificate. Use when you dont have access through the port 80.

USAGE
    exit 1
}

# Set flags
echo
while [ "$1" != "" ]; do
	case $1 in
	-d | --domain)
		shift
		DOMAIN=$1
		# echo "Using domain: $DOMAIN"
		;;

	-e | --email)
		shift
		EMAIL=$1
		# echo "Email: $EMAIL"
		;;

	-s | --server-path)
		shift
		SERVER_PATH=$1
		# echo "Server path: $SERVER_PATH"
		;;

    -p | --preferred-challenges)
        shift
        PREFERRED_CHALLENGES=$1
        # echo "Preferred challenges: $PREFERRED_CHALLENGES"
        ;;

    --no-confirm)
        NOCONFIRM=true
        ;;

	-h | --help | --usage)
		usage
		exit 1
		;;

    	*)
		printf "\033[1;31mError: Invalid option!\033[0m\n"
		echo "Use --help for usage"
		exit 1
		;;
	esac
	shift
done

# Checks to see if script is running as root.
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Check to see if certbot is installed.
if ! type certbot > /dev/null; 
then
    printf "\033[1;31mError: Certbot could not be found\033[0m\n"
    echo "Install Certbot https://certbot.eff.org"
    exit 1
fi

# Check for arguements.
if [ "$DOMAIN" = "" ]; then
	read -p "Set your domain: " DOMAIN
        if [[ $DOMAIN == "" ]];
            then printf "\033[1;31mError: Domain not specified. Must enter domain.\033[0m\n" && exit 1
        fi
	echo
fi

if [ "$EMAIL" = "" ]; then
	read -p "Set your Email: " EMAIL
        if [[ $EMAIL == "" ]];
            then printf "\033[1;31mError: Email not specified. Must enter email.\033[0m\n" && exit 1
        fi
	echo
fi

if [ "$SERVER_PATH" = "" ]; then
	read -p "Set your Server Path. Press 'enter' for default. ('/Library/FileMaker Server/'): " SERVER_PATH
    SERVER_PATH=${SERVER_PATH:-"/Library/FileMaker Server/"}
        if [[ $SERVER_PATH == "" ]];
            then printf "\033[1;31mError: Server Path not specified. Must enter Server Path.\033[0m\n" && exit 1
        fi
	echo
fi
PS3="Select challenge: "

if [ "$PREFERRED_CHALLENGES" = "" ]; then
    select challenge in dns http quit; do
        case $challenge in
            dns)
                PREFERRED_CHALLENGES=$challenge
                break
            ;;
            https)
                PREFERRED_CHALLENGES=$challenge
                break
            ;;
            quit)
                exit 1
                break
            ;;
            *)
                echo "Invalid option $REPLY"
                exit 1
                break
            ;;
        esac
    done
fi

# Confirm arguements
if  [[ $NOCONFIRM == "" ]]; 
then
    while true; do
        echo
        echo "-- Your settings --"
        echo "Domain:       $DOMAIN"
        echo "Email:        $EMAIL"
        echo "Server Path:  $SERVER_PATH"
        echo "Preferred challenges: $PREFERRED_CHALLENGES"
        echo
        read -p "Is the above information correct? Y/n: " YN
        case $YN in
            [Yy]* )
                echo "Continueing..."
                break;;

            [Nn]* )
                echo "Stopping script..."
                exit 1
                break;;
            * )
                echo "Please answer yes or no.";;
        esac
    done
else
    echo "Skipping Confirmation..."
fi

# testing e-brake
# exit

WEB_ROOT="${SERVER_PATH}HTTPServer/htdocs"


# Get the certificate
if [ "$PREFERRED_CHALLENGES" == "dns" ]; 
then
    sudo certbot certonly --manual -w "$WEB_ROOT" -d $DOMAIN --agree-tos -m "$EMAIL" --preferred-challenges "dns" 
else
    certbot certonly --webroot -w "$WEB_ROOT" -d $DOMAIN --agree-tos -m "$EMAIL" --preferred-challenges "http" -n
fi

# cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "${SERVER_PATH}CStore/fullchain.pem"
# cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "${SERVER_PATH}CStore/privkey.pem"

cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" .
cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" .
cp "/etc/letsencrypt/live/${DOMAIN}/cert.pem" .


# chmod 640 "${SERVER_PATH}CStore/privkey.pem"
chmod 640 "privkey.pem"

# Move an old certificate, if there is one, to prevent an error
FILE=${SERVER_PATH}CStore/serverKey.pem

if [test -f "$FILE"]; 
then
    echo "$FILE exists. Moving to serverKey-old.pem to prevent an error."
    mv "${SERVER_PATH}CStore/serverKey.pem" "${SERVER_PATH}CStore/serverKey-old.pem"
fi

# Remove the old certificate
echo
echo "Deleting old certificate..."
fmsadmin certificate delete

# Install the certificate
fmsadmin certificate import "cert.pem" --intermediateCA "fullchain.pem" --keyfile "privkey.pem" -y

# Stop FileMaker Server
echo
echo "Stopping FMS..."
launchctl stop com.filemaker.fms

# Wait 15 seconds for it to stop
echo
echo "Waiting 15 seconds..."
sleep 15s

# Start FileMaker Server again
echo
echo "Starting FMS..."
launchctl start com.filemaker.fms

# Remove cert files in user folder
rm fullchain.pem
rm privkey.pem
rm cert.pem

echo
echo "FileMaker Server should now be set to use TLS/SSL"
echo