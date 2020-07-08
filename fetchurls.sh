#!/bin/bash

# Set Defaults
WGET_INSTALLED=0
RUN_NONINTERACTIVE=0
SHOW_HELP=0
SHOW_WGET_INSTALL_INFO=0
SHOW_VERSION=0
SHOW_TROUBLESHOOTING=0
USER_DOMAIN=
USER_FILENAME=
DEFAULT_SAVE_LOCATION=~/Desktop
USER_SAVE_LOCATION=
DEFAULT_EXCLUDED_EXTENTIONS="bmp|css|doc|docx|gif|jpeg|jpg|JPG|js|map|pdf|PDF|png|ppt|pptx|svg|ts|txt|xls|xlsx|xml"
USER_EXCLUDED_EXTENTIONS=

# Set colors
COLOR_RED=$'\e[31m'
COLOR_CYAN=$'\e[36m'
COLOR_YELLOW=$'\e[33m'
COLOR_GREEN=$'\e[32m'
COLOR_RESET=$'\e[0m'

VERSION="v3.0.0"

PARAMS=""

# Loop through arguments and process them
while (( "$#" )); do

    # Debug: Show flag being evaulated
    # echo "  ${COLOR_CYAN}$1${COLOR_RESET}"

    case "$1" in
        -h|-\?|--help)
            SHOW_HELP=1
            ;;
        -w|--wget)
            SHOW_WGET_INSTALL_INFO=1
            ;;
        -v|-V|--version)
            SHOW_VERSION=1
            ;;
        -n|--non-interactive)
            RUN_NONINTERACTIVE=1
            ;;
        -t|--troubleshoot)
            SHOW_TROUBLESHOOTING=1
            ;;
        # DOMAIN
        -d|--domain)
            if [ "$2" ]; then
                USER_DOMAIN="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -d=*?|--domain=*?)
            USER_DOMAIN="${1#*=}"
            shift # Remove domain from processing
            ;;
        # FILENAME
        -f|--filename)
            if [ "$2" ]; then
                USER_FILENAME="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required. Remove $1 flag to use the default value."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -f=*|--filename=*)
            USER_FILENAME="${1#*=}"
            shift # Remove filename from processing
            ;;
        # LOCATION
        -l|--location)
            if [ "$2" ]; then
                USER_SAVE_LOCATION="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required. Remove $1 flag to use the default value."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -l=*|--location=*)
            USER_SAVE_LOCATION="${1#*=}"
            shift # Remove location from processing
            ;;
        # EXCLUDE FILE EXTENSIONS
        -e|--exclude)
            if [ "$2" ] || [ "$2" == "" ]; then
                # Remove first and last character, if either is a pipe
                USER_EXCLUDED_EXTENTIONS="$(echo "$2" | sed 's/^|//' | sed 's/|$//')"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required. Remove $1 flag to use the default value."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -e=*|--exclude=*)
            USER_EXCLUDED_EXTENTIONS="${1#*=}"
            shift # Remove location from processing
            ;;
        # End of all options
        -*|--*=) # unsupported flags
            echo "${COLOR_RED}ERROR: Flag $1 is not a supported option."${COLOR_RESET} >&2
            exit 1
            ;;
        # preserve positional arguments
        *)
            PARAMS="${PARAMS} $1"
            shift
            ;;
    esac
    shift
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Version
showVersion()
{
    echo ""
    echo "${COLOR_YELLOW}fetchurls $VERSION${COLOR_RESET}"
    footerInfo
}

footerInfo()
{
    echo ""
    echo "For updates and more information:"
    echo "  https://github.com/adamdehaven/fetchurls"
    echo ""
    echo "Created by Adam DeHaven"
    echo "  @adamdehaven or https://adamdehaven.com"
    echo ""
}

