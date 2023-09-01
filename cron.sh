#!/bin/bash
crontab -e
0 0 * * * ./backup.sh  #To run the task daily at 12:00 AM
