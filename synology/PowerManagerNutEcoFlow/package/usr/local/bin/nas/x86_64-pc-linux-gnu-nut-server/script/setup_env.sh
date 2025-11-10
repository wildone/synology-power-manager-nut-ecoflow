#!/bin/bash

CURRENT_DIR=$(pwd)
BASE_DIR=$CURRENT_DIR/x86_64-pc-linux-gnu-nut-server
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Folder $BASE_DIR does not exist."
    exit 1
fi

# udev 添加权限
RULES_FILE="$BASE_DIR/etc/udev/rules.d/62-nut-usbups.rules"
TARGET_DIR="/etc/udev/rules.d/"
if [ ! -f "$RULES_FILE" ]; then
    echo "Source udev rules file does not exist: $RULES_FILE"
    exit 1
fi
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p $TARGET_DIR
fi
sudo cp "$RULES_FILE" "$TARGET_DIR"
sudo udevadm control --reload-rules
sudo udevadm trigger

# 拷贝动态库
TARGET_DIR="/usr/lib"
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p $TARGET_DIR
fi
sudo cp "$BASE_DIR/lib/libnutscan.so.2.0.5" "$TARGET_DIR/libnutscan.so.2"
sudo chmod 755 ${TARGET_DIR}/libnutscan.so.2
sudo cp "$BASE_DIR/lib/libltdl.so.7" "$TARGET_DIR/libltdl.so.7"
sudo chmod 755 ${TARGET_DIR}/libltdl.so.7
sudo cp "$BASE_DIR/lib/libusb-1.0.so.0" "$TARGET_DIR/libusb-1.0.so"
sudo chmod 755 ${TARGET_DIR}/libusb-1.0.so
sudo cp "$BASE_DIR/lib/libusb-1.0.so.0" "$TARGET_DIR/libusb-1.0.so.0"
sudo chmod 755 ${TARGET_DIR}/libusb-1.0.so.0
sudo cp "$BASE_DIR/lib/libupsclient.so.6.0.1" "$TARGET_DIR/libupsclient.so"
sudo chmod 755 ${TARGET_DIR}/libupsclient.so
sudo cp "$BASE_DIR/lib/libupsclient.so.6.0.1" "$TARGET_DIR/libupsclient.so.4"
sudo chmod 755 ${TARGET_DIR}/libupsclient.so.4
sudo cp "$BASE_DIR/lib/libupsclient.so.6.0.1" "$TARGET_DIR/libupsclient.so.6"
sudo chmod 755 ${TARGET_DIR}/libupsclient.so.6

echo "Installation completed successfully."
