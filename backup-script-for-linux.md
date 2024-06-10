#Serverlərin BackUp olunmasının prasedur qaydası
#Seafile serveri backup etmək. Biz bu serveri qısa bir shell scripting yazılıb və bu script əməliyyat systemində həm APP-ni həmdə DBA-nı backup edir.
#Yazılmış script bundan ibarətdir
#1. Mysql backup edirik script mysql serveri dayandırır
##############
#!/bin/bash
ps auxw | grep mysqld | grep -v grep > /dev/null
if [ $? != 0 ]
then
        systemctl stop mariadb  > /dev/null
fi
############

#2.Sonra Mysql Serveri backup edirik mysqldump vastəsi ilə müəyyən olunmuş backup qovluğuna 
############

mysqldump -u root –password='sql root password here' --all-databases  > $DES/$SQLFILE 

########
#2. Seafile serveri seafile və seahub servicelərini dayandırırıq
############### Seafile and Seahub stop ###################

ps auxw | grep seafile | grep -v grep > /dev/null

if [ $? != 0 ]
then
    	systemctl stop seafile.service  > /dev/null
fi
ps auxw | grep seahub | grep -v grep > /dev/null
if [ $? != 0 ]
then
    	systemctl stop seahub.service  > /dev/null
fi
########################################################
#33.Ngnix server və App tar vastəsi ilə bacup olunur
#####################
 $TAR cfj  $DES/$SEAFILE.$DATE.tar.bz2  --exclude=/opt/seafile/ccnet/ccnet.sock --absolute-names $SEAF
####################
#4.Bütün backupları ssh vastəsi ilə scp vastəsi ilə serverə göndəririk

######################################################
scp $FILE  $FILE1 user@$IP:/home/user/bk-server
######################################################
#5.Köhnə backupların silinməsi
######################################################
if [ "(ls -A  $DES)" ]
  then
    echo "Silinid `find $DES -type f \( -name *.sql -o -name *.tar.bz2 \) -delete `"
 fi
######################################################
#6. Sonda bütün servicelər start olunur
######################################################
################## Start mariadb ##################
ps auxw | grep mysqld | grep -v grep > /dev/null
if [ $? != 0 ]
then
    	 systemctl start mariadb  > /dev/null
fi
################## Start Seahub and seafile #######
ps auxw | grep seafile | grep -v grep > /dev/null
if [ $? != 0 ]
then
    	systemctl start seafile.service  > /dev/null
fi
ps auxw | grep seahub | grep -v grep > /dev/null

if [ $? != 0 ]
then
    	systemctl start seahub.service  > /dev/null
fi
#############################################
#Server Restor from Back up
#1.Backup etdiyimiz serveri restore etmək üçün ilk növbədə service-ləri dayandırırıq.
########################################
systecmctl stop mariadb
systemctl stop seafile.service
systecmctl stop seahub.service
systemctl stop nginx
########################################
#2.Backup etdiyimizi serviceləri restor edirik.
 mysql -u root -p –all-databases < alldatabases.sql # 
#qeyd: back etdiyimiz  alldatabases.sql 
#restoru isə bu komanda ilə restor edirik ---- mysql -u root -p –all-databases
tar xvfj Seafile.tar.bz2 -C  /opt/
tar xvfj vastəsi ilə biz backup etdiyimiz Seafile.tar.bz2 backup filini opt folderinə extract edirik.
#########################################
#3. Bütün service-ləri restore-dən sonra aktiv edirik
systecmctl start mariadb
systemctl start seafile.service
systecmctl start seahub.service
systemctl start nginx

fi
