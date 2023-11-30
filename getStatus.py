import json

try:

    with open("status.txt", 'r') as fhandle:
        status = json.loads(fhandle.read())

    with open("result.txt", 'w') as fhandle:
        fhandle.write(status["Reservations"][0]["Instances"][0]["State"]["Name"])

except Exception as e:
    print("Exception occurred...", e)
