range="$1"
with_time_range=1
filter=""

if [[ $# < 4 ]]; then
    with_time_range=0
    filter=$2
else
    start_time=$2
    end_time=$3
    filter=$4
fi

# echo "first: $1, second: $2, third: $3, fourth: $4\n"

TMP=/tmp/credits
declare -A mail2author
declare -A mail2organization
remap="s/'/ /g"

if [[ $with_time_range -eq 1 ]]; then
    git log --pretty='%ae %aN <%aE>' $range --since=$start_time --until=$end_time | sed -e "$remap" | sort -u > $TMP
else
    git log --pretty='%ae %aN <%aE>' $range | sed -e "$remap" | sort -u > $TMP
fi

while read mail who ; do
    author=$(echo $who | git -c mailmap.file=.peoplemap check-mailmap --stdin)
    mail2author[$mail]="$author"
    organization=$(echo $who | git -c mailmap.file=.organizationmap check-mailmap --stdin)
    mail2organization[$mail]="$organization"
done < $TMP

declare -A author2lines
declare -A organization2lines

if [[ $with_time_range -eq 1 ]]; then
    git log --no-merges --pretty='%ae' $range --since=$start_time --until=$end_time | sed -e "$remap" | sort -u > $TMP
else
    git log --no-merges --pretty='%ae' $range | sed -e "$remap" | sort -u > $TMP    
fi

while read mail ; do 
    if [[ $with_time_range -eq 1 ]]; then
        count=$(git log --numstat --author="$mail" --pretty='%h' $range --since=$start_time --until=$end_time | 
        perl -e 'while(<STDIN>) { if(/(\d+)\t(\d+)/) { $added += $1; $deleted += $2 } }; print $added + $deleted;')
    else
        count=$(git log --numstat --author="$mail" --pretty='%h' $range | 
        perl -e 'while(<STDIN>) { if(/(\d+)\t(\d+)/) { $added += $1; $deleted += $2 } }; print $added + $deleted;')
    fi
    (( author2lines["${mail2author[$mail]}"] += $count ))
    (( organization2lines["${mail2organization[$mail]}"] += $count ))
done < $TMP

echo
echo "Number of lines added and removed, by authors"
for author in "${!author2lines[@]}" ; do
    printf "%6s %s\n" ${author2lines["$author"]} "$author"
done | sort -rn | nl | grep "$filter"

echo
echo "Number of lines added and removed, by organization"
for organization in "${!organization2lines[@]}" ; do
    printf "%6s %s\n" ${organization2lines["$organization"]} "$organization"
done | sort -rn | nl | grep "$filter"

echo
echo "Commits, by authors"
if [[ $with_time_range -eq 1 ]]; then
    git log --no-merges --pretty='%aN <%aE>' $range --since=$start_time --until=$end_time | git -c mailmap.file=.peoplemap check-mailmap --stdin | sort | uniq -c | sort -rn | nl | grep $filter
else
    git log --no-merges --pretty='%aN <%aE>' $range  | git -c mailmap.file=.peoplemap check-mailmap --stdin | sort | uniq -c | sort -rn | nl | grep $filter
fi

echo
echo "Commits, by organizations"
if [[ $with_time_range -eq 1 ]]; then
    git log --no-merges --pretty='%aN <%aE>' $range --since=$start_time --until=$end_time | git -c mailmap.file=.organizationmap check-mailmap --stdin | sort | uniq -c | sort -rn | nl | grep $filter
else
    git log --no-merges --pretty='%aN <%aE>' $range | git -c mailmap.file=.organizationmap check-mailmap --stdin | sort | uniq -c | sort -rn | nl | grep $filter
fi

# echo
# echo "Reviews, by authors (one review spans multiple commits)"
# git log --pretty=%b $range | perl -n -e 'print "$_\n" if(s/^\s*Reviewed-by:\s*(.*<.*>)\s*$/\1/i)' | git check-mailmap --stdin | git -c mailmap.file=.peoplemap check-mailmap --stdin | sort | uniq -c | sort -rn | nl
# echo
# echo "Reviews, by organizations (one review spans multiple commits)"
# git log --pretty=%b $range | perl -n -e 'print "$_\n" if(s/^\s*Reviewed-by:\s*(.*<.*>)\s*$/\1/i)' | git check-mailmap --stdin | git -c mailmap.file=.organizationmap check-mailmap --stdin | sort | uniq -c | sort -rn | nl

#echo "Commits, by authors and monthly"
#git log --no-merges --pretty='%aN <%aE>' $range --since=2016-04-01 --until=2016-04-30 | git -c mailmap.file=.peoplemap check-mailmap --stdin | sort | uniq -c | sort -rn | nl | grep "@h3c.com"  > stats_april.txt
