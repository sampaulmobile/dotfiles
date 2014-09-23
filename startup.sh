#!/bin/bash
############################
# startup.sh
# This script starts up all the appropriate services for development
############################


DOC_HOME='/Users/sampaul/Development/Docurated'

plunchy start redis
plunchy start post
plunchy start mongo

cd $DOC_HOME/scratch/clients/mvc/browser && coffee --watch --compile --output lib/ src/ &
cd $DOC_HOME/scratch/clients/mvc && python -m SimpleHTTPServer &

cd $DOC_HOME/website/rails/opt/solr/jetty && java -Dsolr.solr.home=docu -jar start.jar &
# cd $DOC_HOME/website/rails rvm gemset use docurated bundle exec sunspot-solr start -p 8984
