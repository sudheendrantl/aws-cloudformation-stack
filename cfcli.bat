@echo off

rem set these flags to either 1 or 0. 
rem setting the flag as 1 enables the phase. 
rem setting the flag as 0 disables the phase.

set preclean=1
set preprocess=1
set createstack=1
set postclean=1

rem set the name of the template file
set stackfilename=stack.json

rem set the name of the s3 bucket to be used for storing project artifacts
rem This needs to the same name as provided in the template while creating 
rem the s3 resource.
set anomalydetectionbucketname=anomalydetections3bucket

rem set the name of the s3 bucket to be used for storing project templates
set templatesbucketname=cftaddbucket

rem set the name of the db table created by the template
set dynamodbtablename=adddb

rem set the name of the cloudformation stack name
set stackname=cfproject

rem set the name of the keypair name for ec2. This needs to the same name as 
rem provided in the template while creating the keypair.
set keypairname=addec2key

if not "%preclean%"=="1" goto preprocess

echo:
echo -----------------------------------------------------

echo:
echo precleanup started...

echo:
echo checking/emptying/deleting %anomalydetectionbucketname% if it exists...
aws s3 ls > result.txt
findstr %anomalydetectionbucketname% result.txt >nul
set errlevel=%errorlevel%
if %errlevel% equ 0 aws s3 rm s3://%anomalydetectionbucketname% --recursive
if %errlevel% equ 0 aws s3 rb s3://%anomalydetectionbucketname%

echo:
echo checking/emptying/deleting %templatesbucketname% if it exists...
aws s3 ls > result.txt
findstr %templatesbucketname% result.txt >nul
set errlevel=%errorlevel%
if %errlevel% equ 0 aws s3 rm s3://%templatesbucketname% --recursive
if %errlevel% equ 0 aws s3 rb s3://%templatesbucketname%

echo:
echo checking/deleting tmp files it they exist...
if exist dbcount.txt del dbcount.txt
if exist result.txt del result.txt
if exist resid.txt del resid.txt
if exist %keypairname%.pem del %keypairname%.pem
if exist stack.txt del stack.txt
if exist status.txt del status.txt

echo:
echo precleanup completed.

echo:
echo -----------------------------------------------------

:preprocess

if not "%preprocess%"=="1" goto createstack

echo:
echo -----------------------------------------------------

echo:
echo preprocess started...

echo:
echo creating a S3 bucket named %templatesbucketname% for storing cloudformation templates ...
aws s3 mb s3://%templatesbucketname%

echo:
echo copying templates to the templates bucket named %templatesbucketname% ...
aws s3 cp %stackfilename% s3://%templatesbucketname%
aws s3 cp %stackfilename% s3://%templatesbucketname%

echo:
echo preprocess completed.

echo:
echo -----------------------------------------------------

:createstack

if not "%createstack%"=="1" goto postclean

echo:
echo -----------------------------------------------------

echo:
echo createstack started...

echo:
echo initiating stack creation ...
aws cloudformation create-stack --capabilities CAPABILITY_NAMED_IAM  --stack-name %stackname% --template-url https://%templatesbucketname%.s3.amazonaws.com/%stackfilename%

echo:
echo waiting for completion of stack creation ...
aws cloudformation wait stack-create-complete

echo:
echo cloudformation stack creation completed

rem get the keypair id from ec2 and save to result.txt file and keypairid variable
aws ec2 describe-key-pairs --filters Name=key-name,Values=%keypairname% --query KeyPairs[*].KeyPairId --output text > result.txt

set /p keypairid=<result.txt

rem get the keypair pem file from aws system manager service
rem and save in .pem file
aws ssm get-parameter --name /ec2/keypair/%keypairid% --with-decryption --query Parameter.Value --output text > %keypairname%.pem

rem get the description of the stack just now created using cloudformation
aws cloudformation describe-stack-resources --stack-name %stackname% > stack.txt

rem get the instance id of the ec2 from stack.txt using the python utility
rem and save it into the result.txt and instanceid variable
python getInstanceId.py
set /p instanceid=<result.txt

rem ensure that the ec2 is in running state before attempting to fetch the public ip address
:waituntilec2running
echo:
echo waiting for ec2 to enter running status
aws ec2 describe-instances --filters "Name=instance-id,Values=%instanceid%" --filters "Name=instance-state-name,Values=running" > status.txt
python getStatus.py
findstr running result.txt >nul

set errlevel=%errorlevel%
if %errlevel% equ 1 echo ec2 is not yet running...
if %errlevel% equ 1 timeout /t 5
if %errlevel% equ 1 goto goto waituntilec2running

echo:
echo ec2 is up and running!

rem get the public ip address of the ec2 instance created and save
rem it into result.txt and ip variable
aws ec2 describe-instances --filters "Name=instance-id,Values=%instanceid%" --query "Reservations[].Instances[].PublicIpAddress" --output text > result.txt

set /p ip=<result.txt
set ip=%ip:.=-%

rem launch a new command windows and SSH into the new ec2 created
start cmd /k "ssh -i "%keypairname%.pem" ubuntu@ec2-%ip%.compute-1.amazonaws.com"

echo:
echo createstack completed

echo all deployments done and the stack is ready for use!

echo:
echo -----------------------------------------------------

:waitfordeleteconfirmation

echo:
aws dynamodb scan --table-name %dynamodbtablename% --select COUNT > dbcount.txt
python getdbcount.py
set /p count=<result.txt
echo count of items in %dynamodbtablename% is %count%

echo:
echo WARNING: continue deleting all the infra created(y/n)?

set var=n
set /p var=

if "%var%"=="y" goto postclean
goto waitfordeleteconfirmation

:postclean

if not "%postclean%"=="1" goto exit

echo:
echo -----------------------------------------------------

echo:
echo postcleanup started...

echo:
echo checking/emptying %anomalydetectionbucketname% if it exists...
aws s3 ls > result.txt
findstr %anomalydetectionbucketname% result.txt >nul
if %errorlevel% equ 0 aws s3 rm s3://%anomalydetectionbucketname% --recursive

echo:
echo checking/emptying/deleting %templatesbucketname% if it exists...
aws s3 ls > result.txt
findstr %templatesbucketname% result.txt >nul
set errlevel=%errorlevel%
if %errlevel% equ 0 aws s3 rm s3://%templatesbucketname% --recursive
if %errlevel% equ 0 aws s3 rb s3://%templatesbucketname%

echo:
echo checking/deleting tmp files if they exist...

if exist dbcount.txt del dbcount.txt
if exist result.txt del result.txt
if exist resid.txt del resid.txt
if exist %keypairname%.pem del %keypairname%.pem
if exist stack.txt del stack.txt
if exist status.txt del status.txt

echo:
echo initiating the deletion of stack named %stackname% ...
aws cloudformation delete-stack --stack-name %stackname%

echo:
echo waiting for completion of the deletion of the stack named %stackname% ...
aws cloudformation wait stack-delete-complete --stack-name "%stackname%"

echo:
echo postcleanup completed.

echo:
echo -----------------------------------------------------

:exit
pause
