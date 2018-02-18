#!/bin/bash
set -e

# check for required commands
which wget && which unzip && which dos2unix && which sed && which sqlite3

if [ -z "$1" ]; then 
    echo "USAGE: $0 DBPATH"
    exit 1
fi

# set SQLite DB file location
DB_FILE=$1

# first download and unzip USDA National Nutrient Database (Release SR-28) ASCII version
wget https://www.ars.usda.gov/SP2UserFiles/Place/12354500/Data/SR/SR28/dnload/sr28asc.zip
unzip ./sr28asc.zip

# transform all data files from DOS to UNIX file format
dos2unix *.txt

echo "Transforming into CSV"
# Escape all double quotes
sed "s/\"/\"\"/g" -i *.txt
# Replace ~ with "
sed "s/~/\"/g" -i *.txt
# Replace ^ with ,
sed "s/\^/,/g" -i *.txt

# create database with predefined schema
echo "Importing schema"
sqlite3 "${DB_FILE}" < ./sr28_schema.sql 

# import USDA SR-28 data files into predefined table schema
echo "Importing data"
cat << EOM |
.mode "csv";
.import ./FD_GROUP.txt FD_GROUP
.import ./FOOD_DES.txt FOOD_DES
.import ./DATA_SRC.txt DATA_SRC
.import ./DERIV_CD.txt DERIV_CD
.import ./FOOTNOTE.txt FOOTNOTE
.import ./LANGDESC.txt LANGDESC
.import ./WEIGHT.txt WEIGHT
.import ./NUTR_DEF.txt NUTR_DEF
.import ./LANGUAL.txt LANGUAL
.import ./SRC_CD.txt SRC_CD
.import ./DATSRCLN.txt DATSRCLN
.import ./NUT_DATA.txt NUT_DATA
EOM
sqlite3 "${DB_FILE}" -echo

echo "USDA National Nutrient Database imported successfully"
echo "Cleaning up"
rm *.txt *.zip *.pdf
