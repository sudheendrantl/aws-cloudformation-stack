import json
import boto3
import sys
import time
import random
import datetime
import sched


KINESIS_DATA_STREAM = "addkinesisstream"

kinesis_handle = boto3.client('kinesis', region_name = "us-east-1")


# Function to push data in the kinesis stream, partition key of kinesis stream is deviceid


def publishDummyData(loopCount):
	message = {}
	value = float(random.normalvariate(97, 2))
	value = round(value, 1)
	timestamp = str(datetime.datetime.now())
	message['timestamp'] = str(timestamp)
	message['datatype'] = 'Temperature'
	message['value'] = value
	message['deviceid'] = "DHT_001"
	message['date'] = str(today)
	message['lowest_temp'] = 96
	message['highest_temp'] = 101
	message = json.dumps(message)
	#print(message)
	response = kinesis_handle.put_record(StreamName=KINESIS_DATA_STREAM, Data = message, PartitionKey="deviceid")
	print("Response is: ", response)


today = datetime.date.today()


scheduler = sched.scheduler(time.time, time.sleep)

now = time.time()
loopCount = 0
# Pushing the data to a configuered kinesis stream.
print("Data push to kinesis stream started")

while True:
    try :
    	scheduler.enterabs(now+loopCount, 1, publishDummyData, (loopCount,))
    	loopCount += 1
    	scheduler.run()
    except KeyboardInterrupt:
        break

print("Data push to kinesis stream has stopped")


