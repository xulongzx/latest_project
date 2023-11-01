#!/bin/bash

#Check platform
cat /sys/class/dmi/id/board_name | grep -i ElkhartLake
if [ $? -eq 0 ]; then
  echo "Check platform over."
else
  echo "skip,Platform doesn't support ECLite driver"
  exit 1
fi

#Check os
echo "Check os !!!"
cat /etc/issue | grep -i ubuntu
result1=$?
cat /etc/redhat-release | grep -i centos
result2=$?
cat /etc/redhat-release | grep -i 'red hat'
result3=$?
if [ $result1 -eq 0 -o $result2 -eq 0 -o $result3 -eq 0 ];then
  kernel_version=$(uname -r)
  cat_config=$(cat "/boot/config-$kernel_version")
else
  cat_config=$(zcat "/proc/config.gz")
fi

#Check config
if [[ $cat_config =~ "CONFIG_INTEL_ISHTP_ECLITE=m" ]];then
  echo "Check config over."
else
  echo "fail;CONFIG_INTEL_ISHTP_ECLITE=m doesn’t enable."
  exit 1
fi


#Check module probe
output=$(lsmod | grep -i ishtp_eclite)
if [[ $output =~ "ishtp_eclite" ]] && [[ $output =~ "intel_ishtp" ]];then
  echo "Check module over."
  echo "output: $output"
else
  echo "Module not found, try to mount."
  $(modprobe ishtp_eclite)
  if [ $? -eq 0 ];then
    output=$(lsmod | grep -i ishtp_eclite)
    echo "output: $output"
    if [[ $output =~ "ishtp_eclite" ]] && [[ $output =~ "intel_ishtp" ]];then
      echo "Check module over"
    else
      echo "Module mount failed."
    fi
  else
    echo "Module mount failed."
  fi
fi

#Check ishtp-eclite read:
if [[ $cat_config =~ "CONFIG_DYNAMIC_DEBUG=y" ]];then
  dynamic_debug=true
  echo "file *ecl* +p" > /sys/kernel/debug/dynamic_debug/control
else
  "Platform doesn’t support kernel dynamic debug, skip log check."
fi

if [[ $(cat "/sys/class/thermal/thermal_zone0/type") =~ "acpitz" ]];then
  cat /sys/class/thermal/thermal_zone0/temp
  if [ $? -eq 0 ];then
    echo "Read over."
  else
    echo "fail,/sys/class/thermal/thermal_zone0/temp read fail."
    exit 1
  fi
else 
  echo "fail,ECLite thermal zone is not correct."
  exit 1
fi

if $dynamic_debug;then
  output=$(dmesg | grep -i "ishtp-eclite" | grep -i "ish_rd")
  if [ $? -eq 0 ];then
    echo "Eclite test pass."
  else
    echo "Eclite test fail."
  fi
fi
echo>1.log
