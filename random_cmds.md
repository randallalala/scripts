# delete all non txt-files in the current directory:
# find . -type f -not -name '*txt' -print0 | xargs -0 rm --

# delete all files except log folder
cd /data/home/user00 || exit
echo "--before"
ls -la
find .  ! -name log | xargs rm -rf
echo "--after"
ls -la


