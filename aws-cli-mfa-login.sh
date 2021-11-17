#!/bin/bash

export MFA_DEVICE_ARN=""
export AWS_PROFILE=""
export MFA_CODE=""
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_SESSION_TOKEN=""

read -p "Please enter AWS Profile to use: " AWS_PROFILE

# Total lines in ~/.aws/creditials file
TOTAL_LINE_COUNT="wc -l < $HOME/.aws/credentials"
TOTAL_LINE_COUNT=$(eval "$TOTAL_LINE_COUNT")
#echo "Total lines in ~/.aws/credentials: $TOTAL_LINE_COUNT"

# Look for the line of the profile in ~/.aws/credentials file
PROFILE_LINE="awk '\$1 == "\""[$AWS_PROFILE]"\""{ print NR; exit }' $HOME/.aws/credentials"
PROFILE_LINE=$(eval "$PROFILE_LINE")
#echo "Profile line: $PROFILE_LINE"

# Check if profile exists, if not, exit
if [ -z $PROFILE_LINE ]; then
		    echo "AWS profile [$AWS_PROFILE] not listed in $HOME/.aws/credentials "
   	        exit 1
fi

LAST_LINE="tail -$((TOTAL_LINE_COUNT-PROFILE_LINE)) $HOME/.aws/credentials | awk '/\[/ { print NR; exit }'"
LAST_LINE="$(eval "$LAST_LINE")"
#echo "Last line: $LAST_LINE"

case $LAST_LINE in
    ''|*[!0-9]*) LAST_LINE=$((TOTAL_LINE_COUNT-PROFILE_LINE+1)) ;;
    *) LAST_LINE=$LAST_LINE ;;
esac
#echo "Last line: $LAST_LINE"

if [ -z $LAST_LINE ]; then
		    echo "AWS profile [$AWS_PROFILE] not listed in $HOME/.aws/credentials "
   	        exit 1
fi

PROFILE_INFO="tail -n +$PROFILE_LINE $HOME/.aws/credentials | head -n $LAST_LINE"
PROFILE_INFO="$(eval "$PROFILE_INFO")"
#echo "Profile info: $PROFILE_INFO"

# Find MFA device ARN for the profile
MFA_DEVICE_ARN="echo \$PROFILE_INFO | grep "aws_arn_mfa_device" | sed 's/^.*= //' | head -1"
MFA_DEVICE_ARN=$(eval "$MFA_DEVICE_ARN")
#echo "MFA device ARN: $MFA_DEVICE_ARN"

if [ -z $MFA_DEVICE_ARN ]; then
		    echo "No aws_arn_mfa_device listed for AWS Profile [$AWS_PROFILE] in $HOME/.aws/credentials"
   	        exit 1
fi

read -p "Please enter MFA code: " MFA_CODE
COMMAND="aws --output text sts get-session-token \
					--serial-number $MFA_DEVICE_ARN \
					--token-code $MFA_CODE \
					--profile $AWS_PROFILE"

CREDS=$($COMMAND)
KEY=$(echo $CREDS | cut -d" " -f2)
SECRET=$(echo $CREDS | cut -d" " -f4)
SESS_TOKEN=$(echo $CREDS | cut -d" " -f5)



export AWS_ACCESS_KEY_ID=$KEY
export AWS_SECRET_ACCESS_KEY=$SECRET
export AWS_SESSION_TOKEN=$SESS_TOKEN

# Check if script has been sourced or executed
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [ $sourced -eq 1 ]; then
    echo "Script was sourced."
else
    echo "Script was executed, starting subshell."
    bash -l
fi