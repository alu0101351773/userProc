variable=""
reg_err="[]"
while [[ "$1" != -* ]]; do
    variable="$variable $1"
    shift
done

echo $variable