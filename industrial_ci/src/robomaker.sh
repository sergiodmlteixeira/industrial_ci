#!/bin/bash

function ici_setup_aws {
    ici_quiet ici_aws_cli_install
    ici_aws_cli_configuration
    bundle_setup
}

function ici_aws_cli_install {
    cd ~ && mkdir .temp_aws && cd .temp_aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ici_asroot ./aws/install
}

function ici_aws_cli_configuration {
    aws configure set aws_access_key_id $AWS_ACCESS_KEY
    aws configure set aws_secret_access_key $AWS_SECRET_KEY
    aws configure set default.region $AWS_REGION
}

function ici_setup_bundle_workspace {
    local -a ws_bundle
    ici_parse_env_array ws_bundle BUNDLE_WORKSPACE
    local workspace="bundle_ws"
    ici_with_ws "$workspace/ws" ici_prepare_sourcespace "$workspace/ws/src/" "${ws_bundle[@]}"
}

function ici_upload_bundle {
    ici_with_ws "$bundle_ws" ici_exec_in_workspace "$extend" "$bundle_ws" aws s3 cp bundle/output.tar $AWS_ROBOT_BUNDLE --no-progress
    export TERM=xterm
}

function ici_test_simulation {
    cd ~/bundle_ws
    echo "Starting Simulation..."
    aws lambda invoke --cli-binary-format raw-in-base64-out --function-name $AWS_SIM_FUNCTION --payload '{"package": "simulated_omni_drive_skill_server", "launch_file": "run_sim_test.launch"}' -
    sleep 10
    temp=$(aws stepfunctions list-executions  --state-machine-arn=$AWS_SF_ARN --max-items=1 --query executions[0].executionArn)
    temp="${temp%\"}"
    SF_EXECUTION="${temp#\"}"
    echo "Simulation is running on AWS Robomaker..."
    while true
    do
        temp=$(aws stepfunctions describe-execution --execution-arn=$SF_EXECUTION --query "status")
        temp="${temp%\"}"
        STATUS="${temp#\"}"
        if [[ "$STATUS" == "SUCCEEDED" ]]; then
            echo "Simulation finished successfully"
            break
        elif [[ "$STATUS" == "RUNNING" ]]; then
            sleep 10
        else
            echo "Simulation failed"
            exit 1
        fi
    done
}
