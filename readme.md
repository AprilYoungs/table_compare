#### 功能

编写了一个shell用来比较两个hive表的字段差异,并把比较结果输出到一个csv文件

### 使用方式

1. 创建配置文件your_tables.properties, 格式如下

   ```shell
   # 左边对应的db
   db1=test1
   # 右边对应的db
   db2=test2
   # 左边需要比较的所有表
   tabs1=tab1,tab2
   # 右边需要比较的所有表
   tabs2=tab3,tab4
   # 以上配置注意格式,=两边不能有空格,多张表用“,”隔开,注意tabs1和tabs2的表需要一一对应
   ```
   
2. 运行比较脚本

   下载`tab_compare.sh` 到可以运行hive的服务器,并上传配置文件`your_tables.properties`到服务器

   执行如下指令

   ```shell
   sh tab_compare.sh your_tables.properties
   ```

   如果没有出异常,结果会输出到相同目录下的`result`文件夹中

3. 结果文件.csv, 文件名为比较的两张表名用_连接起来,比如tab1_tab3.csv

   | **tab1** | **date_type** | **is_shared** | **tab3** | **date_type** | **is_shared** |
   | -------- | ------------- | ------------- | -------- | ------------- | ------------- |
   | **var1** | string        | Shared        | var1     | string        | Shared        |
   | **var2** | string        | Unique        | var3     | string        | Shared        |
   | **var3** | string        | Shared        | var4     | string        | Shared        |
   | **var4** | string        | Shared        | var5     | string        | Unique        |

   第一列是左表对应的列名

   第二列是左表对应列名的数据类型

   第三列是左表表示左边对应列是否在右表中存在, `Shared`表示存在,`Unique`表示不存在

   第四列是右表对应的列名

   第五列是右表对应列名的数据类型

   第六列是右表表示左边对应列是否在右表中存在, `Shared`表示存在,`Unique`表示不存在

4. 自定义比较规则, 默认是比较`字段,数据类型`,如果只是相比`字段`,可以改`tab_compare.sh`下面这几行的比较逻辑

   ```shell
    45     for c1 in $cols1;do
    46         isShared="Unique"
    47         for c2 in $cols2;do
    48             # more detail compare and update the flag if you like
    49             if [ "$c1" = "$c2" ];then
    50                 isShared="Shared"
    51                 break
    52             fi
    53         done
    54         echo "$c1,$isShared" >> $tab_res
    55     done
   ```

   
