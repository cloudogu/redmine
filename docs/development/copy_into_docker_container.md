# Um ein bash-script in ein docker container zu verschieben
##Syntax:
docker cp <src-path> <container>:<dest-path> 
docker cp /vagrant/containers/redmine/resources/delete-plugin.sh redmine:/

bash-scripte liegen im docker container unter root