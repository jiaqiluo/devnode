#!/bin/bash
set -x

# Function to attempt a command up to 10 times
retry_command() {
    local COMMAND=$@
    local MAX_ATTEMPTS=10
    local ATTEMPT=0

    while (( ATTEMPT < MAX_ATTEMPTS )); do
        ATTEMPT=$((ATTEMPT + 1))
        echo "Attempt $ATTEMPT of $MAX_ATTEMPTS: $COMMAND"

        EXIT_MSG=$($COMMAND 2>&1)
        EXIT_CODE=$?
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "Command succeeded on attempt $ATTEMPT."
            return 0
        else
            echo "Command failed with exit code $EXIT_CODE."
            echo "Error: $EXIT_MSG"
        fi

        sleep 5
    done

    echo "Command failed after $MAX_ATTEMPTS attempts."
    return 1
}

# Install the user's public key in case they need to debug an issue
echo "$CORRAL_corral_user_public_key" >> /$(whoami)/.ssh/authorized_keys

curl https://releases.rancher.com/install-docker/27.2.sh | sudo sh
sudo groupadd docker
sudo usermod -aG docker $USER
sudo service docker restart
sudo systemctl enable docker
sudo systemctl start docker

sudo apt-get -qq update >/dev/null
retry_command sudo apt-get -qq install -y build-essential apache2-utils >/dev/null

curl -SL https://github.com/docker/compose/releases/download/v2.30.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

snap refresh
retry_command snap install --classic go
retry_command snap install --classic certbot
retry_command snap install yq

# check all components
docker version
docker-compose -v
go version
make -v
yq --version

# generate the certs
certbot certonly --standalone -d "$CORRAL_registry_host" -m xegom53748@xegom53748.com  --non-interactive  --agree-tos
mkdir -p /etc/nginx/certs
cp /etc/letsencrypt/live/"$CORRAL_registry_host"/fullchain.pem /etc/nginx/certs/fullchain.pem
cp /etc/letsencrypt/live/"$CORRAL_registry_host"/privkey.pem /etc/nginx/certs/privkey.pem

# corral variables are available as environment variables with the prefix `CORRAL_`
sed -i "s/HOSTNAME/$CORRAL_registry_host/g" /etc/nginx/nginx.conf

cd /opt/corral
docker-compose up -d
