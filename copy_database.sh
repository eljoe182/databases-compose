#!/bin/bash

BAK=$1

docker cp $BAK sqlserver2017:/var/opt/mssql/backup
