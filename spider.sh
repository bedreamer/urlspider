#!/bin/bash

DOMAIN=$1
DATABASE=$DOMAIN.log
DB=db.db
g_urls=
CACHEDIR=/run/shm/
urlnr=

# 将制定页面中本站的链接找出来并返回
function spider_page() {
	thiz=`curl $1 2>/dev/null|grep -o "href=[\'\"]http://[^\"\'\?\#]\+[\"]"|grep -o "http://[^\"]\+"|uniq 2>/dev/null`
	g_urls="";
	for u in $thiz; do
		grep $u $DATABASE >/dev/null 2>&1
		if [ $? == 0 ]; then
		#	echo exist URL: $u
			continue; 
		fi
		#echo $u | grep $DOMAIN >/dev/null 2>&1
		#if [ $? != 0 ]; then 
		#	echo not domain URL: $u
		#	continue; 
		#fi
		g_urls="$g_urls $u";
		echo $u >> $DATABASE
		echo "   new url: $u"
		./a main.db "insert into links values('$u','dfadf');"
	done
}

# 使用数据库作为缓冲区 
function spider_page_db() {
	thiz=`curl $1 2>/dev/null|grep -o "href=[\'\"]http://[^\"\'\?\#]\+[\"]"|grep -o "http://[^\"]\+"|uniq 2>/dev/null`
	for u in $thiz; do
		#echo "SELECT * FROM urls WHERE url='$u'"
		u_md5a=`echo "$u" | md5sum | awk '{print $1}'`
		u_md5b=`echo "$u/" | md5sum | awk '{print $1}'`
		result=`./db $DB "SELECT md5 FROM urls WHERE md5='$u_md5a' OR md5='$u_md5b'"`
		if [ ${#result} != 0 ]; then
		#	echo exist URL: $u
		#	echo "-------REPEATE------ $result:::${#result}:::$u"
			continue; 
		fi
		#echo $u | grep $DOMAIN >/dev/null 2>&1
		#if [ $? != 0 ]; then 
		#	echo not domain URL: $u
		#	continue; 
		#fi
		nr=`./db $DB "SELECT COUNT(*)+1 FROM urls"`
		echo "[ $nr ] $u_md5a:$u"
		./db $DB "INSERT INTO urls VALUES('$nr','$u_md5a','$u');"
	done
}

function spider_domain() {
	echo "www.$1"
	thiz=`curl www.$1 2>/dev/null|grep -o "href=[\'\"]http://[^\"\'\?\#]\+[\"]"|grep -o "http://[^\"\/]\+"|sed 's/http:\/\///'|grep -o '[^\.\/\?\#]\+\.com[^\/\?\#]\+' | sort|uniq 2>/dev/null`
	g_urls="";
	for u in $thiz; do
		grep $u $DATABASE >/dev/null 2>&1
		if [ $? == 0 ]; then
		#	echo exist URL: $u
			continue; 
		fi
		#echo $u | grep $DOMAIN >/dev/null 2>&1
		#if [ $? != 0 ]; then 
		#	echo not domain URL: $u
		#	continue; 
		#fi
		g_urls="$g_urls $u";
		echo $u >> $DATABASE
		geo=`geoiplookup $u`;
		echo $geo | grep "can\'t" >/dev/null 2>&1
		if [ $? == 0 ]; then
			echo "   new domain: $u   -->  $geo"
		else
			echo "   new domain: $u   -->  N/A"
		fi
	done
}

function spider_page_enum() {
	for u in $@; do
		if [ ${#u} == 0 ];then continue; fi
		echo spidering on page: $u
		spider_page $u
		newurls="$newurls $g_urls"
	done
	spider_page_enum $newurls
}

function spider_domain_enum() {
	for u in $@; do
		if [ ${#u} == 0 ];then continue; fi
		echo spidering on page: $u
		spider_domain $u
		newurls="$newurls $g_urls"
	done
	spider_domain_enum $newurls
}

if [ -e $DB ]; then
	rm $DB;
fi
./db $DB "create table urls(id unsigned int,md5 string,url string);"
md=`echo '$1' | md5sum | awk '{print $1}'` 
./db $DB "INSERT INTO urls VALUES('0', '$md', '$1');"

i=0
while [ $i -ge 0 ]
	do
		sql="SELECT url FROM urls WHERE id='$i'";
		url=`./db $DB "$sql"`
		echo "spider url $sql ==> $url"
		spider_page_db $url
		echo "--------->"
		i=$(($i+1))
	done
echo done.
