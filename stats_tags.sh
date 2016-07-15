#!/bin/bash
start_time="$1"
end_time="$2"

TMP=/tmp/tags
git tag -l | sort -t. -n -k1.2 > $TMP
tagtime=/tmp/tagstime
rangeres=/tmp/range

start_tags=""
end_tags=""
start_tags_time=""
end_tags_time=""

rm -rf $tagtime $rangeres

while read tag ; do
    tag_time=`git show $tag --date=short | grep -i date: | head -n 1 | awk -F: '{print $2}' | sed 's/^[][ ]*//g'`
    # echo
    # echo "$tag_time\t$start_time\t$end_time"
    if [[ $tag_time > $start_time && $tag_time < $end_time ]]; then
        echo "$tag,$tag_time" >> $tagtime
        end_tags=$tag
        end_tags_time=$tag_time
        if [[ $start_tags != "" && $start_tags_time < $end_tags_time ]]; then
            echo "$start_tags..$end_tags" >> $rangeres
        fi
        start_tags=$end_tags
        start_tags_time=$end_tags_time
    fi
done < $TMP

while read range ; do
    ./credits.sh $range "@h3c.com" > "./$range.txt"
done < $rangeres

range="$start_tags..master"
./credits.sh $range "$start_time" "$end_time" "@h3c.com" > "./$range.txt"


