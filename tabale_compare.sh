#!/bin/bash

if [ $# -eq 0 ]; then
    echo "please run with a config file like:"
    echo "db1=test"
    echo "db2=test"
    echo "tabs1=tab1,tab2"
    echo "tabs2=tab3,tab4"
    exit 1
fi

config_file=$1

# get params from config files
db1=$(sed -n '/^db1=/s/db1=//p' $config_file | awk '{print $1}')
db2=$(sed -n '/^db2=/s/db2=//p' $config_file | awk '{print $1}')
tabs1=($(sed -n '/^tabs1=/s/tabs1=//p' $config_file | awk 'BEGIN{FS=","}{for(i=1;i<=NF;i++) print $i}'))
tabs2=($(sed -n '/^tabs2=/s/tabs2=//p' $config_file | awk 'BEGIN{FS=","}{for(i=1;i<=NF;i++) print $i}'))

echo "db1=$db1,db2=$db2"
echo "input tables left: ${tabs1[@]}"
echo "input tables right: ${tabs2[@]}"

tabs1_len=${#tabs1[@]}
tabs2_len=${#tabs2[@]}

if [ $tabs1_len -ne $tabs2_len ];then
    echo "tables number should be paired!"
    echo "But I got $tabs1_len and $tabs2_len"
    exit 1
fi


## compare table 1 with table 2 with column,dateType, and cache the result
colums_compare(){
    local cols1=$1
    local cols2=$2
    local tab_res=$3
    
    if [ -f $tab_res ]; then
        rm -f $tab_res 
    fi
    touch $tab_res

    for c1 in $cols1;do 
        isShared="Unique"
        for c2 in $cols2;do  
            # more detail compare and update the flag if you like
            if [ "$c1" = "$c2" ];then
                isShared="Shared"
                break
            fi            
        done 
        echo "$c1,$isShared" >> $tab_res
    done
}

## merge two tables' compare result into one csv file 
export_result(){
    local tab_result1=$1
    local tab_result2=$2
    local tab1=$3
    local tab2=$4

    # export result
    test -d result || mkdir result

    # merge_file
    tab_len1=$(wc -l $tab_result1 | awk '{print $1}')
    tab_len2=$(wc -l $tab_result2 | awk '{print $1}')

    if [ $tab_len1 -ge $tab_len2 ]; then 
        max_len=$tab_len1
    else
        max_len=$tab_len2
    fi 

    # prepare result file
    local result_file="result/${tab1}_${tab2}.csv"
    if [ -f $result_file ]; then
        rm -f $result_file 
    fi
    touch $result_file

    # header 
    echo "${tab1},date_type,is_shared,${tab2},date_type,is_shared" >> $result_file

    # escape with the globe i
    local i
    for ((i=1;i<=max_len;i++));do 
        if (( $i <= $tab_len1 && $i <= $tab_len2 )); then 
            left=$(sed -n "${i}p" $tab_result1)
            right=$(sed -n "${i}p" $tab_result2)    
        elif (( $i > $tab_len1 && $i <= $tab_len2 )); then 
            left=",,"
            right=$(sed -n "${i}p" $tab_result2)    
        elif (( $i <= $tab_len1 && $i > $tab_len2 )); then 
            left=$(sed -n "${i}p" $tab_result1)
            right=",,"
        fi

        echo "${left},${right}" >> $result_file
    done  

    echo "done exporting"
}

# tmp dir 
test -d tmp || mkdir tmp

for ((i=0;i<$tabs1_len;i++));do
    tab1=${tabs1[$i]}
    tab2=${tabs2[$i]}
    echo "dealing with ${db1}.${tab1}"
    echo "dealing with ${db2}.${tab2}"

    hive -e "desc ${db1}.${tab1}" > tmp/$tab1.txt
    hive -e "desc ${db2}.${tab2}" > tmp/$tab2.txt

    # add "" to datatype to avoid unexpected csv format error
    cols1=$(cat tmp/$tab1.txt | awk 'BEGIN{OFS=","}{if(NR>1) {print tolower($1),"\"" tolower($2) "\""}}')
    cols2=$(cat tmp/$tab2.txt | awk 'BEGIN{OFS=","}{if(NR>1) {print tolower($1),"\"" tolower($2) "\""}}')

    tab_result1="tmp/${tab1}.result"
    tab_result2="tmp/${tab2}.result"


    colums_compare "${cols1}" "${cols2}" $tab_result1
    colums_compare "${cols2}" "${cols1}" $tab_result2

    echo "exporting result....."

    export_result $tab_result1 $tab_result2 ${tab1} ${tab2}
    
done

#rm -rf tmp

echo "all done, enjoy..."

cd result
echo "result files...."
ls

# send result files back to local if support
sz *.csv