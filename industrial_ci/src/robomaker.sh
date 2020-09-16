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
    # Define needed parameters
    args=( --max-job-duration-in-seconds $MAX_JOB_DURATION --iam-role $IAM_ROLE )

    # Check and define optional parameters
    if [ ! -z "$CLIENT_REQUEST_TOKEN" ]; then
    	args+=( --client-request-token $CLIENT_REQUEST_TOKEN )
    fi
    if [ ! -z "$OUTPUT_LOCATION" ]; then
    	args+=( --output-location $OUTPUT_LOCATION )
    fi
    if [ ! -z "$LOGGING_CONFIG" ]; then
    	args+=( --logging-config $LOGGING_CONFIG )
    fi
    if [ ! -z "$FAILURE_BEHAVIOR" ]; then
    	args+=( --failure-behavior $FAILURE_BEHAVIOR )
    fi
    if [ ! -z "$ROBOT_APPLICATIONS" ]; then
    	args+=( --robot-applications $ROBOT_APPLICATIONS )
    fi
    if [ ! -z "$SIMULATION_APPLICATIONS" ]; then
    	args+=( --simulation-applications $SIMULATION_APPLICATIONS )
    fi
    if [ ! -z "$DATA_SOURCES" ]; then
    	args+=( --data-sources $DATA_SOURCES )
    fi
    if [ ! -z "$TAGS" ]; then
    	args+=( --tags $TAGS )
    fi
    if [ ! -z "$VPC_CONFIG" ]; then
    	args+=( --vpc-config $VPC_CONFIG )
    fi
    if [ ! -z "$COMPUTE" ]; then
    	args+=( --compute $COMPUTE )
    fi

    # Run simulation job
    aws robomaker create-simulation-job "${args[@]}"
    
    # Run analysis script
    ./$ANALYSIS_SCRIPT
}
