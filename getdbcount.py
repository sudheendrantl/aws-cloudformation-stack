import json

try:

    with open("dbcount.txt", 'r') as fhandle:
        db = json.loads(fhandle.read())

    with open("result.txt", 'w') as fhandle:
        (fhandle.write(str(db['ScannedCount'])))

except Exception as e:
    print("Exception occurred...", e)
