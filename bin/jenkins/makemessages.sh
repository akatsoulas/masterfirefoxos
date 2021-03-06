#!/bin/bash
#
# Fetches the latest strings from the database and codebase and
# updates the locale repository.
#
# Needs DEIS_USER, DEIS_PASSWORD, DEIS_CONTROLLER, DEIS_APP and
# LOCALE_REPOSITORY environment variables.
#
# To set them go to Job -> Configure -> Build Environment -> Inject
# passwords and Inject env variables
#

set -ex

TDIR=`mktemp -d`
virtualenv $TDIR
. $TDIR/bin/activate
pip install deis==1.1.0
pip install fig

rm -rf locale db-strings.txt
git clone $LOCALE_REPOSITORY locale

deis login $DEIS_CONTROLLER --username $DEIS_USERNAME --password $DEIS_PASSWORD
deis run -a $DEIS_APP -- "./manage.py db_strings && cat db-strings.txt" > db-strings.txt

fig --project-name jenkins${JOB_NAME}${BUILD_NUMBER} run -T web ./manage.py makemessages -a
fig --project-name jenkins${JOB_NAME}${BUILD_NUMBER} run -T web chmod a+wx -R locale

cd locale
git commit -a -m "Update strings."
git push origin master