# Help text
showHelp()
{
    echo ""
    echo "Description:"
    echo "  A bash script to spider a site, follow links, and fetch urls (with built-in filtering) into a generated text file."
    echo ""
    if [ "$WGET_INSTALLED" -eq 0 ]; then
        echo "Requirements:"
        echo "  ${COLOR_YELLOW}You'll need wget installed in order to continue.${COLOR_RESET}"
        echo "  For more information, run with the --wget flag, or check out https://github.com/adamdehaven/fetchurls#usage"
        echo ""
    fi
    echo "Usage:"
    echo "  1. Set execute permissions for the script:"
    echo "     ${COLOR_CYAN}chmod +x ./fetchurls.sh${COLOR_RESET}"
    echo "  2. Enter the following to run the script:"
    echo "      ${COLOR_CYAN}./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
    echo ""
    echo "      ${COLOR_YELLOW}Note: The script will run in interactive mode if no options are passed.${COLOR_RESET}"
    echo ""
    echo "  Alternatively, you may execute with either of the following:"
    echo "  a) ${COLOR_CYAN}sh ./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
    echo "  b) ${COLOR_CYAN}bash ./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
    echo ""
    echo "Options:"
    echo ""
    echo "  -d, --domain                  The fully qualified domain URL (with protocol) you would like to crawl."
    echo "                                If you do not pass the --domain flag, the script will run in interactive mode."
    echo "                                Example: ${COLOR_CYAN}https://example.com${COLOR_RESET}"
    echo ""
    echo "  -l, --location                The location (directory) where you would like to save the generated results."
    echo "                                Default: ${COLOR_YELLOW}~/Desktop${COLOR_RESET}"
    echo "                                Example: ${COLOR_CYAN}/c/Users/username/Desktop${COLOR_RESET}"
    echo ""
    echo "  -f, --filename                The name of the generated file, without spaces or file extension."
    echo "                                Default: ${COLOR_YELLOW}domain-topleveldomain${COLOR_RESET}"
    echo "                                Example: ${COLOR_CYAN}example-com${COLOR_RESET}"
    echo ""
    echo "  -e, --exclude                 Pipe-delimited list of file extensions to exclude from results."
    echo "                                The list of file extensions must be passed inside quotes."
    echo "                                To prevent excluding files matching the default list, simply pass an empty string: \"\""
    echo "                                Default: ${COLOR_YELLOW}\"$DEFAULT_EXCLUDED_EXTENTIONS\"${COLOR_RESET}"
    echo "                                Example: ${COLOR_CYAN}\"css|js|map\"${COLOR_RESET}"
    echo ""
    echo "  -n, --non-interactive         Allows the script to run successfully in a non-interactive shell."
    echo "                                Uses the default --location and --filename settings unless the corresponding flags are set."
    echo ""
    echo "  -w, --wget                    Show wget install instructions."
    echo "                                The installation process may vary depending on your computer's configuration."
    echo ""
    echo "  -v, -V, --version             Show version info."
    echo ""
    echo "  -t, --troubleshooting         Output arguments passed as flags for troubleshooting."
    echo ""
    echo "  -h, -?, --help                Show this help message."
    footerInfo
}

showWgetInstallInfo()
{
    echo ""
    if [ "$WGET_INSTALLED" -eq 0 ]; then
        echo "${COLOR_RED}You will need wget installed (or properly added to your PATH) to continue.${COLOR_RESET}"
        echo ""
    fi
    echo "To check if wget is already installed, try running the command 'wget' by itself."
    echo ""
    echo "If you are on a Mac or running Linux, chances are you already have wget installed;"
    echo "however, if the wget command is not working, it may not be properly added to your PATH variable."
    echo ""
    echo "If you are running Windows:"
    echo ""
    echo "  1. Download the lastest wget binary for windows from https://eternallybored.org/misc/wget/"
    echo "     The download is available as a zip with documentation, or just an exe. I'd recommend just the exe."
    echo ""
    echo "  2. If you downloaded the zip, extract all files (if windows built in zip utility gives an error, use 7-zip)."
    echo "     In addition, if you downloaded the 64-bit version, rename the wget64.exe file to wget.exe"
    echo ""
    echo "  3. Move wget.exe to C:\Windows\System32\\"
}

showTroubleshooting()
{
    echo ""
    echo "${COLOR_YELLOW}Runtime variables:${COLOR_RESET}"
    echo "  WGET_INSTALLED:             ${COLOR_CYAN}$WGET_INSTALLED${COLOR_RESET}"
    echo "  SHOW_WGET_INSTALL_INFO:     ${COLOR_CYAN}$SHOW_WGET_INSTALL_INFO${COLOR_RESET}"
    echo "  SHOW_HELP:                  ${COLOR_CYAN}$SHOW_HELP${COLOR_RESET}"
    echo "  SHOW_VERSION:               ${COLOR_CYAN}$SHOW_VERSION${COLOR_RESET}"
    echo "  RUN_NONINTERACTIVE:         ${COLOR_CYAN}$RUN_NONINTERACTIVE${COLOR_RESET}"
    echo "  USER_DOMAIN:                ${COLOR_CYAN}$USER_DOMAIN${COLOR_RESET}"
    echo "  USER_FILENAME:              ${COLOR_CYAN}$USER_FILENAME${COLOR_RESET}"
    echo "  USER_SAVE_LOCATION:         ${COLOR_CYAN}$USER_SAVE_LOCATION${COLOR_RESET}"
    echo "  USER_EXCLUDED_EXTENTIONS:   ${COLOR_CYAN}$USER_EXCLUDED_EXTENTIONS${COLOR_RESET}"
}

