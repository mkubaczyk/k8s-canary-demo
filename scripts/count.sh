
count=$1
url=$2

v1=()
v2=()
v3=()
for i in $(seq 1 $count)
do 
	response=$(curl -s $url)
	if [[ $response =~ "v1" ]]; then
		v1+=($response)
	elif [[ $response =~ "v2" ]]; then
		v2+=($response)
	elif [[ $response =~ "v3" ]]; then
		v3+=($response)
	else
		echo "no match"
	fi
done

echo "v1: ${#v1[@]}"
echo "v2: ${#v2[@]}"
echo "v3: ${#v3[@]}"