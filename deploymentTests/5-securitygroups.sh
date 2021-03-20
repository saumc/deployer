#!/usr/bin/env bash
echo Install pipeapple first
which go
sudo go get -u github.com/jvehent/pineapple
#echo which pipeapple 
which pineapple
echo Running security groups check 
#echo pineapple version - gopath 
$GOPATH/bin/pineapple -V

echo pineapple version - straight 
pineapple -V

rundir=`pwd`


echo "Locate yaml?"
ls $rundir/deploymentTests/myconfig.yaml


$GOPATH/bin/pineapple -c $rundir/deploymentTests/myconfig.yaml

pineapple -c $rundir/deploymentTests/myconfig.yaml
