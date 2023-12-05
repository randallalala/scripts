#!/bin/bash
# set -x

input="asia_hk_9"
# input="asia_hk_hw_2"
# input="ME_DU_NORTH_M"
# input="AS_HK"
# input="EU_FI_HEL_G"
# input="AF_EG_GZA_TOC"
# input="af_egypt_2"
# echo $input

#  <!-- DS_164_Attr|shadow={ME_DU_NORTH_M},idc=me_dubai_1,cloud=azure,region=dubainorth| -->


touch results.txt

# store array of idc matching the input
idc=($(grep -w "${input}" host.xml | awk -F '|' '{print $2}' | awk -F'[=,]' '{for (i=1; i<=NF; i++) {if ($i == "idc") {print $(i+1)}}}'))
gamesvrs=()

for idc in "${idc[@]}"; do
  zoneid=`cat host.xml | grep -w ${idc} | awk -F '_' '{print $2}'`
  shadow=`cat host.xml | grep -E "<!-- DS_${zoneid}\*| -->" | grep $idc | awk -F'[{}]' '{print$2}'`
  cloud=`cat host.xml | grep -E "<!-- DS_${zoneid}\*| -->" | grep $idc | awk -F'[=,]' '{print$6}'`
  region=`cat host.xml | grep -E "<!-- DS_${zoneid}\*| -->" | grep $idc | awk -F'[=|]' '{print$6}'`

  idcagent_count=0
  gamesvr_count=0
  gsproxy_count=0
  onlinesvrcount=0

    # count gamesvr / idc / gsproxy
  while IFS= read -r line; do
    # ignore commented out lines
    if [[ $line == "<!--"*"-->" ]]; then 
      continue
    elif [[ $line == *"DS_${zoneid}_idcagent"* ]]; then
      idcagent_count=$((idcagent_count + 1))
    elif [[ $line == *"DS_${zoneid}_gamesvr"* ]]; then
      gamesvr_count=$((gamesvr_count + 1))
      gamesvrs+=(`echo $line | awk -F'"' '{print $4}'`)
    elif [[ $line == *"DS_${zoneid}_gsproxy"* ]]; then
      gsproxy_count=$((gsproxy_count + 1))
    # else 
    fi
  done < host.xml

# check if gamesvrs are offline (gsmaxload=0) 
# cat proc_dep.xml | grep -nE "<D.*DS_${zoneid}_gamesvr.*gs_max_load=0.*" | grep -vE "<\!--.*-->"
num=`cat proc_deploy_2.xml | grep -nE "<D.*DS_${zoneid}_gamesvr.*gs_max_load=0.*" | grep -vE "<\!--.*-->" | wc -l`
onlinesvrcount=$((gamesvr_count-num))

echo "${idc}, ${shadow}, ${cloud}, ${region}, $zoneid, ${idcagent_count}, ${onlinesvrcount}/${gamesvr_count}, ${gsproxy_count}" >> results.txt

done

# sort data and put into table with header
echo "idc, shadow, cloud, region, zone, idcagent, gamesvr, gsproxy" | column -t
sort -k1 results.txt | column -t

rm results.txt
