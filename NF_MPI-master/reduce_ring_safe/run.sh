max=$1

for ((i=1; i<=$max; ++i )) ; 
do
    cp -r node "$i"
done

for ((i=1; i<=$max; ++i )) ;
do
    cd "$i"
    if [ "$i" = "1" ]
    then
	python opl_cosim.py ../"$i"s ../"$((i+1))"s head &
    elif [ "$i" = "$max" ]	
    then
	python opl_cosim.py ../"$i"s  ../1s &
    else
	python opl_cosim.py ../"$i"s ../"$((i+1))"s &
    fi
    cd ../
done

for ((i=1; i<=$max; ++i )) ;
do
    cd "$i"
    if [ "$i" = "1" ]
    then
	python client.py ../"$i"s head &
    else
	python client.py ../"$i"s & 
    fi
    cd ../
done
