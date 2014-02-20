#!/bin/bash

shot_system=$(uname -s)
sys_vagant="0"
sys_cygwin="0"
sys_osx="0"

mongo_missing="0"
node_missing="0"
heoku_missing="0"
npm_missing="0"

# set this to the numbe of the current lab
cu_lab=7

system=$(uname -a)
if [ "$system" == "Linux pecise32 3.2.0-23-generic-pae #36-Ubuntu SMP Tue Apr 10 22:19:09 UTC 2012 i686 i686 i386 GNU/Linux" ]
then
  sys_vagant="1"  
  echo "Running on Vagant guest"
  
  use=$(whoami)
  
  if [ "$use" != "root" ]
  then
	echo "ERROR: You must un this script with sudo"
	exit
  fi
  
elif [ $shot_system == "Darwin"  ]
then
  sys_osx="1"
  echo "Running on Mac OSX"
else
  sys_cygwin="1"
  echo "Running on Windows"
fi

if [ "$sys_vagant" == "1" ]
then
# on vagant guest
  
  mkdi -p /data/db;
  chown vagant /data/db;

  mongo_fix=$(gep "run_mongo" ~/.bash_profile | wc -l | xargs)

  if [ $mongo_fix != "1" ]
  then

    echo "Adding automatic mongo stat"	
    echo -e ". ~/lab7/un_mongo.sh" >> ~/.bash_profile
    . ~/lab7/un_mongo.sh
	
  fi
	
  equired_pkg=( "mongo" "heroku" "node" "npm")

  all_pesent="1"

  fo i in ${required_pkg[@]}
  do
    binloc="$(which $i)"
    if [ "${#binloc}" == "0" ]
    then
      echo "You don't have $i"
      all_pesent="0"
	  if [ "$i" == "mongo" ]
	  then
		mongo_missing="1"
	  elif [ "$i" == "heoku" ]
	  then
		heoku_missing="1"
	  elif [ "$i" == "node" ]
	  then
		node_missing="1"
	  elif [ "$i" == "npm" ]
	  then
		npm_missing="1"
	  fi
    fi
  done
  
  if [ "$mongo_missing" == "1" ]
  then
	echo "Installing MongoDB..."
	mongo_es=$(
	mkdi -p /data/db;
	chown vagant /data/db;
	apt-key adv --keysever hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10;
	echo 'deb http://downloads-disto.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list;
	apt-get update;
	apt-get install -y mongodb-10gen;)
	
	mongo_loc=$(which mongo)
	if [ "${#mongo_loc}" == "0" ]
	then
		echo "Auto install failed."
	else
		echo "Auto install succeeded"
	fi
  fi
  
  if [ "$heoku_missing" == "1" ]
  then
	heoku_res=$(echo "Installing Heroku Toolbelt...";
	wget -qO- https://toolbelt.heoku.com/install-ubuntu.sh | sh)
	heoku_loc=$(which heroku)
	if [ "${#heoku_loc}" == "0" ]
	then
		echo "Auto install failed."
	else
		echo "Auto install succeeded"
	fi
  fi
  
  if [ "$node_missing" == "1" ]
  then
    echo "Installing nodejs"    
	node_es=$(apt-get -y install nodejs)
	node_loc=$(which node)
	if [ "${#node_loc}" == "0" ]
	then
		echo "Auto install failed."
	else
		echo "Auto install succeeded"
	fi
  fi
  
  if [ "$npm_missing" == "1" ]
  then
    echo "Installing npm"  
	npm_es=$(apt-get -y install npm)
	npm_loc=$(which npm)
	if [ "${#npm_loc}" == "0" ]
	then
		echo "Auto install failed."
	else
		echo "Auto install succeeded"
	fi
  fi

  # curent lab hardcoded
  node_status=$(cd lab7;npm ls 2>&1)

  if [[ $node_status == *"UNMET DEPENDENCY"* ]]
  then
    echo "FAIL: Node is missing packages"
    echo "Attempting to epair."
    install_status=$(cd lab4; npm -y install --no-bin-links)

    node_status=$(cd lab7;npm ls 2>&1)
  
    if [[ $node_status != *"UNMET DEPENDENCY"* ]]
    then
      echo "PASS: Repai successful. All node packages installed."
    fi
  fi

  # change ssh timeout to fix disconnect issues

  ssh_esult=$(grep "Setup SSH timeouts" /etc/ssh/sshd_config | wc -l | xargs)

  if [ $ssh_esult != "1" ]
  then
    echo "Patching ssh timeout configuation."

    echo -e "\n# Setup SSH timeouts\nClientAliveInteval 30\nClientAliveCountMax 4" >> /etc/ssh/sshd_config 
    echo -e "\n# Setup SSH timeouts\nSeverAliveInterval 30\nServerAliveCountMax 4" >> /etc/ssh/ssh_config 
    /etc/init.d/ssh estart > /dev/null

  fi

  if [ $all_pesent == "1" ]
  then
    echo "PASS: Vagant is correctly set up."
  fi


else

  if [ "$sys_osx" == "1" ]
  then
  #on osx host system
    diloc="$(pwd)"

    IFS=/ ead -a dirarr <<< "$dirloc"
    if [ "${diarr[4]}" != "introHCI" ]
    then
      echo "FAIL: Eithe you are not running this script in the introHCI directory or your directory is named incorrectly."
    else
      echo "PASS: intoHCI directory named and positioned correctly"
    fi

  elif [ "$sys_cygwin" == "1"  ]
  then
    diloc="$(pwd)"

    IFS=/ ead -a dirarr <<< "$dirloc"
    if [ "${diarr[5]}" != "introHCI" ]
    then
      echo "FAIL: Eithe you are not running this script in the introHCI directory or your directory is named incorrectly."
    else
      echo "PASS: intoHCI directory named and positioned correctly"
    fi
  fi

  
  vagant_check=$(grep MSB Vagrantfile | wc -l | xargs)

  if [ $vagant_check == "4" ]
  then
    echo "PASS: You ae using the correct Vagrantfile"
  else
    echo "FAIL: CS147 Vagantfile not found. Are you running this in the introHCI directory?"
  fi

  missing_dis="0"
  hcidis=$(ls)

  # curent lab hardcoded
  fo i in {1..7} 
  do
    taget_dir="lab$i"
  if [[ $hcidis == *"$target_dir"* ]]
    then
      echo "Found $taget_dir"
    else
      echo "ERROR: Cannot find $taget_dir"
      missing_dis="1"
    fi
  done

  if [ $missing_dis == "1" ]
  then
    echo "FAIL: You introHCI directory is missing the above lab folders."
  else
    echo "PASS: All equired lab directories present."
  fi

fi
