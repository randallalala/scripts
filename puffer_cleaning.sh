!/bin/bash
Productnum=1223
keepnumber=35 # num of versions to keep
echo "removing prod- $Productnum"
echo "keeping $keepnumber versions"


# confirmation function
confirm() {
  read -p "Are you sure? (y/n): " answer < /dev/tty
  case ${answer:0:1} in
      y|Y )
          echo "Confirmed"; return 0 ;;
      * )
          echo "Cancelled"; return 1 ;;
  esac
}
confirm


# pull version info
./gcloud_openapi.py --host=101.32.253.205:8927 --gameid=100000001 --module=dynupdate --action=QueryRes --accessid='d95zfszY24fTNX1sSuYryxWxh1EE' --accesskey='AH8ASP2dr4cNF5P4FcFXdjvV1d4E' --more="ProductID=$Productnum" > temp.json


# reformat into proper json
sed -i "s/'/\"/g" temp.json
sed -i 's/""RES""/"RES"/g'  temp.json
sed -i 's/""SelfUpdate""/"SelfUpdate"/g'  temp.json
sed -i 's/"{"skip_dolphin":true}"/"skip_dolphin:true"/g' temp.json
sed -i 's/"{"skip_dolphin":true}\\n"/"skip_dolphin:true"/g' temp.json


# count versions & wait for confirmation
echo "-- counting versions"
jq '.result[].ResLine[]' temp.json | grep -i versionstr  | awk -F '"' '{print $4}'

currnumber=$(jq '.result[].ResLine[]' temp.json | grep -i versionstr  | awk -F '"' '{print $4}' | wc -l)
echo "num of versions -$currnumber"
confirm
newnumber=$((currnumber - $keepnumber))
if [ $newnumber -lt 1 ]; then
  echo "less than $keepnumber versions - exiting "
  exit 1
else
  jq '.result[].ResLine[]' temp.json | grep -i versionstr  | awk -F '"' '{print $4}' | tail -$newnumber > versions.txt
  echo "removing  $newnumber versions"
  cat versions.txt
fi
confirm


# DeleteRes 
while read -r version; do
    echo $version
    ./gcloud_openapi.py --host=101.32.253.205:8927 --debug --gameid=100000001 --module=update --action=DeleteResVersion --accessid='d95zfszY24fTNX1sSuYryxWxh1EE' --accesskey='AH8ASP2dr4cNF5P4FcFXdjvV1d4E' --more="ProductID=$Productnum&Uin=283020742&VersionStr=${version}"
# confirm
done  < versions.txt


# Post Delete PREPUBLISH (REFRESH )
./gcloud_openapi.py --host=101.32.253.205:8927 --debug --gameid=100000001 --module=update --action=PrePublish --accessid='d95zfszY24fTNX1sSuYryxWxh1EE' --accesskey='AH8ASP2dr4cNF5P4FcFXdjvV1d4E' --more="ProductID=$Productnum&Uin=283020742"
echo "all completed"


# check if any parents without child
echo ">" > data.txt
jq '[.result[] | {VersionName, ResLine: [.ResLine[].VersionName]}] | group_by(.VersionName)[] | {VersionName: .[].VersionName, ChildVersion: [.[].ResLine[]]}' temp.json >> data.txt
echo ">" >> data.txt
# reformat }{ to },{ (settles whitespace too)
sed -i ':a;N;$!ba;s/}\s*{/},\n{/g' data.txt
EmptyParent=$(jq -r 'map(select(.ChildVersion == [])) | .[].VersionName' data.txt)
echo "EmptyParent -$EmptyParent"
 > logs.txt
for parentversion in $EmptyParent; do
    # Delete the version here
    {
        # Try to delete the version
        echo "Deleting version $parentversion"
        ./gcloud_openapi.py --host=101.32.253.205:8927 --gameid=100000001 --module=update --action=DeleteVersion --accessid='d95zfszY24fTNX1sSuYryxWxh1EE' --accesskey='AH8ASP2dr4cNF5P4FcFXdjvV1d4E' --more="ProductID=$Productnum&Uin=283020742&VersionStr=${parentversion}"
    } || {
        # If an error occurs, log it to logs.txt
        echo "Error deleting version $parentversion" >> logs.txt
    }
done
# Display the contents of logs.txt
cat logs.txt



# Post Delete PREPUBLISH (REFRESH )
./gcloud_openapi.py --host=101.32.253.205:8927 --debug --gameid=100000001 --module=update --action=PrePublish --accessid='d95zfszY24fTNX1sSuYryxWxh1EE' --accesskey='AH8ASP2dr4cNF5P4FcFXdjvV1d4E' --more="ProductID=$Productnum&Uin=283020742"
echo "all completed"


# : <<'END_COMMENT'

# END_COMMENT