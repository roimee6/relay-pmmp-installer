ACTUAL_PATH=$(echo "$PWD/")

PHP_BIN="$ACTUAL_PATH/bin/php7/bin"
PHP_CONFIG="$PHP_BIN/php-config"
PHP_INI="$PHP_BIN/php.ini"

echo $ACTUAL_PATH
echo $PHP_BIN
echo $PHP_CONFIG
echo $PHP_INI

RELAY_VERSION="dev"
RELAY_PHP=$($PHP_CONFIG --version | cut -c -3)
RELAY_EXT_DIR=$($PHP_CONFIG --extension-dir)
RELAY_ARCH=$(arch | sed -e 's/arm64/aarch64/;s/amd64\|x86_64/x86-64/')

index=$(echo "$RELAY_EXT_DIR" | awk -F'bin' '{print length($1)}')
RELAY_EXT_DIR="$ACTUAL_PATH${RELAY_EXT_DIR:index}"

echo $RELAY_PHP
echo $RELAY_EXT_DIR
echo $RELAY_ARCH

RELAY_ARTIFACT="https://builds.r2.relay.so/$RELAY_VERSION/relay-$RELAY_VERSION-php$RELAY_PHP-debian-$RELAY_ARCH+zts.tar.gz"
RELAY_TMP_DIR=$(mktemp -d -t relay.XXXXXXXXXX)

curl -sSL "$RELAY_ARTIFACT" | tar -xz --strip-components=1 -C "$RELAY_TMP_DIR"
sed -i "s/00000000-0000-0000-0000-000000000000/$(cat /proc/sys/kernel/random/uuid)/" "$RELAY_TMP_DIR/relay-pkg.so"

sudo mkdir -p "$RELAY_EXT_DIR"
sudo cp "$RELAY_TMP_DIR/relay-pkg.so" "$RELAY_EXT_DIR/relay.so"

sed -i 's/^;\? \?relay.maxmemory =.*/relay.maxmemory = 128M/' "$RELAY_TMP_DIR/relay.ini"
sed -i 's/^;\? \?relay.eviction_policy =.*/relay.eviction_policy = lru/' "$RELAY_TMP_DIR/relay.ini"
sed -i 's/^;\? \?relay.environment =.*/relay.environment = production/' "$RELAY_TMP_DIR/relay.ini"

sudo mkdir -p ./relay
sudo cp "$RELAY_TMP_DIR/relay.ini" ./relay/relay.ini

echo >> $PHP_INI && cat ./relay/relay.ini >> $PHP_INI

sudo rm -r ./relay/
