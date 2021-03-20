#!/usr/bin/env bash
echo Install pipeapple first
which go
go get -u github.com/jvehent/pineapple
echo which pipeapple 
which pineapple
echo Running security groups check

$GOPATH/bin/pineapple <<EOF
aws:
    region: ap-south-1
    accountnumber: 690890622406

components:
    - name: load-balancer
      type: elb
      tag:
          key: elasticbeanstalk:environment-name
          value: invoicer-api

    - name: application
      type: ec2
      tag: 
          key: elasticbeanstalk:environment-name
          value: invoicer-api

    - name: database
      type: rds
      tag:
          key: environment-name
          value: invoicer-api

#    - name: bastion
#      type: ec2
#      tag:
#          key: environment-name
#          value: invoicer-bastion

rules:
    - src: 0.0.0.0/0
      dst: load-balancer
      dport: 443

    - src: load-balancer
      dst: application
      dport: 80

    - src: application
      dst: database
      dport: 5432

#    - src: bastion
#      dst: application
#      dport: 22
#
#    - src: bastion
#      dst: database
#      dport: 5432
EOF
