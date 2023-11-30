import json

try:

    with open("stack.txt", 'r') as fhandle:
        stack = json.loads(fhandle.read())

    for item in stack["StackResources"]:
        if (item["ResourceType"] == 'AWS::EC2::Instance'):
            with open("result.txt", 'w') as fhandle:
                (fhandle.write(item['PhysicalResourceId']))

except Exception as e:
    print("Exception occurred...", e)