checkForWget()
{
    if [ -x "$(which wget 2>/dev/null)" ] ; then
        # wget is installed
        WGET_INSTALLED=1
    else
        # wget is NOT installed
        WGET_INSTALLED=0
    fi
}

displaySpinner()
{
  local pid=$!
  local delay=0.3
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
      local temp=${spinstr#?}
      printf "${COLOR_RESET}${COLOR_CYAN}Please wait... [ %c ]  " "$spinstr${COLOR_RESET}" # Count number of backspaces needed (A = 25)
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" # Number of backspaces from (A)
  done
  printf "                         \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" # Number of spaces, then backspaces from (A)
}

fetchUrlsForDomain() {
  cd $USER_SAVE_LOCATION && wget --spider -r -nd --max-redirect=30 $USER_DOMAIN 2>&1 \
  | grep '^--' \
  | awk '{ print $3 }' \
  | grep -E -v '\.('${USER_EXCLUDED_EXTENTIONS}')(\?.*)?$' \
  | grep -E -v '\?(p|replytocom)=' \
  | grep -E -v '\/wp-content\/uploads\/' \
  | grep -E -v '\/feed\/' \
  | grep -E -v '\/category\/' \
  | grep -E -v '\/tag\/' \
  | grep -E -v '\/page\/' \
  | grep -E -v '\/widgets.php$' \
  | grep -E -v '\/wp-json\/' \
  | grep -E -v '\/xmlrpc' \
  | sort -u \
  > $USER_SAVE_LOCATION/$1.txt
}

# Cleanup before exit
beforeExit()
{
    # Delete generated file if it exists and is empty
    if [ -f $USER_SAVE_LOCATION/$USER_FILENAME.txt ] && [ ! -s $USER_SAVE_LOCATION/$USER_FILENAME.txt ]; then
        printf "                         \b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b" # Number of backspaces from (A) to remove spinner
        if [ "$RUN_NONINTERACTIVE" -eq 1 ]; then
            echo "${COLOR_RESET}"
        fi
        echo ""
        echo "${COLOR_RED}User cancelled. Cleaning up...${COLOR_RESET}"
        rm $USER_SAVE_LOCATION/$USER_FILENAME.txt
    else
        echo "${COLOR_RESET}"
    fi
    echo ""
    echo "${COLOR_YELLOW}Cancelled${COLOR_RESET}"
    # Exit process
    exit 130
}
trap beforeExit INT

# First, check if wget is installed
checkForWget

# If user passed troubleshoot flag, output variables before continuing
if [ "$SHOW_TROUBLESHOOTING" -eq 1 ] && { [ "$SHOW_HELP" -eq 1 ] || [ "$SHOW_VERSION" -eq 1 ]; } then
    showTroubleshooting
fi

# If user passed help flag
if [ "$SHOW_HELP" -eq 1 ]; then
    showHelp
    exit
# If user passed version flag
elif [ "$SHOW_VERSION" -eq 1 ]; then
    showVersion
    exit
elif [ "$SHOW_WGET_INSTALL_INFO" -eq 1 ] || [ "$WGET_INSTALLED" -eq 0 ]; then
    showWgetInstallInfo
    exit
fi

# USER_DOMAIN
if [ -z "$USER_DOMAIN" ] && [ "$RUN_NONINTERACTIVE" -eq 0 ]; then
    # Prompt user for domain
    echo "${COLOR_RESET}"
    echo "Fetch a list of unique URLs for a domain."
    echo ""
    echo "Enter the full domain URL ( https://example.com )"
    read -e -p "Domain URL: ${COLOR_CYAN}" USER_DOMAIN
elif [ -z "$USER_DOMAIN" ] && [ "$RUN_NONINTERACTIVE" -eq 1 ]; then
    echo "${COLOR_RED}ERROR: --domain is required.${COLOR_RESET}"
    echo "${COLOR_RED}Try again by passing a valid domain URL or removing the --non-interactive flag."${COLOR_RESET} >&2
    exit 1
fi

USER_DOMAIN="${USER_DOMAIN%/}"
DISPLAY_DOMAIN="$(echo ${USER_DOMAIN} | grep -oP "^http(s)?://(www\.)?\K.*")"
GENERATED_FILENAME="$(echo ${USER_DOMAIN} | grep -oP "^http(s)?://(www\.)?\K.*" | tr "." "-")"

# Check if URL is valid and returns 200 status
URL_STATUS=$(wget --spider -q --server-response $USER_DOMAIN 2>&1 | grep --max-count=1 "HTTP/" | awk '{print $2}')
# If response is 301, follow redirect
if [ "$URL_STATUS" = "301" ]; then
    # Get redirect URL
    FORWARDED_URI=$(wget --spider -q --server-response $USER_DOMAIN 2>&1 | grep --max-count=1 "Location" | awk '{print $2}')
    echo "${COLOR_RESET}"
    echo "${COLOR_YELLOW}NOTE: ${USER_DOMAIN} is permanently forwarded to ${FORWARDED_URI}${COLOR_RESET}"
    USER_DOMAIN=$FORWARDED_URI
    echo ""
    echo "Script will fetch ${COLOR_CYAN}${USER_DOMAIN}${COLOR_RESET} instead"
    echo ""
elif [ "$URL_STATUS" != "200" ] || [ -z "$URL_STATUS" ]; then
    echo "${COLOR_RESET}"
    echo "${COLOR_RED}ERROR: '${USER_DOMAIN}' is unresponsive or is not a valid URL.${COLOR_RESET}"
    echo "${COLOR_RED}       Ensure the site is up by checking in your browser, then try again.${COLOR_RESET}"
    exit 1
fi

# USER_SAVE_LOCATION
if [ -z "$USER_SAVE_LOCATION" ] && [ "$RUN_NONINTERACTIVE" -eq 0 ]; then
    # Prompt user for save directory
    echo "${COLOR_RESET}"
    echo "Save file to directory"
    read -e -p "Location: ${COLOR_CYAN}" -i "${DEFAULT_SAVE_LOCATION}" USER_SAVE_LOCATION
else
    # Running non-interactive, so set to default
    USER_SAVE_LOCATION="$DEFAULT_SAVE_LOCATION"
fi
# Create directory if it does not exist
mkdir -p $USER_SAVE_LOCATION

# USER_FILENAME
if [ -z "$USER_FILENAME" ] && [ "$RUN_NONINTERACTIVE" -eq 0 ]; then
    # Prompt user for filename
    echo "${COLOR_RESET}"
    echo "Save file as"
    read -e -p "Filename (no file extension, and no spaces): ${COLOR_CYAN}" -i "${GENERATED_FILENAME}" USER_FILENAME
    USER_FILENAME="$USER_FILENAME"
else
    # Running non-interactive, so set to default
    USER_FILENAME="$GENERATED_FILENAME"
fi

# USER_EXCLUDED_EXTENTIONS
if [ -z "$USER_EXCLUDED_EXTENTIONS" ] && [ "$RUN_NONINTERACTIVE" -eq 0 ]; then
    # Prompt user for excluded file extensions
    echo "${COLOR_RESET}"
    echo "Exclude files with matching extensions"
    read -e -p "Excluded extensions: ${COLOR_CYAN}" -i "${DEFAULT_EXCLUDED_EXTENTIONS}" USER_EXCLUDED_EXTENTIONS
    # Remove first and last character, if either is a pipe
    USER_EXCLUDED_EXTENTIONS="$(echo "$USER_EXCLUDED_EXTENTIONS" | sed 's/^|//' | sed 's/|$//')"
else
    # Running non-interactive, so set to default
    USER_EXCLUDED_EXTENTIONS="$DEFAULT_EXCLUDED_EXTENTIONS"
fi

# If user passed troubleshoot flag, output variables before continuing
if [ "$SHOW_TROUBLESHOOTING" -eq 1 ] && { [ "$SHOW_HELP" -eq 0 ] || [ "$SHOW_VERSION" -eq 0 ]; } then
    showTroubleshooting
fi

echo ""
echo "${COLOR_RESET}Fetching URLs for ${DISPLAY_DOMAIN}"

# Start process
echo ""
# Start process, with spinner
fetchUrlsForDomain $USER_FILENAME & displaySpinner

# Process is complete

# Count number of results if file exists
if [ -f $USER_SAVE_LOCATION/$USER_FILENAME.txt ]; then
    RESULT_COUNT="$(cat ${USER_SAVE_LOCATION}/$USER_FILENAME.txt | sed '/^\s*$/d' | wc -l)"
    if [ "$RESULT_COUNT" = 1 ]; then
        RESULT_MESSAGE="${RESULT_COUNT} result"
    else
        RESULT_MESSAGE="${RESULT_COUNT} results"
    fi

    # Output message
    echo "${COLOR_GREEN}Finished with ${RESULT_MESSAGE}!${COLOR_RESET}"
    echo ""
    echo "File Location:"
    echo "   ${COLOR_GREEN}${USER_SAVE_LOCATION}/$USER_FILENAME.txt${COLOR_RESET}"
    echo ""
fi
