#!/bin/bash

bluetoothctl info | grep "Battery Percentage" | grep -oP '\(\K\d+'