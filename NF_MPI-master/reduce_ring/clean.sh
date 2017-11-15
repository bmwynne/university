max=$1

python kill.py "$max"

for ((i=1; i<=$max; ++i )) ; 
do
    rm -f -r "$i"
    rm -f -r "$i"s
done

