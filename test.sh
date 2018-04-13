#!/bin/bash

function red {
	echo "<font face="verdana" color="red">$@</font>"
}
function green {
	echo "<font face="verdana" color="green">$@</font>"
}
function orange {
        echo "<font face="verdana" color="darkorange">$@</font>"
}
function black {
        echo "<font face="verdana" color="black">$@</font>"
}

function dnssec {
	dnssec=`dig +short ds $1 `
	if [ "$dnssec" ] ; then
		green "- $1 är signerad med DNSSEC"
		#echo 1.0:$1:DNSSEC:OK
		test=`dig +dnssec www.$i | grep "ad;"`
		if [ "$test" ] ; then
			green "- $1's DNSSEC fungerar"
			#echo 1.1:$1:DNSSEC_USE:OK
		elif [ ! "$test" ] ; then
			red "- Varning! DNSSEC för $1 är trasig!!"
                        #echo 1.1:$1:DNSSEC_USE:NOK
		fi
	elif [ ! "$dnssec" ] ; then
		red "- $1 är inte signerad med DNSSEC"
		#echo 1.0:$1:DNSSEC:NOK
	fi

}

function ipv6 {
	ipv6=`dig +short -taaaa www.$1`
	if [ ! "`echo $ipv6 | grep :`" ] ; then
		unset ipv6
	fi
        if [ "$ipv6" ] ; then
		green "- $1 har IPv6 aktiverat på www.$1"
		curl -6 -s -q -m3 http://www.$1 >/dev/null
		exit=$? 
		if [ "$exit" != "0" ] ; then
			red "- $1 har tyvärr en trasig IPv6 på webben"
		fi
        elif [ ! "$ipv6" ] ; then
		red "- $1 har missat att aktivera IPv6 på webben..."
		
        fi
	
}

function https {
	host=http://www.$1
	res=`curl  -m 2 -s -I $host | grep Location | grep https`
	if [ "$res" ] ; then
		location=`echo $res | awk -F"Location:" '{print $2}'`
		location=${location%$'\r'}
		green "- $1 har automatisk https till$location"
		host=$location
	elif [ ! "$res" ] ; then
		red "- $1 har inte automatisk https"
		host=https://www.$1
	fi
	curl -s -q -m5 $host >/dev/null
	exit=$?
	case $exit in
	0)
		green "- $1 har fungerande https" 
		domain2=`echo $host | awk -F/ '{print $3}'`
		if [ ! "`dig +short -tcaa $domain2`" ] ; then
			orange "-         men ingen CAA post på `echo $domain2 | sed s/"www."//g` för certifikat uppsatt"
		fi
		if [ ! "`curl -m 2 -s -I https://www.$1 | grep Strict-Transport-Security`" ] ; then
			orange "-         har inte HSTS för HTTPS uppsatt"
		fi
		;;
	7)
		red "- $1 Det går inte att ansluta till https://www.$1" ;;
	28)
		red "- $1 tar för lång tid att ansluta mot via https" ;;
	35)	
		red "- $1 fel vid https anslutningen" ;;
	51)
		red "- $1 har felaktigt certifikat" ;;

	*)
		red "- $1 går inte att ansluta till $host" ;;
	esac
	
}

function mx {
	if [ ! "`dig +short  $1`" ] ; then
		green "- $1 tar inte emot mail"
	elif [ "`dig +short  $1`" ] ; then
		MX=`dig +short mx $1 |awk '{print $2}'`
        	for mx in $MX ; do
                	if [ "`dig +short -taaaa $mx`"  ] ; then
				mxv6=1
				resmx=`echo quit|nc -6 -w 6 $mx 25`	
				res=$?
				if [ "$res" = "0" ] ; then
					green "- $1's mailserver $mx svarar på IPv6"
				elif [ "$res" = "1" ] ; then
					red "- $1's mailserver $mx svarar inte IPv6"
				fi
			fi
		done
		#if [ "$mxv6" = "1" ] ; then
        	#        green "- $1 IPv6 aktiverat för inkommande mail men det är inte testat att det fungerar"
	        #fi
		if [ ! "$MX" ] ; then
			green "- $1 tar inte emot mail"
			exit
		fi
		if [ ! "$mxv6" = "1" ] ; then
			red "- $1 har ingen mailserver med IPv6 aktiverat"
		fi
		
        	if [ "$MX" ] ; then
               	./spf2 $1 
        	fi	
	fi

}

function dns {
	expire=`dig soa +multiline $1 |grep expire|awk '{print $1}'`

	if [ "$expire" -lt "604800" ] ; then
		red "- $1 har SOA expire under en vecka"
	fi
}


if [ ! "$1" ] ; then
	exit
fi

echo `date`,$1 >>test/tests.txt


domain=`echo $1 | /usr/local/bin/idn2.pl`
if [ "$domain" != "$1" ] ; then
	green "- $1 ser ut att innehålla underliga tecken, testar $domain"
fi 

if [ ! "`dig +short ns $domain`" ] ; then
        red "- $domain är inte aktiv"
        exit
fi

dns $domain

dnssec 	$domain
	
ipv6	$domain

https	$domain

mx	$domain

red ""
green "Grönt - bra"
red "Rött - dåligt - Fixa!"
orange "Orange - bör sätta upp"
black ""
black "Google är din bästa vän om ni inte hänger med i det ovan"
