#!/bin/bash
set -e    #a

echo 'Gerando arquivo de configuração nginx.conf ...'

# NGINXCONF=/etc/nginx/nginx.conf
NGINXCONF=./nginx.conf

cat > $NGINXCONF <<- EOM

events {

}
http { 

    log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log   logs/access.log  main;
    rewrite_log on;

EOM

if [ "$PROXY_DESTINATIONS" != "" ]; then
    # proxy servers
   for PS in $(echo $PROXY_DESTINATIONS | tr " " "\n")
   do
        URI=''
        LISTENPORT=''
        SERVERPORT=''
        SERVER=''  
        SCHEMA=''
        I1=0                                   #  export PROXY_DESTINATIONS="9090|/|http|grafana|3000 8181|/|https|mongo-express|6666" 
        for PARTS in $(echo $PS | tr "|" "\n")
        do
        echo "'$PARTS'"
            if [ $I1 -eq 0  ]; then
             LISTENPORT=$PARTS
             I1=1
            else
                if [ $I1 -eq 1  ]; then
                    URI=$PARTS
                    I1=2
                else
                    if [ $I1 -eq 2  ] ; then
                        SCHEMA=$PARTS
                        I1=3
                    else
                        if [ $I1 -eq 3  ] ; then
                           SERVER=$PARTS
                           I1=4
                        else
                           if [ $PARTS -ne 0 ]; then
                             SERVERPORT=$SERVER:$PARTS
                           fi
                        fi
                    fi

                fi

            fi
        done

        echo $URI   $LISTENPORT    $SERVER $SERVERPORT     $SCHEMA         $I1 
        cat >> $NGINXCONF <<- EOM
    server {
        listen $LISTENPORT;

        access_log   logs/$SERVER.access.log  main;

        location $URI {
            proxy_pass $SCHEMA://$SERVERPORT ;  
        }

EOM
   done

fi

#final do arquivo de configurações nginx.conf

cat >> $NGINXCONF <<- EOM
    }
}
EOM

echo "######      Arquivo nginx.conf     ######"
cat $NGINXCONF
echo "#########################################"

