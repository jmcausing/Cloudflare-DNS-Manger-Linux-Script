#!/bin/bash
echo "#########################################"
echo "# Cloudflare dns manager by John Mark C."
echo "#"
echo "#"
# Check argument if valid
if [[ "$1" =~ ^(create|delete|update)$ ]]; then
    echo "# Let's beging!"
    echo "#"
else
    echo "# $1 is not a valid argument. Try ./cf.sh create or ./cf delete"
    exit;
fi

# A bash script to update a Cloudflare DNS A record with the external IP of the source machine
# Used to provide DDNS service for my home
# Needs the DNS record pre-creating on Cloudflare
# Usage: 
# ./cf create
# ./cf delete
# ./cf update

# Cloudflare zone is the zone which holds the record
zone=mydomain.com

## Cloudflare authentication details
## keep these private
cloudflare_auth_email=myemailfromcloudflare@gmail.com
cloudflare_auth_key=30ddbf8bf3744444444553f7953


# Get the current external IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)

echo "# Current IP is $ip"

if host $dnsrecord 1.1.1.1 | grep "has address" | grep "$ip"; then
  echo "# $dnsrecord is currently set to $ip; no changes needed"
 # exit
fi

# Get the zone id for the requested zone
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
  -H "X-Auth-Email: $cloudflare_auth_email" \
  -H "X-Auth-Key: $cloudflare_auth_key" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

echo "# Zoneid for $zone is $zoneid"
echo "#"




### Start
# Creating dns records 
if [ "$1" == "create" ]
  then
  echo "# Enter the domain or subdomain you want to add in Cloudflare DNS"
  echo "# Example: hello.com for primary domain or just hello for subdomain"
  echo "#"
  read -p "# " dnsrecord

  # Create DNS records
  result=$(
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/" \
    -H "X-Auth-Email: $cloudflare_auth_email" \
    -H "X-Auth-Key: $cloudflare_auth_key" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}"
  )
  # echo $result
  if [[ "$result" == *"success\":false"* ]]
    then
     echo "# Failed. "
     echo "#":
     echo "# Result: $result"
    else 
      echo "# Success!!"
      echo "#"
      echo "# Result: $result"
  fi

fi
# Creating dns records 
### END


### Start
# Deleting dns records 
if [ "$1" == "delete" ]
  then
  echo "# Enter the domain or subdomain you want to DELETE in Cloudflare DNS"
  echo "# Example: hello.com for primary domain or just hello for subdomain"
  echo "#"
  read -p "# " dnsrecord

  # Get the DNS record ID
  dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord.${zone}" \
     -H "X-Auth-Email: $cloudflare_auth_email" \
     -H "X-Auth-Key: $cloudflare_auth_key" \
     -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

  echo "# DNS record ID for $dnsrecord is $dnsrecordid" 


  # Confirmation
  read -p "# Are you sure? Enter Y or y " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then

    # Delete DNS records
    echo "# Deleting $dnsrecord dns record.."
    echo "#"
    result=$(
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
      -H "X-Auth-Email: $cloudflare_auth_email" \
      -H "X-Auth-Key: $cloudflare_auth_key" \
      -H "Content-Type: application/json" \
    )
    # echo $result
    if [[ "$result" == *"method_not_allowed"* ]]
      then
      echo "# Failed. Result: $result"
      echo "#"
      echo "# Make sure you entered the correct domain like domain.com or subdomain like hello.domain.com"
      echo "# Or make sure it exist!"
      else 
        echo "# Success!"
        echo "#":
        echo "# Result: $result"
    fi

  fi

fi
# Deleting dns records 
### END


### Start
# Updating dns records 
if [ "$1" == "update" ]
  then

  echo "# Enter the domain or subdomain you want to UPDATE in Cloudflare DNS"
  echo "# Example: hello.com for primary domain or just hello for subdomain"
  echo "#"
  read -p "# " dnsrecord

  # Get the DNS record ID
  dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord.${zone}" \
     -H "X-Auth-Email: $cloudflare_auth_email" \
     -H "X-Auth-Key: $cloudflare_auth_key" \
     -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

  echo "# DNS record ID for $dnsrecord is $dnsrecordid" 

  # Get new IP
  echo "#"  
  read -p "# Enter new IP " newip
  echo "#"  

  # Confirmation
  read -p "# Are you sure? Enter Y or y " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then

    # Delete DNS records
    echo "# Updating $dnsrecord dns record.."
    echo "#"
    result=$(
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
      -H "X-Auth-Email: $cloudflare_auth_email" \
      -H "X-Auth-Key: $cloudflare_auth_key" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$newip\",\"ttl\":1,\"proxied\":false}"
      
    )
    # echo $result
    if [[ "$result" == *"method_not_allowed"* ]]
      then
      echo "# Failed. Result: $result"
      echo "#"
      echo "# Make sure you entered the correct domain like domain.com or subdomain like hello.domain.com"
      echo "# Or make sure it exist!"
      else 
        echo "# Success!"
        echo "#":
        echo "# Result: $result"
    fi

  fi

fi
# Updating dns records 
### END


