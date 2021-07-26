#!/bin/bash

db1=test
db2=test
tabs1=(tab1 tab2)
tabs2=(tab3 tab4)

tabs1_c=${#tabs1[@]}
tabs2_c=${#tabs2[@]}

if [ $tabs1_c -ne $tabs2_c ];then
    echo "tables number should be paired!"
    echo "But I got $tabs1_c and $tabs2_c"
    exit 1
fi

## 比较表1的列是否都在表2中存在,并把结果存在tab中缓存
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
            if [ "$c1" = "$c2" ];then
                isShared="Shared"
                break
            fi            
        done 
        echo "$c1,$isShared" >> $tab_res
    done
}

## 合并两个表的差异文件到一个csv
export_result(){
    local tab_result1=$1
    local tab_result2=$1
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
    result_file="result/${tab1}_${tab2}.csv"
    if [ -f $result_file ]; then
        rm -f $result_file 
    fi
    touch $result_file

    echo "${tab1}_col,${tab1}_date_type,${tab1}_isShared,${tab2}_col,${tab2}_date_type,${tab2}_isShared" >> $result_file
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

for ((i=0;i<$tabs1_c;i++));do
    tab1=${tabs1[$i]}
    tab2=${tabs2[$i]}
    echo "dealing with ${db1}.${tab1}"
    echo "dealing with ${db2}.${tab2}"

    hive -e "desc ${db1}.${tab1}" > tmp/$tab1.txt
    hive -e "desc ${db2}.${tab2}" > tmp/$tab2.txt

    cols1=$(cat tmp/$tab1.txt | awk 'BEGIN{OFS=","}{if(NR>1) {print tolower($1),tolower($2)}}')
    cols2=$(cat tmp/$tab2.txt | awk 'BEGIN{OFS=","}{if(NR>1) {print tolower($1),tolower($2)}}')

    tab_result1="tmp/${tab1}.result"
    tab_result2="tmp/${tab2}.result"


    colums_compare "${cols1}" "${cols2}" $tab_result1
    colums_compare "${cols2}" "${cols1}" $tab_result2

    echo "exporting result....."

    export_result $tab_result1 $tab_result2 ${tab1} ${tab2}
    echo "why---->"$?
done

#rm -rf tmp

echo "all done, enjoy...":