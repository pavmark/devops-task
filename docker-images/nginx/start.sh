#!/bin/sh
svscanboot &

nginx -g "daemon off;"
