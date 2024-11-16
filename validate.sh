# given a directory, recursively check if all .sqlite files are valid
# via sqlite3 <db> 'PRAGMA integrity_check'

# Initialize counters
ok_count=0
corrupt_count=0

for db in $(find $1 -name "*.sqlite"); do
    result=$(sqlite3 $db "PRAGMA integrity_check;")
    if [ "$result" != "ok" ]; then
        echo "$db: $result"
        ((corrupt_count++))
    else
        ((ok_count++))
    fi
done

echo "Validated databases, summary:"
echo "- Valid databases: $ok_count"
echo "- Corrupted databases: $corrupt_count"
echo "- Total databases checked: $((ok_count + corrupt_count))"
